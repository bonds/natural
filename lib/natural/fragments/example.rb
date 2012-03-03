# how many days of the week start with the letter t

# e.g. how many
class Count < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['how many'])
  end
  def aggregator
    'count'
  end
end

# e.g. days of the week
class DayNames < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['days of the week'])
  end
  def data(context)
    Date::DAYNAMES
  end
end

# e.g. start with the letter t
class StartsWithLetter < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:and => ['start with the letter', {:or => ('a'..'z').to_a}]})
  end
  def filter
    "select {|a| a[0].downcase == '#{self.children.last.to_s.downcase}'}"
  end
end
