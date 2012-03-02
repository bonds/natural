class Natural
  require 'tree'

  class Fragment < Tree::TreeNode
    attr_accessor :text, :score, :filter, :aggregator

    def initialize(options={})
      @ids = options[:ids]
      self.text = options[:text]
      super("#{GREEN}#{options[:text]}#{CLEAR} #{self.class.to_s.split('::').last.underscore} (#{self.id_range})", options[:text])
    end

    # recurse to the leaves and print out the id range of the underyling words
    def ids
      self.is_leaf? ? [@ids].flatten : self.children.inject([]) {|result, item| result += item.ids}
    end

    def ids=(values)
      @ids = values
    end

    def id_range
      @ids.size > 1 ? @ids.first..@ids.last : @ids.first
    end

    def all_filters
      if self.is_leaf?
        self.filter
      else
        self.children.inject('') do |result, item| 
          result = [result, self.filter, item.all_filters].select{|a| !a.blank?}.uniq.join('.')
        end
      end
    end

    # recurse to the leaves and print out all the words, applying all edits along the way
    def to_s(options={})
      if self.is_leaf?
        if options[:without_edits] && [Spelling, Synonym].include?(self.class)
          self.parent.text
        else
          self.text
        end
      else
        self.children.inject('') {|result, item| (result += item.text + ' ')}.strip
      end
    end

    def pretty_to_s(level=0)
      result = ''
      
      if is_root? || level == 0
        result += '*'
      else
        result += "|" unless parent.is_last_sibling?
        result += (' ' * ((level - 1) * 4 + (parent.is_last_sibling? ? 0 : -1)))
        result += is_last_sibling? ? '+' : '|'
        result += '---'
        result += has_children? ? '+' : '>'
      end
    
      result += " #{name}\n"
      children.each {|child| result += child.pretty_to_s(level+1)}
      
      result
    end

    def data(context=nil)
      nil
    end

    def score
      self.to_s.split(' ').size ** 2
    end

    def self.find(text_to_search, looking_for, matches={}, match_class=self)
      words = text_to_search.split(' ')

      case
      when looking_for.class == String || (looking_for.class == Array && looking_for.all? {|a| a.class == String})
        return matches if matches[match_class]
        looking_for = [looking_for] if looking_for.class != Array
        looking_for = looking_for.map{|a| a.singularize.downcase}
        # look for the longest possible matches and work our way down to the short ones
        0.upto(words.size-1) do |first|
          (words.size-1).downto(first) do |last|
            match = nil
            selection = (first..last).inject('') {|result, i| result += words[i] + ' '}.strip.downcase

            # puts "#{selection} vs #{phrases_to_look_for}"
            if looking_for.include?(selection.singularize.downcase)
              match = match_class.new(:ids => (first..last).to_a, :text => selection)
            end

            if !match
              selection_corrected = Spelling.check(selection.singularize)
              if selection_corrected && looking_for.include?(selection_corrected)
                selection_corrected = selection_corrected.pluralize if selection.plural?
                match = match_class.new(:ids => (first..last).to_a, :text => selection)
                match << Spelling.new(:ids => (first..last).to_a, :text => selection_corrected)
              end
            end

            if !match
              synonym = (Synonym.check((selection_corrected || selection).singularize) & looking_for).first
              if synonym
                match = match_class.new(:ids => (first..last).to_a, :text => selection)
                match << Synonym.new(:ids => (first..last).to_a, :text => selection.plural? ? synonym : synonym.pluralize)
              end
            end

            if !match 
              expansion = (Expansion.check((selection_corrected || selection).singularize) & looking_for).first
              if expansion
                match = match_class.new(:ids => (first..last).to_a, :text => selection)
                match << Expansion.new(:ids => (first..last).to_a, :text => selection)
              end
            end

            matches[match_class] = [] if !matches[match_class]
            if match
              matches[match_class] << match
            end
          end
        end

      when looking_for.class <= Fragment

        return matches if matches[looking_for]
        matches = klass.find(text_to_search, matches)

      when (looking_for.class == Hash && looking_for[:or]) || looking_for.class == Array

        looking_for.each do |term|
          matches = Fragment.find(text_to_search, term, matches, match_class)
        end

      when looking_for.class == Hash && looking_for[:and] # look for a sequence of strings and/or fragments
        looking_for = looking_for[:and]

        # first we find the starting term
        if looking_for.first.class == Class && looking_for.first <= Fragment
          matches = looking_for.first.find(text_to_search, matches)
          starting_term_matches = matches[looking_for.first]
        else
          starting_term_matches = Fragment.find(text_to_search, looking_for.first).values.first
        end

        # look for the next string/fragment in the sequence
        (starting_term_matches || []).each do |first_term|
          fragments = [first_term]
          looking_for[1..-1].each do |term|
            if term.class == Class && term <= Fragment
              matches = term.find(text_to_search, matches) if !matches[term]
              matches[term].each do |match|
                if match.ids.first == fragments.select {|a| a}.last.ids.last + 1
                  fragments << match
                end
              end
            elsif term.class == Array || term.class == String # handle strings and arrays of strings ORed together
              term_updated = term.class == Array ? term : [term]
              (Fragment.find(text_to_search, term_updated).values.first || []).each do |match|
                if match.ids.first == fragments.select {|a| a}.last.ids.last + 1
                  fragments << Fragment.new(:ids => match.ids, :text => match.to_s)
                end
              end
            elsif term.class == Hash
              (Fragment.find(text_to_search, term).values.first || []).each do |match|
                if match.ids.first == fragments.select {|a| a}.last.ids.last + 1
                  fragments << Fragment.new(:ids => match.ids, :text => match.to_s)
                end
              end
            else # turn nils into fragments
              last_fragment = fragments.select {|a| a}.last
              id = last_fragment.ids.last + 1
              fragments << Fragment.new(:ids => [id], :text => words[id])
            end
          end

          # found a match
          looking_for_updated = looking_for.map{|a| [String, Array, Hash, NilClass].include?(a.class) ? Fragment : a}

          if fragments.map{|a| a.class} == looking_for_updated
            ids = (fragments.first.ids.first..fragments.last.ids.last).to_a
            text = fragments.inject('') {|memo, fragment| memo += fragment.to_s + ' '}.strip
            match = match_class.new(:ids => ids, :text => text)
            fragments.each do |fragment|
              match << fragment
            end

            matches[match_class] = [] if !matches[match_class]
            if match
              matches[match_class] << match
            end
          end
        end
      end

      matches
    end

  end

  class Unused < Fragment
  end

end