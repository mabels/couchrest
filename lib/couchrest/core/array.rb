module CouchRest

  class Array 

    (::Array.instance_methods-::Array.superclass.instance_methods).each do |fn|
      class_eval <<-METH, __FILE__, __LINE__
        def #{fn}(*a)
          @my.#{fn}(*a) 
        end
      METH
    end

    include ::CouchRest::Parent

    def initialize(*a) 
      @my = ::Array.new(*a)
    end

    def kind_of?(c)
      c == ::Array || super
    end

    def collect
       ret = self.class.new
       self.each { |i| (tmp = yield(i)) && ret << tmp }
    end
    def <<(*a)
     @my.push(*a)
     a.each { |b| b.respond_to?('parent=') && b.parent = self }
    end

    def push(*a)
     @my.push(*a)
     a.each { |b| b.respond_to?('parent=') && b.parent = self }
    end

    def to_json(*a)
      @my.to_json(*a)
    end

  end
  
end
