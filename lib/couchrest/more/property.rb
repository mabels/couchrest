module CouchRest

  # Basic attribute support for adding getter/setter + validation
  class Property
    attr_reader :name, :read_only, :default, :casted, :init_method, :options, :type, :coerce, :alias
    
    # attribute to define
    def initialize(name, options)
      @name = name.to_s
      @type = self.class.parse_type(options)
      @alias = []
      parse_options(options)
      self
    end
    
    private

      class Type
         attr_writer :item, :container
         def item
            @item = ::CouchRest.constantize(@item) if @item.kind_of?(::String) && @item.class != Class
            @item
         end
         def container
            @container = ::CouchRest.constantize(@container) if @container.kind_of?(::String) && @container.class != Class
            @container
         end
         def to_s
            "<Property::Type(#{self.object_id}):item=>#{item.inspect},container=>#{container.inspect}>"
         end
      end
    
      #(options.delete(:cast_as) || options.delete(:type)
      def self.parse_type(options)
        type = options.delete(:cast_as) || options.delete(:type) 
        ret = Type.new
        ret.item = String
        ret.container = nil
        if type.kind_of?(::Array) 
          if type.empty? 
            ret.container = type
          else
            ret.container = ::CouchRest::Array
            ret.item = type.first
          end
        elsif type.kind_of?(::Hash)
          ret.container = type.keys.first
          ret.item = type.values.first
        elsif !type.nil?
          ret.item = type
        end
#puts "TYPE:#{ret.inspect}"
        return ret
      end

      def alias=(a)
#puts "WORLD:"+a.inspect 
         if a.respond_to? :each
            @alias = a
         else
            @alias = [a]
         end 
      end
      
      def parse_options(options)
        return if options.empty?
        @validation_format  = options.delete(:format)     if options[:format]
        @read_only          = options.delete(:read_only)  if options[:read_only]
        self.alias          = options.delete(:alias)      if options[:alias]
        @default            = options.delete(:default)    if options[:default]
        @coerce             = options.delete(:coerce)     if options[:coerce]
        @casted             = options[:casted] ? true : false
        @init_method        = options[:send] ? options.delete(:send) : 'new'
        @options            = options
      end
    
  end
end
