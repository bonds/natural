require 'date'

# e.g. yesterday
class RelativeDateName < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['yesterday', 'today', 'tomorrow'])
  end
end

# e.g. January
class MonthName < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => Date::MONTHNAMES.select{|a| a})
  end
end

# e.g. Monday
class DayName < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => Date::DAYNAMES)
  end
end

# e.g. month
class UnitOfTime < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['second', 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year', 'decade', 'century'])
  end
end

# e.g. last month
class Dut < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:and => [Determiner, UnitOfTime]})
  end
end

# e.g. last January
class Dmn < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:and => [Determiner, MonthName]})
  end
end

# e.g. in January
class Pmn < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:and => [Preposition, MonthName]})
  end
end

# e.g. over the last month
class Pdut < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:and => [Preposition, 'the', Dut]})
  end
end
