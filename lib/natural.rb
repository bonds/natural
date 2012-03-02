require 'natural/inflections'
require 'natural/string'
require 'natural/fragment'
require 'natural/fragments/timeframes.rb'
require 'natural/fragments/misc.rb'
require 'natural/fragments/example.rb'

class Natural
  require 'map_by_method'
  require 'active_support/inflector'
  require 'active_support/core_ext'

  require 'logger'
  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::DEBUG

  GREEN   = "\e[32m"
  RED     = "\e[31m"  
  YELLOW  = "\e[33m"
  CLEAR   = "\e[0m"

  DEFAULT_SPELLINGS   = {'blu-ray' => ['bluray', 'blueray', 'blue ray', 'blu ray']}
  DEFAULT_SYNONYMS    = [['cd', 'audio cd'], ['food', 'eat', 'dine']]
  DEFAULT_EXPANSIONS  = {'food' => ['grocery', 'eat out', 'eating out', 'dining out', 'dine out', 'dine in'], 'music' => ['audio cd', 'audio tape'], 'movie' => ['blu-ray', 'dvd', 'video']}

  def initialize(text, options={})
    @text       = text.squeeze(' ').strip
    @options    = options
    
    @parse      = parse
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

    # search for all possible matches using all the different fragment classes
    fragment_classes = @options[:fragment_classes] || ObjectSpace.each_object(Class)
    fragment_classes = fragment_classes.select {|a| a < Natural::Fragment && !a.to_s.start_with?('Natural::')}
    matches_by_class = {}
    fragment_classes.each do |klass|
      matches_by_class = klass.find(:text => @text, :matches => matches_by_class, :spellings => @options[:spellings] || DEFAULT_SPELLINGS, :synonyms => @options[:synonyms] || DEFAULT_SYNONYMS, :expansions => @options[:expansions] || DEFAULT_EXPANSIONS)
    end

    # find all valid combinations, choose the one with the highest score
    sequences = []
    sequences = assemble_sequences(matches_by_class.values.flatten)
    sequences = sequences.uniq.sort {|a,b| b.map_by_score.sum <=> a.map_by_score.sum}
    fragments = sequences.first || []

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
    
    sequences.each {|a| @@logger.debug "[n][scor] #{a.map_by_score.sum.to_s.rjust(2, '0')} #{a.sort{|b,c| b.ids.first <=> c.ids.first}.join(', ')}"}
    @@logger.debug("[n]")
    @parse.pretty_to_s.each_line do |line|
      @@logger.debug("[n][tree] #{line.gsub("\n", '')}")
    end
    @@logger.debug("[n]")
    @@logger.info("[n][orig] #{@text}" + (@options[:context] ? " (#{@options[:context]})" : ""))
    @@logger.info("[n][used] #{interpretation}" + (@options[:context] ? " (#{@options[:context]})" : ""))

    @parse
  end

  def parse!
    @parse = nil
    parse
  end

  def answer
    result = @parse.children.map_by_data(@options[:context]).select{|a| !a.blank?}.flatten
    @parse.children.map_by_all_filters.select{|a| !a.blank?}.each {|f| result = eval("result.#{f}")}
    @parse.children.map_by_aggregator.select{|a| !a.blank?}.each {|a| result = eval("result.#{a}")}
    result
  end
    
  private

  def interpretation(crossout=true)
    result = ''
    @parse.children.each do |node|
      result += ' '
      # result += YELLOW if @automatic_words && !(@automatic_words & node.ids).blank?
      if !node.all_filters.blank? || node.data(@options[:context]) || node.aggregator
        result += node.to_s(:without_edits => true)
      elsif crossout == true
        result += node.to_s.gsub(/[a-zA-Z]/,'-')
      end
      # result += CLEAR if @automatic_words && !(@automatic_words & node.ids).blank?
    end

    result.strip
  end

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
