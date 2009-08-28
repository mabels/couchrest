module CouchRest

  class Array < ::Array
    include ::CouchRest::Parent
    def collect
       ret = self.class.new
       self.each { |i| (tmp = yield(i)) && ret << tmp }
    end
    def <<(*a)
     super
     a.each { |b| b.respond_to?('parent=') && b.parent = self }
    end

    def push(*a)
     super
     a.each { |b| b.respond_to?('parent=') && b.parent = self }
    end
  end

end
