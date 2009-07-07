module CouchRest
  module Parent
      attr_accessor :parent
      def document
        (!parent && self) || (parent && parent.document)
      end
  end
end
