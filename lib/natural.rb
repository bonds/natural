require 'natural/inflections'
require 'natural/string'
require 'natural/array'
require 'natural/fragment'
require 'natural/fragments/timeframes.rb'
require 'natural/fragments/misc.rb'
require 'natural/fragments/example.rb'
require 'pry'

class Natural
  require 'map_by_method'
  require 'active_support/inflector'
  require 'active_support/core_ext'
  require 'logger'

  GREEN   = "\e[32m"
  RED     = "\e[31m"  
  YELLOW  = "\e[33m"
  CLEAR   = "\e[0m"

  MATCHING_OPTIONS    = [:most_points, :first_match]

  DEFAULT_SPELLINGS   = {'week' => ['wek', 'weeek'], 'begin' => ['beginn', 'beegin']}
  DEFAULT_SYNONYMS    = {'1' => ['start', 'begin', 'commence'], '2' => ['stop', 'end', 'finish', 'conclude']}
  DEFAULT_EXPANSIONS  = {'food' => ['grocery', 'eat out', 'eating out', 'dining out', 'dine out', 'dine in'], 'music' => ['audio cd', 'audio tape'], 'movie' => ['blu-ray', 'dvd', 'video']}
  DEFAULT_MATCHING    = :most_points

  def initialize(text, options={})
    @text = text.squeeze(' ').strip
    @options = options

    if options[:logger]
      @logger = options[:logger]
    else
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
    end
    
    @parse        = parse
  end
  
  def text=(text)
    @text = text
    parse
  end
  
  def options=(options)
    @options = options
    parse
  end
  
  def parse
    return @parse if @parse

    start_at = Time.now

    # search for all possible matches using all the different fragment classes
    matches_by_class = {}
    fragment_classes = @options[:fragment_classes] || ObjectSpace.each_object(Class)
    fragment_classes = fragment_classes.select {|a| a < Natural::Fragment && a != Natural::Unused}
    find_options = {
      :text => @text, 
      :matches => matches_by_class, 
      :matching => @options[:matching] || DEFAULT_MATCHING,
      :spellings => @options[:spellings] || DEFAULT_SPELLINGS, 
      :synonyms => @options[:synonyms] || DEFAULT_SYNONYMS, 
      :expansions => @options[:expansions] || DEFAULT_EXPANSIONS
    }

    if find_options[:matching] == :first_match
      # once a match has been found, exclude those words from further consideration
      # can help speed things up, but requires you order the candidate fragment_classes carefully
      fragment_classes.each do |klass|
        new_options = find_options.dup
        new_options[:ignore] = matches_by_class.values.flatten.select{|a| a}.map_by_ids.flatten.uniq.sort
        matches_by_class[klass] = klass.find(new_options)[klass] if klass.find(new_options)[klass]
      end
    else
      ObjectSpace.each_object(Class).select {|a| a < Natural::Alternative}.each do |klass| 
        matches_by_class = klass.find(find_options)
      end
      fragment_classes.each do |klass|
        matches_by_class = klass.find(find_options)
      end
    end

    matching_at = Time.now
    @logger.debug "[n][perf] matching took #{(matching_at - start_at).seconds.round(1)} seconds"

    # find all valid combinations, choose the one with the highest score
    sequences = []
    sequences = assemble_sequences(matches_by_class.values.flatten)
    sequences = sequences.uniq.sort {|a,b| b.map_by_score.sum <=> a.map_by_score.sum}
    fragments = sequences.first || []

    scoring_at = Time.now
    @logger.debug "[n][perf] scoring took #{(scoring_at - matching_at).seconds.round(1)} seconds"
    @logger.debug "[n]"

    # tag the leftover words as unused
    remaining_words = (0..@text.split(' ').size-1).to_a - (!fragments.blank? ? fragments.map_by_ids.flatten : [])
    remaining_words.each do |id|
      tag_match = Unused.new(:ids => [id], :text => @text.split(' ')[id])
      fragments << tag_match
    end

    # put the fragments we are using in order and assemble the final tree
    fragments = fragments.sort {|a,b| a.ids.first <=> b.ids.first}
    @parse = Fragment.new(:ids => (0..@text.split(' ').size-1).to_a, :text => @text)
    fragments.each {|a| @parse << a}
    
    sequences.each {|a| @logger.debug "[n][scor] #{a.map_by_score.sum.to_s.rjust(2, '0')} #{a.sort{|b,c| b.ids.first <=> c.ids.first}.join(' | ')}"}
    @logger.debug("[n]")
    @parse.pretty_to_s.each_line do |line|
      @logger.debug("[n][tree] #{line.gsub("\n", '')}")
    end
    @logger.debug("[n]")
    @logger.info("[n][orig] #{@text}" + (@options[:context] ? " (#{@options[:context]})" : ""))
    @logger.info("[n][used] #{interpretation}" + (@options[:context] ? " (#{@options[:context]})" : ""))

    @parse
  end

  def parse!
    @parse = nil
    parse
  end

  def answer
    result = @parse.children.map_by_data(@options[:context]).select{|a| !a.blank?}.flatten
    @parse.children.map_by_all_filters.select{|a| !a.blank?}.each {|f| result = eval("result.#{f}")}
    
    case @parse.children.map_by_aggregator.select{|a| !a.blank?}.first
    when :sum
      result = result.sum {|a| a.sum}
    when :count
      result = result.sum {|a| a.count}
    end

    result
  end
    
  def interpretation(crossout=true, format=:text)
    result = ''
    @parse.children.each do |node|
      result += ' '
      # result += YELLOW if @automatic_words && !(@automatic_words & node.ids).blank?
      if !node.all_filters.blank? || node.data(@options[:context]) || node.aggregator
        result += node.to_s(:without_edits => true)
      elsif crossout == true
        if format == :html
          result += "<span class='unused'>#{node.to_s}</span>"
        else
          result += node.to_s.gsub(/[a-zA-Z]/,'-')
        end
      end
      # result += CLEAR if @automatic_words && !(@automatic_words & node.ids).blank?
    end

    result.strip
  end

  private

  def assemble_sequences(left_to_try, sequence_so_far=[])
    sequences = []

    new_left_to_try = left_to_try.dup.select{|a| (a.ids & sequence_so_far.map_by_ids.flatten.uniq).blank?}
    new_left_to_try.each do |fragment|
      new_sequence_so_far = sequence_so_far.dup << fragment
      sequences << new_sequence_so_far.sort{|a,b| a.ids.first <=> b.ids.first}
      sequences += assemble_sequences(new_left_to_try, new_sequence_so_far)
    end

    return sequences
  end

end
