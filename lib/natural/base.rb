class Natural
  @@logger = Logger.new(STDOUT)

  def initialize(text, user)

    @text       = text
    @user       = user
    @parse      = parse

    @text = @text.split(' ').map{|a| a.strip}.select{|a| !a.blank?}.join(' ') # remove extra spaces between words
  end
  
  def text=(text)
    @text = text
    parse
  end
  
  def user=(user)
    @user = user
    parse
  end
  
  def parse
    return @parse if @parse

    text = @automatic_text || @text

    # search for all possible matches using all the different fragment classes
    tag_classes = ObjectSpace.each_object(Class).select {|a| a < Natural::Fragment}
    matches_by_class = {}
    tag_classes.each do |klass|
      matches_by_class = klass.find(text, matches_by_class)
    end
    puts matches_by_class

    # find all valid combinations, choose the one with the highest score
    sequences = []
    sequences = assemble_sequences(matches_by_class.values.flatten)

    sequences = sequences.uniq.sort {|a,b| b.map_by_score.sum <=> a.map_by_score.sum}
    fragments = sequences.first || []
    ap sequences.map {|a| "#{a.sort{|b,c| b.ids.first <=> c.ids.first}} score #{a.map_by_score.sum}"}

    # tag the leftover words as unused
    remaining_words = (0..text.split(' ').size-1).to_a - (!fragments.blank? ? fragments.map_by_ids.flatten : [])
    remaining_words.each do |id|
      tag_match = UnusedTerm.new(:ids => [id], :text => text.split(' ')[id])
      fragments << tag_match
    end

    # put the fragments we are using in order and assemble the final tree
    fragments = fragments.sort {|a,b| a.ids.first <=> b.ids.first}
    @parse = Fragment.new(:ids => (0..text.split(' ').size-1).to_a, :text => text)
    fragments.each {|a| @parse << a}
    
    @parse
  end

  def parse!
    @parse = nil
    parse
  end

  def answer
    result = {:question => nil, :interpreted_as => nil, :answer => nil, :items => nil}

    result[:items] = result_set

    accumulator = @parse.children.map_by_accumulator.select{|a| a}.first
    case accumulator
    when :sum
      result[:answer] = result[:items].map_by_total.sum
    when :count
      result[:answer] = result[:items].count
    when :itemize
    end

    result[:question] = "#{@user.name}: #{@text}"
    result[:interpreted_as] = "#{@user.name}: #{interpretation}"

    # @@logger.debug("[q][accu] #{accumulator}")
    @@logger.info("[q][orig] #{@user.name}: #{@text}")
    @@logger.info("[q][intr] #{@user.name}: #{interpretation}")
    @parse.pretty_to_s.each_line do |line|
      @@logger.debug("[q][tree] #{line.gsub("\n", '')}")
    end

    result
  end
    
  private

  def result_set
    results = []

    if @user
      sets = @parse.children.map_by_data(@user).select{|a| a}.flatten
      if sets.blank?
        if !@user.friends.blank?
          @automatic_text = @text + ' we bought'
        else
          @automatic_text = @text + ' i bought'
        end
        @automatic_words = [@automatic_text.split(' ').size-2, @automatic_text.split(' ').size-1]
        parse!
        sets = @parse.children.map_by_data(@user).select{|a| a}.flatten
      end
    else
      sets = []
    end

    filters = @parse.children.map_by_all_filters.select{|a| !a.blank?}
    sets.each do |set|
      search = set
      filters.each do |filter|
        search += ".#{filter}"
      end
      @@logger.debug("[q][srch] #{search}")
      results += eval(search)
    end
    @@logger.debug("[q][srch] #{HighLine::RED}none#{HighLine::CLEAR}") if sets.blank?

    results
  end

  def interpretation(crossout=true)
    result = ''
    @parse.children.each do |node|
      result += ' '
      # result += HighLine::YELLOW if @automatic_words && !(@automatic_words & node.ids).blank?
      if !node.all_filters.blank? || node.data(@user) || node.accumulator
        result += node.to_s(:without_edits => true)
      elsif crossout == true
        result += node.to_s.gsub(/[a-zA-Z]/,'-')
      end
      # result += HighLine::CLEAR if @automatic_words && !(@automatic_words & node.ids).blank?
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
