class SuperlativePerson < ActiveRecord::Base
  acts_as_marker do |marker, markable, mark|
    markable_name = markable.name.downcase
    alias_method "#{"the_most_#{mark}_#{markable_name}".pluralize}", "#{"#{mark}_#{markable_name}".pluralize}"
  end
end
