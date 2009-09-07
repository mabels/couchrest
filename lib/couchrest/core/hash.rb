module CouchRest

  class Hash < ::Hash
    include ::CouchRest::Parent
    def []=(a)
      super
      a.respond_to?('parent=') && a.parent = self
    end
    def merge(a)
      a.each do |k,v|
         v.respond_to?('parent=') && v.parent = self
      end
      super
    end
    def merge!(a)
      a.each do |k,v|
         v.respond_to?('parent=') && v.parent = self
      end
      super
    end
  end
  
end
