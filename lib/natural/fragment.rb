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
        location = self
        if !options[:without_edits]
          while !location.is_root? && location.parent.class < Natural::Alternative do
            location = location.parent
          end
        end
        location.text
      else
        self.children.inject('') {|result, item| (result += item.to_s + ' ')}.strip
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

    def clone(height=nil)
      result = self.class.new(:ids => self.ids, :text => self.text)
      if !height || height > 0
        self.children.each do |child|
          result << child.clone(height ? height-1 : nil)
        end
      end
      result
    end

    def self.find(options)
      text_to_search = options[:text]
      looking_for = options[:looking_for]
      old_matches = options[:matches] || {}
      if options[:matches] && (options[:merge_results].class == NilClass || options[:merge_results])
        new_matches = options[:matches]
      else
        new_matches = {}
      end
      match_class = options[:match_class] || self
      words = text_to_search.split(' ')

      case
      when looking_for.class == String || (looking_for.class == Array && looking_for.all? {|a| a.class == String})
        return old_matches if old_matches[match_class]
        looking_for = [looking_for] if looking_for.class != Array
        looking_for = looking_for.map{|a| a.singularize.downcase}

        # look for the longest possible matches and work our way down to the short ones
        0.upto(words.size-1) do |first|
          (words.size-1).downto(first) do |last|
            match = nil
            selection = words[(first..last)].join(' ').strip.downcase

            if looking_for.include?(selection.singularize.downcase)
              match = match_class.new(:ids => (first..last).to_a, :text => selection)
            end

            # didn't find a simple match, try swapping some or all words for alternatives and try again
            if !match && !(match_class < Natural::Alternative)
              fragments = old_matches.select {|k,v| k < Natural::Alternative && !v.blank?}.values.flatten.select {|a| a.ids.first >= first && a.ids.last <= last}

              # assemble a list of all the possible, non-overlapping swaps
              combinations = (1..fragments.size).inject([]) do |memo, i| 
                fragments.combination(i).each do |combo|
                  if !combo.combination(2).any? {|a| (a[0].ids.first..a[0].ids.last).overlaps?(a[1].ids.first..a[1].ids.last)}
                    memo << combo
                  end
                end                
                memo
              end

              combinations.each do |combo|
                alternative_words = words.clone
                alternative_fragments = []

                combo.each do |fragment|
                  alternative_words.slice!(fragment.ids.first..fragment.ids.last)
                  alternative_words.insert(fragment.ids.first, fragment.to_s)
                  alternative_fragments << fragment
                end
                alternative_selection = alternative_words[(first..last)].join(' ').strip.downcase

                if looking_for.include?(alternative_selection.singularize.downcase)
                  match = match_class.new(:ids => (first..last).to_a, :text => alternative_selection)
                  leftovers = ((first..last).to_a - combo.map {|a| a.ids}.flatten).to_ranges
                  leftovers.each do |range|
                    alternative_fragments << Fragment.new(:ids => range.to_a, :text => words[range].join(' '))
                  end
                  alternative_fragments.sort_by {|a| a.ids.first}.each {|a| match << a}
                end

              end
            end

            new_matches[match_class] = [] if !new_matches[match_class]
            if match
              if match_class < Natural::Alternative
                new_matches = recurse_alternatives(match, options)
              else
                new_matches[match_class] << match
              end
            end
          end
        end

      when looking_for.class <= Fragment

        return old_matches if old_matches[looking_for]
        new_matches = klass.find(:text => text_to_search, :matches => old_matches, :spellings => options[:spellings], :synonyms => options[:synonyms], :expansions => options[:expansions])

      when (looking_for.class == Hash && looking_for[:or]) || looking_for.class == Array

        looking_for.each do |term|
          new_matches = Fragment.find(:text => text_to_search, :looking_for => term, :matches => old_matches, :match_class => match_class, :spellings => options[:spellings], :synonyms => options[:synonyms], :expansions => options[:expansions])
        end

      when looking_for.class == Hash && looking_for[:and] # look for a sequence of strings and/or fragments
        looking_for = looking_for[:and]
        # first we find the starting term
        if looking_for.first.class == Class && looking_for.first <= Fragment
          new_matches = looking_for.first.find(:text => text_to_search, :matches => old_matches, :spellings => options[:spellings], :synonyms => options[:synonyms], :expansions => options[:expansions])
          starting_term_matches = old_matches[looking_for.first]
        else
          starting_term_matches = Fragment.find(options.merge(:looking_for => looking_for.first, :merge_results => false)).values.first
        end

        # look for the next string/fragment in the sequence
        (starting_term_matches || []).each do |first_term|
          fragments = [first_term]
          looking_for[1..-1].each do |term|
            if term.class == Class && term <= Fragment
              new_matches = term.find(:text => text_to_search, :matches => old_matches, :spellings => options[:spellings], :synonyms => options[:synonyms], :expansions => options[:expansions]) if !old_matches[term]
              new_matches[term].each do |match|
                if match.ids.first == fragments.select {|a| a}.last.ids.last + 1
                  fragments << match
                end
              end
            elsif [Array, Hash, String].include?(term.class)
              term_updated = term.class == String ? [term] : term
              (Fragment.find(:text => text_to_search, :looking_for => term_updated, :spellings => options[:spellings], :synonyms => options[:synonyms], :expansions => options[:expansions]).values.first || []).each do |match|
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

            new_matches[match_class] = [] if !new_matches[match_class]
            if match
              new_matches[match_class] << match
            end
          end
        end
      end

      new_matches
    end

    def self.recurse_alternatives(match, options)
      new_matches = options[:matches]

      match.replacements(options).each do |replacement|
        new_matches[match_class] = [] if !new_matches[match.class]
        new_matches[match.class] << replacement

        unused_alternatives = ObjectSpace.each_object(Class).select {|a| a < Natural::Alternative}
        replacement.breadth_each {|node| unused_alternatives -= [node.class]}

        unused_alternatives.each do |alternative|
          next_layer = alternative.find(options.merge(:text => replacement.to_s, :matches => {})).values.first
          next_layer.each do |frag|
            new_frag = frag.class.new(:ids => replacement.ids, :text => frag.text)
            new_frag << replacement.clone
            new_matches = recurse_alternatives(new_frag, options)
          end
        end
      end

      new_matches
    end

  end

  class Word < Fragment
  end

  class Unused < Fragment
  end

  class Alternative < Fragment
    def score
      super - 2
    end
  end

  class Spelling < Alternative
    def self.find(options)
      super options.merge(:looking_for => options[:spellings].values.flatten)
    end
    def replacements(options)
      options[:spellings].each do |canonical, alternatives|
        if alternatives.include?(self.to_s)
          return [canonical].map do |alternative_text|
            if self.node_height == 0
              alternative = self.class.new(:ids => self.ids, :text => alternative_text)
              alternative << Fragment.new(:ids => (alternative.ids.first..alternative.ids.last).to_a, :text => options[:text].split(' ')[alternative.ids.first..alternative.ids.last].join(' '))
              alternative
            else
              [self]
            end
          end
        end
      end
    end
  end

  class Synonym < Alternative
    def self.find(options)
      super options.merge(:looking_for => options[:synonyms].values.flatten)
    end
    def replacements(options)
      options[:synonyms].values.each do |alternatives|
        if alternatives.include?(self.to_s)
          # binding.pry
          return (alternatives - [self.to_s]).map do |alternative_text|
            if self.node_height == 0
              alternative = self.class.new(:ids => self.ids, :text => alternative_text)
              alternative << Fragment.new(:ids => (alternative.ids.first..alternative.ids.last).to_a, :text => options[:text].split(' ')[alternative.ids.first..alternative.ids.last].join(' '))
              alternative
            else
              return [self]
            end
          end
        end
      end
    end
  end

  # class Expansion < Alternative
  #   def self.find(options)
  #     super options.merge(:looking_for => options[:expansions].keys)
  #   end
  #   def replacement(options)
  #     options[:expansions][self.to_s]
  #   end
  # end

end