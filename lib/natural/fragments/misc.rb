# e.g. last
class Determiner < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['this', 'last', 'next'])
  end
end

# e.g. over
class Preposition < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['over', 'during', 'in', 'on', 'through'])
  end
end

# e.g. I, we
class Pronoun < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['i', 'we'])
  end
end

# e.g. spent, total
class Sum < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:or => ['spend', 'spent', 'total', {:and => ['how much did', Pronoun , 'spend']}, {:and => ['how much have', Pronoun, 'spent']}]})
  end
  def aggregator
    'sum'
  end
end
