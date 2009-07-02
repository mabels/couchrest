require 'time'
require File.join(File.dirname(__FILE__), '..', 'more', 'property')

module CouchRest
  module Mixins
    module Properties
      
      class IncludeError < StandardError; end

      def self.included(base)
        base.class_eval <<-EOS, __FILE__, __LINE__
            extlib_inheritable_accessor(:properties) unless self.respond_to?(:properties)
            self.properties ||= []
        EOS
        base.extend(ClassMethods)
        raise CouchRest::Mixins::Properties::IncludeError, "You can only mixin Properties in a class responding to [] and []=, if you tried to mixin CastedModel, make sure your class inherits from Hash or responds to the proper methods" unless (base.new.respond_to?(:[]) && base.new.respond_to?(:[]=))
      end

      def apply_defaults
        return unless self.respond_to?(:new_document?) && new_document?
        return unless self.class.respond_to?(:properties) 
        return if self.class.properties.empty?
        # TODO: cache the default object
        self.class.properties.each do |property|
          key = property.name.to_s
          # let's make sure we have a default and we can assign the value
          if property.default && (self.respond_to?("#{key}=") || self.has_key?(key))
              if property.default.class == Proc
                self[key] = property.default.call
              else
                self[key] = Marshal.load(Marshal.dump(property.default))
              end
            end
        end
      end
      
      def cast_keys
        return unless self.class.properties
        self.class.properties.each do |property|
          key = self.has_key?(property.name) ? property.name : property.name.to_sym
          self[key] = self.class.cast_property(key, self[key], self)
        end
      end
          
      
      module ClassMethods
        
        def property(name, options={})
          existing_property = self.properties.find{|p| p.name == name.to_s}
          if existing_property.nil? || (existing_property.default != options[:default])
            define_property(name, options)
          end
        end

        def cast_property(property_name, input_value, requesting_casting_type)
            return input_value unless input_value
            property = self.properties.find {|i| i.name.to_s == property_name.to_s}
            return input_value unless property
            return input_value unless property.casted
            target = property.type
            if target.respond_to?(:push)
              klass = ::CouchRest.constantize(target[0])
              input_value ||= []
              ret = target.class.new
              input_value.each do |value|
                # Auto parse Time objects
                obj = ( (property.init_method == 'new') && klass == Time) ? Time.parse(value) : klass.send(property.init_method, value)
                obj.casted_by = self if obj.respond_to?(:casted_by)
                ret.push(obj)
              end
            else
              # Auto parse Time objects
              ret = if ((property.init_method == 'new') && target == 'Time') 
                input_value.is_a?(String) ? Time.parse(input_value.dup) : input_value
              else
                # Let people use :send as a Time parse arg
                klass = ::CouchRest.constantize(target)
                # I'm not convince we should or should not create a new instance if we are casting a doc/extended doc without default value and nothing was passed
                # unless (property.casted && 
                #   (klass.superclass == CouchRest::ExtendedDocument || klass.superclass == CouchRest::Document) && 
                #     (self[key].nil? || property.default.nil?))
                klass.send(property.init_method, input_value)
                #end
              end
              ret.casted_by = requesting_casting_type if ret.respond_to?(:casted_by)
            end
            ret
        end
        
        protected
        
          # This is not a thread safe operation, if you have to set new properties at runtime
          # make sure to use a mutex.
          def define_property(name, options={})
            # check if this property is going to casted
            options[:casted] = options[:cast_as] ? options[:cast_as] : false
            property = CouchRest::Property.new(name, (options.delete(:cast_as) || options.delete(:type)), options)
            create_property_getter(property) 
            create_property_setter(property) unless property.read_only == true
            properties << property
          end
          
          # defines the getter for the property (and optional aliases)
          def create_property_getter(property)
            # meth = property.name
            class_eval <<-EOS, __FILE__, __LINE__
              def #{property.name}
                self['#{property.name}']
              end
            EOS

            if property.alias
              class_eval <<-EOS, __FILE__, __LINE__
                alias #{property.alias.to_sym} #{property.name.to_sym}
              EOS
            end
          end

          # defines the setter for the property (and optional aliases)
          def create_property_setter(property)
            meth = property.name
            class_eval <<-EOS
              def #{meth}=(value)
                self['#{meth}'] = value
              end
            EOS

            if property.alias
              class_eval <<-EOS
                alias #{property.alias.to_sym}= #{meth.to_sym}=
              EOS
            end
          end
          
      end # module ClassMethods
      
    end
  end
end
