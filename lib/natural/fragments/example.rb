# how many days of the week start with the letter t

# e.g. how many
class Count < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['how many'])
  end
  def meaning
    {
      :select => "count(*)"
    }
  end
end

# e.g. days of the week
class DayNames < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['days of the week'])
  end
  def meaning
    {
      :from => '(' + Date::DAYNAMES.map{|a| "SELECT '#{a}' as day_name"}.join(' UNION ALL ') + ') as day_names'
    }
  end
end

# e.g. blu-ray
class BluRay < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => ['blu-ray'])
  end
end

# e.g. start with the letter t
class StartsWithLetter < Natural::Fragment
  def self.find(options)
    super options.merge(:looking_for => {:and => ['start with the letter', {:or => ('a'..'z').to_a}]})
  end
  def meaning
    {
      :where => "column_to_filter LIKE #{children.last.text}%"
    }
  end
end
