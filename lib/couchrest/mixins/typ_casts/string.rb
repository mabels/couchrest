
module CouchRest
  module Mixins
    module Properties
      class CastString < CasterBase
        def result_typ
          String
        end
        def result_class_name
          String.name
        end
        def default_value
          String.new
        end
        def from_string(str)
          str
        end
      end
      register_typ_cast CastString
    end
  end
end
