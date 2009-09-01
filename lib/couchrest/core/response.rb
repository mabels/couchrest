module CouchRest
  class Response 
    include CouchRest::Parent
#    include CouchRest::Hash

    attr_reader :attributes
    attr_accessor :id
    attr_accessor :rev
    attr_accessor :couchrest_typ
 
    def initialize(pkeys = {})
      @attributes = {}
      if pkeys.kind_of? Hash
         @parent = pkeys.delete(:parent) # kaputt
         @id =  pkeys.delete('_id') || nil
         @rev = pkeys.delete('_rev') || nil
         @couchrest_typ = pkeys.delete('couchrest-typ') || nil
      elsif pkeys.kind_of? Response
         @parent = pkeys.parent
         @id = pkeys.id
         @rev = pkeys.rev
         @couchrest_typ = pkeys.couchrest_typ
      end
      pkeys.each do |k,v| 
        @attributes[k.to_sym] = v 
      end
    end

    def ==(p)
      attributes == p.attributes
    end
    def inspect
      out = ["<#{self.class.name}(#{self.object_id}):{"]
      comma = ''
      attributes.each do |k,v|
        out << "#{comma}#{k.inspect}=>(#{v.class.name}):#{v.inspect}"
        comma = ','
      end
      out << '}>'
      out.join('')
    end
    def internals
      internals = {}
      internals['_id'] = id if id 
      internals['_rev'] = rev if rev 
      internals['couchrest-typ'] = id if couchrest_typ 
      internals
    end
    def to_hash
      ret = internals.merge(attributes)
#puts "TOHASH #{ret.inspect}"
      ret
    end
    def to_json
      to_hash.to_json
    end

    def []=(key, value)
      attributes[key.to_sym] = value
    end
    def [](key)
      attributes[key.to_sym]
    end
    def has_key?(key)
      attributes.has_key?(key.to_sym)
    end
    def delete(key)
      attributes.delete(key.to_sym)
    end
    def clear
      attributes.clear
    end
    def each
      attributes.each { |k,v| yield k,v }
    end


  end
end
