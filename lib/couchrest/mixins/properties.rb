require 'time'
require File.join(File.dirname(__FILE__), '..', 'more', 'property')

class Time
  # returns a local time value much faster than Time.parse
  def self.mktime_with_offset(string)
    string =~ /(\d{4})\/(\d{2})\/(\d{2}) (\d{2}):(\d{2}):(\d{2}) ([\+\-])(\d{2})/
    # $1 = year
    # $2 = month
    # $3 = day
    # $4 = hours
    # $5 = minutes
    # $6 = seconds
    # $7 = time zone direction
    # $8 = tz difference
    # utc time with wrong TZ info:
    time = mktime($1, RFC2822_MONTH_NAME[$2.to_i - 1], $3, $4, $5, $6, $7)
    tz_difference = ("#{$7 == '-' ? '+' : '-'}#{$8}".to_i * 3600)
    time + tz_difference + zone_offset(time.zone)
  end
end

module CouchRest

  module Mixins
    module Properties
      class CasterBase
        def getter_and_setter_code(property)
          ret = []
          ret.push <<-EOS
            def #{property.name}
              self['#{property.name}']
            end
          EOS
          ret << "alias #{property.alias.to_sym} #{property.name.to_sym}" if property.alias
          unless property.read_only
            ret.push <<-EOS
              def #{property.name}=(value)
                self['#{property.name}'] = value
              end
            EOS
            ret << "alias #{property.alias.to_sym}= #{property.name.to_sym}=" if property.alias
          end
          ret.join("\n")
        end
      end
      class Caster < CasterBase
        def initialize(cname, options)
          @klass_name = cname.to_s
          @from_string = options[:send] || :new
        end
        def result_typ
          @klass ||= CouchRest::constantize(@klass_name)
        end
        def result_class_name
          @klass_name
        end
        def from_string(str='')
          begin
             return result_typ.send(@from_string, str)
          rescue Exception => e
            raise "#{e} typ:#{result_class_name} method:#{@from_string} value:#{str.class.name}=>#{str.inspect}"
          end
        end
        def default_value
#puts "CASTER_DEFAULT_VALUE oid=#{self.object_id}  #{@klass_name}"
          from_string
        end
      end
      class ContainerCaster < CasterBase
        def initialize(cname, options)
#puts "ContainerCaster cname=#{cname} #{options.inspect}"
          @klass_name = cname.to_s
          @from_string = options[:send] || :new
          @item_class_name = options[:item_class_name]
        end
        def result_typ
          @klass ||= CouchRest::constantize(@klass_name)
        end
        def result_class_name
          "#{@klass_name}->#{@item_class_name}"
        end
        def item_typ
          @item_typ ||= CouchRest::constantize(@item_class_name)
        end
        def item_caster
          @item_caster ||= self.get_caster_from_class_name(item_typ.name)
        end
        def from_string(array=[])
          ret = default_value
          array.each do |item|
            ret.push(item_caster.from_string(item))
          end
        end
        def default_value
#puts "ContainerCaster::default_value:#{result_class_name}"
          result_typ.send(@from_string)
        end
      end

      def self.typ2cast_class
         @@typ2cast_class ||= {}
      end

      def self.register_instance_of_caster(instance)
        #puts "register_instance_of_caster:#{instance.result_class_name}"
        typ2cast_class[instance.result_class_name] = instance
        instance
      end

      def self.register_typ_cast(cast_class)
        register_instance_of_caster(cast_class.new)
      end

      def self.get_caster_from_class_name(caster_name, options = {})
        caster_typ = Caster
        if caster_name.respond_to?(:push)
          options[:item_class_name] = caster_name.first
          caster_name = caster_name.class.name
          caster_typ = ContainerCaster
        end
        caster_name = caster_name.to_s
        caster = CouchRest::Mixins::Properties.typ2cast_class[caster_name]
        caster = register_instance_of_caster(caster_typ.new(caster_name, options)) unless caster
#puts "CASTER:#{caster_typ.name} #{caster_name.inspect} #{caster.inspect}"
        caster
      end

      def self.get_caster_from_options(options)
        get_caster_from_class_name(options[:cast_as] || options[:type] || 'String', options)
      end

      class IncludeError < StandardError; end

      def self.included(base)
        base.class_eval <<-EOS, __FILE__, __LINE__
            extlib_inheritable_accessor(:properties) unless self.respond_to?(:properties)
            self.properties ||= {}
        EOS
        base.extend(ClassMethods)
        raise CouchRest::Mixins::Properties::IncludeError, "You can only mixin Properties in a class responding to [] and []=, if you tried to mixin CastedModel, make sure your class inherits from Hash or responds to the proper methods" unless (base.new.respond_to?(:[]) && base.new.respond_to?(:[]=))
      end

      def apply_defaults
        return if self.respond_to?(:new_document?) && (new_document? == false)
        return unless self.class.respond_to?(:properties)
        return if self.class.properties.empty?
        # TODO: cache the default object
        self.class.properties.each do |key,property|
#puts "TO-APPLY:#{key} #{property.default.inspect}"
          # let's make sure we have a default and we can assign the value
          if !property.default.nil? # && (self.respond_to?("#{key}=") || self.has_key?(key))
            if property.default.kind_of?(Proc)
              self[key] = property.default.call
              #puts "APPLY_DEFAULTS:PROC:#{key}=>#{property.inspect} ==> #{self[key].inspect}"
            else
              self[key] = Marshal.load(Marshal.dump(property.default)) # deep copy
              #puts "APPLY_DEFAULTS:DEEP:#{key}=>#{property.inspect} ==> #{self[key].inspect}"
            end
            self[key].respond_to?('parent=') && self[key].parent = self
          end
        end
      end

      def cast_keys
        return unless self.class.properties
#puts "CAST_KEYS #{self.class.name} => #{self.methods.grep(/=$/).inspect}"
        self.class.properties.each do |name, property|
#puts "CAST_KEYS #{name}=>#{property.inspect}"
          unless property.read_only
            self.send("#{name}=", self.class.cast_property(name, self.send(name), self))
          end
        end
      end


      module ClassMethods

        include CouchRest::Callbacks

        def property(name, options={})
            property = CouchRest::Property.new(name, CouchRest::Mixins::Properties.get_caster_from_options(options), options)
            class_eval property.caster.getter_and_setter_code(property)
            properties[property.name] = property
            @new_property_callbacks && @new_property_callbacks.each { |name| send(name, property) if respond_to?(name) }
        end

        def register_new_property_callback(*names)
            @new_property_callbacks ||= []
            @new_property_callbacks += names
        end

        def cast_property(property_name, input_value, requesting_casting_type)
            return input_value unless input_value
            property = self.properties[property_name.to_s]
            return input_value unless property
            unless input_value.kind_of? property.caster.result_typ
              input_value = property.caster.from_string(input_value)
              #input_value.casted_by = requesting_casting_type if input_value.respond_to?('casted_by=')
              input_value.parent = requesting_casting_type if input_value.respond_to?('parent=')
            end
            input_value
        end

      end # module ClassMethods

    end
  end
end

require File.join(File.dirname(__FILE__), 'typ_casts')
