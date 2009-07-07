module CouchRest
  class Response 
    include CouchRest::Parent

    attr_reader :attributes
 
    def initialize(pkeys = {})
      @attributes ||= {}
      @parent = pkeys.delete(:parent)
      pkeys.each do |k,v| 
        @attributes[k.to_sym] = v 
      end
    end
    def []=(key, value)
      @attributes ||= {}
      @attributes[key.to_sym] = value
    end
    def [](key)
      @attributes ||= {}
      @attributes[key.to_sym]
    end
    def has_key?(key)
      @attributes ||= {}
      @attributes.has_key?(key.to_sym)
    end
    def delete(key)
      @attributes ||= {}
      @attributes.delete(key.to_sym)
    end
    def clear
      @attributes.clear
    end
    def each
      @attributes.each { |k,v| yield k,v }
    end
    def ==(p)
      attributes == p.attributes
    end
    def inspect
      out = ["<#{self.class.name}(#{self.object_id}):{"]
      @attributes ||= {}
      comma = ''
      attributes.each do |k,v|
        out << "#{comma}#{k.inspect}=>(#{v.class.name}):#{v.inspect}"
        comma = ','
      end
      out << '}>'
      out.join('')
    end
    def to_json
      @attributes ||= {}
      attributes.to_json
    end
  end
end
