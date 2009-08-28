
module CouchRest
  module Mixins
    module Properties
      class CastInteger < CasterBase
        def result_typ
          Fixnum
        end
        def result_class_name
          Fixnum.name
        end
        def default_value
          0
        end
        def from_string(str)
          str.to_i
        end
      end
      register_typ_cast CastInteger
    end
  end
end
