class String
  def plural?
    self != self.singularize && self == self.pluralize
  end
end
