# e.g. I, we
class Pronoun < Natural::Fragment
  def self.find(text, matches)
    super(text, ['I', 'we'], matches)
  end

  def data(user)
    result = ["User.find(#{user.id}).items"]
    case self.to_s.downcase
    when 'i'
    when 'we'
      result << "User.find(#{user.id}).friends.first.items" if !user.friends.blank?
    end

    result
  end
end

# e.g. spent, total
class Sum < Natural::Fragment
  def self.find(text, matches)
    super(text, {:or => ['spend', 'spent', 'total', {:and => ['how much did', Pronoun , 'spend']}, {:and => ['how much have', Pronoun, 'spent']}]}, matches)
  end

  def accumulator
    :sum
  end

  def data(user)
    pronoun = self.children.select {|a| a.class == Pronoun}.first
    pronoun ? pronoun.data(user) : super
  end
end

# e.g. bought
class Itemize < Natural::Fragment
  def self.find(text, matches)
    super(text, ['bought'], matches)
  end
  def accumulator
    :itemize
  end
end

# e.g. how many
class Count < Natural::Fragment
  def self.find(text, matches)
    super(text, ['how many'], matches)
  end
  def accumulator
    :count
  end
end
