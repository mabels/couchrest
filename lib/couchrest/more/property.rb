module CouchRest

  # Basic attribute support for adding getter/setter + validation
  class Property
    attr_reader :name, :caster, :read_only, :alias, :default, :init_method, :options, :casted

    # attribute to define
    def initialize(name, caster, options = {})
      @name = name.to_s
      @caster = caster
      #parse_type(type)
      parse_options(options)
#puts "Property oid=#{self.object_id} name=#{name} #{caster.result_class_name} #{options.inspect} #{default.inspect}"
      self
    end

    def default_value
#puts "PROPERTY_DEFAULT_VALUE oid=#{self.object_id}  #{name} #{default.inspect} #{@caster.default_value}"
      (default.kind_of?(Proc) && default.call()) || (default) || @caster.default_value
    end

    private

      def parse_type(type)
        if type.nil?
          @type = 'String'
        elsif type.kind_of?(::Array)
          if type.empty?
            @type = type.class.name
          else
            @type = ::CouchRest::Array.new([type.first.to_s])
          end
        elsif type.kind_of?(Hash)
          @type = Kernel.const_get(type.keys.first).new()
          @type.push(type.values.first)
        else
          @type = type.to_s
        end
      end

      def parse_options(options)
        @validation_format  = options.delete(:format)     if options[:format]
        @read_only          = options.delete(:read_only)  if options[:read_only]
        @alias              = options.delete(:alias)      if options[:alias]
        @default            = options.delete(:default)    unless options[:default].nil?
        @casted             = !!(options[:cast_as] || options[:type]) 
        @init_method        = options[:send] ? options.delete(:send) : 'new' 
        @options            = options
      end

  end
end
