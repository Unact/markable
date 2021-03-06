module Markable
  module ActsAsMarker
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_marker(options = {}, &block)
        class_eval do
          class << self
            attr_accessor :marker_name
          end
        end
        self.marker_name = self.name.downcase.gsub("::", "_").to_sym

        class_eval do
          has_many :marker_marks, :class_name => 'Markable::Mark', :as => :marker, :dependent => :delete_all
          include Markable::ActsAsMarker::MarkerInstanceMethods
        end
        Markable.add_marker self, &block
      end
    end

    module MarkerInstanceMethods
      def method_missing(method_sym, *args)
        super
      rescue NoMethodError
        Markable.load_models
        Markable.models.each do |model_name|
          if method_sym.to_s =~ Regexp.new("^[\\w]+_#{model_name.downcase.pluralize}$") ||
             method_sym.to_s =~ Regexp.new("^#{model_name.downcase.pluralize}_marked_as(_[\\w]+)?$")
            model_name.constantize

            return self.method(method_sym).call(*args) if self.methods.include?(method_sym)
          end
        end

        raise
      end

      def set_mark(mark, markables)
        Array.wrap(markables).each do |markable|
          Markable.can_mark_or_raise? self, markable, mark
          markable.mark_as mark, self
        end
      end

      def remove_mark(mark, markables)
        Markable.can_mark_or_raise? self, markables, mark
        Array.wrap(markables).each do |markable|
          markable.unmark mark, :by => self
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Markable::ActsAsMarker
