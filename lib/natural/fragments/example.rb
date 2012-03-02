# how many days of the week start with the letter A

# e.g. how many
class Count < Natural::Fragment
  def self.find(text, matches)
    super(text, ['how many'], matches)
  end
  def aggregator
    'count'
  end
end

# e.g. days of the week
class DayNames < Natural::Fragment
  def self.find(text, matches)
    super(text, ['days of the week'], matches)
  end
  def data(context)
    Date::DAYNAMES
  end
end

# e.g. start with the letter A
class StartsWithLetter < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => ['start with the letter', {:or => ('a'..'z').to_a}]}, matches)
  end
  def filter
    "select {|a| a[0].downcase == '#{self.children.last.to_s.downcase}'}"
  end
end
