require 'date'

# e.g. yesterday
class RelativeDateName < Natural::Fragment
  def self.find(text, matches)
    super(text, ['yesterday', 'today', 'tomorrow'], matches)
  end
end

# e.g. January
class MonthName < Natural::Fragment
  def self.find(text, matches)
    super(text, Date::MONTHNAMES.select{|a| a}, matches)
  end
end

# e.g. Monday
class DayName < Natural::Fragment
  def self.find(text, matches)
    super(text, Date::DAYNAMES, matches)
  end
end

# e.g. month
class UnitOfTime < Natural::Fragment
  def self.find(text, matches)
    result = super(text, ['second', 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year', 'decade', 'century'], matches)
    result
  end
end

# e.g. last month
class Dut < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Determiner, UnitOfTime]}, matches)
  end
end

# e.g. last January
class Dmn < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Determiner, MonthName]}, matches)
  end
end

# e.g. in January
class Pmn < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Preposition, MonthName]}, matches)
  end
end

# e.g. over the last month
class Pdut < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Preposition, 'the', Dut]}, matches)
  end
end
