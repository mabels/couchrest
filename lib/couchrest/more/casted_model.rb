require File.join(File.dirname(__FILE__), '..', 'mixins', 'properties')

module CouchRest
  module CastedModel
    
    def self.included(base)
      base.send(:include, CouchRest::Mixins::Properties)
      base.send(:attr_accessor, :casted_by)
    end
    
    def initialize(keys={})
      super
      keys.each do |k,v|
        self[k.to_s] = v
      end if keys
      apply_defaults # defined in CouchRest::Mixins::Properties
      # cast_keys      # defined in CouchRest::Mixins::Properties
    end
    
    def []= key, value
      super(key.to_s, value)
    end
    
    def [] key
      super(key.to_s)
    end

    def to_json(*a)
      {
        JSON.create_id => self.class.name,
      }.merge(self).to_json(*a)
    end

    def self.json_create(o)
      o.delete JSON.create_id
      new.merge(o)
    end

  end
end
