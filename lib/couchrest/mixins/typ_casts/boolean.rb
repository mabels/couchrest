
module CouchRest
  module Mixins
    module Properties
      class CastBoolean < CasterBase
        class Boolean
          def self.name
            'boolean'
          end
        end
        def getter_and_setter_code(property)
          ret = super
          ret += <<-EOS
             def #{property.name}?
               !(self['#{property.name}'].nil? || self['#{property.name}'] == false || self['#{property.name}'].to_s.downcase == 'false')
             end
          EOS
          ret
        end
        def result_typ
          Boolean
        end
        def result_class_name
          Boolean.name
        end
        def default_value
          true
        end
        def from_string(str)
          str
        end
      end
      register_typ_cast CastBoolean
    end
  end
end
