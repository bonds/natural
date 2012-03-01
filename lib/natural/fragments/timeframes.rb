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

# e.g. last month
class DpU < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Determiner, UnitOfTime]}, matches)
  end

  def filter
    determiner = self.children[0].to_s
    unit_of_time = self.children[1].to_s

    case determiner
    when 'this'
      target_date = Time.now
    when 'last'
      target_date = Time.now - 1.send(unit_of_time)
    when 'next'
      target_date = Time.now + 1.send(unit_of_time)
    end

    case unit_of_time
    when 'week'
      #TODO
    when 'month'
      start_date = Date.civil(target_date.year, target_date.month, 1)
      end_date = Date.civil(target_date.year, target_date.month, -1)
    when 'year'
      start_date = Date.civil(target_date.year, 1, 1)
      end_date = Date.civil(target_date.year, -1, -1)
    end

    "where(\"receipts.issued_on BETWEEN '#{start_date}' AND '#{end_date}'\")"
  end
end

# e.g. last January
class DpMN < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Determiner, MonthName]}, matches)
  end

  def filter
    determiner = self.children[0].to_s
    month = self.children[1].to_s

    case determiner
    when 'this'
      target_date = Date.parse(month)
      target_date -= 1.year if target_date > Time.now.to_date
    when 'last'
      target_date = Date.parse(month)
      target_date -= 1.year if target_date > Time.now.to_date
    when 'next'
      return
    end

    start_date = Date.civil(target_date.year, target_date.month, 1)
    end_date = Date.civil(target_date.year, target_date.month, -1)

    "where(\"receipts.issued_on BETWEEN '#{start_date}' AND '#{end_date}'\")"
  end
end

# e.g. in January
class PpMN < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Preposition, MonthName]}, matches)
  end

  def filter
    preposition = self.children[0].to_s
    month = self.children[1].to_s

    target_date = Date.parse(month)
    target_date -= 1.year if target_date > Time.now.to_date

    start_date = Date.civil(target_date.year, target_date.month, 1)
    end_date = Date.civil(target_date.year, target_date.month, -1)

    "where(\"receipts.issued_on BETWEEN '#{start_date}' AND '#{end_date}'\")"
  end
end

# e.g. over the last month
class PpDpU < Natural::Fragment
  def self.find(text, matches)
    super(text, {:and => [Preposition, 'the', DpU]}, matches)
  end

  def filter
    preposition = self.children.select{|a| a.class == Preposition}.first.to_s
    dtut = self.children.select{|a| a.class == DpU}.first
    determiner = dtut.children.select{|a| a.class == Determiner}.first.to_s
    unit_of_time = dtut.children.select{|a| a.class == UnitOfTime}.first.to_s
    case
    when ['over', 'during', 'in'].include?(preposition)
      case determiner
      when 'this'
      when 'last'
        end_date = Time.now.to_date
        start_date = end_date - 1.send(unit_of_time)
        "where(\"receipts.issued_on BETWEEN '#{start_date}' AND '#{end_date}'\")"
      when 'next'
      end
    when preposition == 'on'
    when preposition == 'through'
    end
  end

end
