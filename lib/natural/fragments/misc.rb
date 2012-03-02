# e.g. last
class Determiner < Natural::Fragment
  def self.find(text, matches)
    super(text, ['this', 'last', 'next'], matches)
  end
end

# e.g. over
class Preposition < Natural::Fragment
  def self.find(text, matches)
    super(text, ['over', 'during', 'in', 'on', 'through'], matches)
  end
end

# e.g. I, we
class Pronoun < Natural::Fragment
  def self.find(text, matches)
    super(text, ['i', 'we'], matches)
  end
end

# e.g. spent, total
class Sum < Natural::Fragment
  def self.find(text, matches)
    super(text, {:or => ['spend', 'spent', 'total', {:and => ['how much did', Pronoun , 'spend']}, {:and => ['how much have', Pronoun, 'spent']}]}, matches)
  end
  def aggregator
    :sum
  end
end
