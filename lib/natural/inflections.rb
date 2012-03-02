require 'active_support/inflector'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'person', 'people'
  inflect.uncountable %w(is gas)
end
