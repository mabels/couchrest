require 'date'
module CouchRest
  module Mixins
    module Properties
      class CastDate < CasterBase
        def result_typ
          Date
        end
        def result_class_name
          Date.name
        end
        def default_value
          Date.today
        end
        def from_string(str)
          Date.parse(str)
        end
      end
      register_typ_cast CastDate
    end
  end
end
