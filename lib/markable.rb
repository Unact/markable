require 'rake'
require 'active_record'
require 'models/mark'
load 'tasks/markable.rake'


module Markable
  mattr_accessor :markers, :markables, :models
  @@markers   = []
  @@markables = []
  @@models    = []
  @@markers_block = {}
  @@marker_objects   = []
  @@markable_objects = []

protected

  def self.set_models
    @@models = @@models.presence || ActiveRecord::Base.connection.tables.collect{ |t| t.classify rescue nil }.compact
  end

  def self.add_markable(markable)
    @@markable_objects.push markable unless @@markable_objects.include? markable
    @@markables.push markable.name.to_sym unless @@markables.include? markable.name.to_sym
    create_methods @@marker_objects, [ markable ]
  end

  def self.add_marker(marker, &block)
    @@marker_objects.push marker unless @@marker_objects.include? marker
    @@markers.push marker.name.to_sym unless @@markers.include? marker.name.to_sym
    @@markers_block[marker.name.to_sym] = block if block_given?
    create_methods [ marker ], @@markable_objects
  end

  def self.create_methods(markers, markables)
    markables.try :each do |markable|
      markers.try :each do |marker|
        markable.__markable_marks.each do |mark, options|
          if options[:allowed_markers] == :all || options[:allowed_markers].include?(marker.marker_name)
            markable_name = markable.name.downcase

            unless marker.method_defined? "#{markable_name.pluralize}_marked_as"
              marker.class_eval %(
                def #{markable_name.pluralize}_marked_as mark
                  #{markable.name}.marked_as mark, :by => self
                end
              )
            end

            unless marker.method_defined? "#{"#{mark}_#{markable_name}".pluralize}"
              marker.class_eval %(
                def #{"#{mark}_#{markable_name}".pluralize}
                  #{markable.name}.marked_as :#{mark}, :by => self
                end
                def #{markable_name.pluralize}_marked_as_#{mark}
                  #{markable.name}.marked_as :#{mark}, :by => self
                end
              )
            end

            unless marker.method_defined? "mark_as_#{mark}"
              marker.class_eval %(
                def mark_as_#{mark}(objects)
                  self.set_mark :#{mark}, objects
                end
              )
            end

            unless markable.method_defined? "#{marker.marker_name.to_s.pluralize}_have_marked_as"
              markable.class_eval %(
                def #{marker.marker_name.to_s.pluralize}_have_marked_as mark
                  self.have_marked_as_by(mark, #{marker.name})
                end
              )
            end

            unless markable.method_defined? "#{marker.marker_name.to_s.pluralize}_have_marked_as_#{mark}"
              markable.class_eval %(
                def #{marker.marker_name.to_s.pluralize}_have_marked_as_#{mark}
                  self.have_marked_as_by(:#{mark}, #{marker.name})
                end
              )
            end

            @@markers_block[marker.name.to_sym].call(marker, markable, mark) if @@markers_block[marker.name.to_sym].present?
          end
        end
      end
    end
  end

  def self.can_mark_or_raise?(markers, markables, mark)
    Array.wrap(markers).all? do |marker_object|
      Array.wrap(markables).all? do |markable|
        self.can_mark_object?(marker_object, markable, mark)
      end
    end
  end

  def self.can_mark_object?(marker_object, markable_object, mark)
    marker_name = marker_object.class.name.to_sym
    markable_name = markable_object.class.name.to_sym
    raise Markable::WrongMarkerType.new(marker_name) unless @@markers.include?(marker_name)
    raise Markable::WrongMarkableType.new(markable_name) unless @@markables.include?(markable_name)
    raise Markable::WrongMark.new(marker_object, markable_object, mark) unless markable_object.class.__markable_marks.include?(mark)

    raise Markable::NotAllowedMarker.new(marker_object, markable_object, mark) unless (markable_object.class.__markable_marks[mark][:allowed_markers] == :all ||
                                                                  markable_object.class.__markable_marks[mark][:allowed_markers].include?(marker_name.to_s.downcase.to_sym))

    true
  end
end

require 'markable/exceptions'
require 'markable/acts_as_marker'
require 'markable/acts_as_markable'
