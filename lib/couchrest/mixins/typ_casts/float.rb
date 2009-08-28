
module CouchRest
  module Mixins
    module Properties
      class CastFloat < CasterBase
        def result_typ
          Float
        end
        def result_class_name
          Float.name
        end
        def default_value
          0.0
        end
        def from_string(str)
#puts "CastFloat:#{str}"
          begin
            return Float(str)
          rescue
            return str
          end
        end
      end
      register_typ_cast CastFloat
    end
  end
end
