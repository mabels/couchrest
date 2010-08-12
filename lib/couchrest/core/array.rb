module CouchRest

  class Array 

    (::Array.instance_methods-::Array.superclass.instance_methods).each do |fn|
      class_eval <<-METH, __FILE__, __LINE__
        def #{fn}(*a, &block)
          @my.#{fn}(*a, &block) 
        end
      METH
    end

    include ::CouchRest::Parent

    def initialize(*a) 
      @my = ::Array.new(*a)
    end

    def is_a?(c)
      kind_of?(c)
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

    def to_a
      @my
    end

  end
  
end
