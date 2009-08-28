
module CouchRest
  module Mixins
    module Properties
      class CastTime < CasterBase
        def result_typ
          Time
        end
        def result_class_name
          Time.name
        end
        def default_value
          Time.now
        end
        def from_string(str)
          Time.parse(str)
        end
      end
      register_typ_cast CastTime
    end
  end
end
