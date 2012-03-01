class Natural

  class Spelling
    TERMS = {
      'blu-ray' => ['bluray', 'blueray', 'blue ray', 'blu ray']
    }

    def self.check(selection)
      TERMS.each do |correct_spelling, alternative_spellings|
        return correct_spelling if alternative_spellings.include?(selection)
      end

      nil
    end
  end

  class Synonym
    TERMS = [
      ['cd', 'audio cd'],
      ['food', 'eat', 'dine']
    ]
    
    def self.check(selection)

      TERMS.each do |set|
        if set.include?(selection)
          result = set - [selection]
          return set - [selection] if !result.blank?
        end
      end

      []
    end
  end

  class Expansion
    TERMS = {
     'food' => ['grocery', 'eat out', 'eating out', 'dining out', 'dine out', 'dine in'],
     'music' => ['audio cd', 'audio tape'],
     'movie' => ['blu-ray', 'dvd', 'video']
    }
    
    def self.check(selection)
      TERMS[selection] || []
    end
  end

end