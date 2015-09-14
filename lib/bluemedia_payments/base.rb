module BluemediaPayments
  module Base

    def self.included(klass)
      klass.include(ActiveModel::Validations)
      klass.include(ActiveAttr::Model)

      klass.extend(ClassMethods)
    end

    module ClassMethods
      def define_attributes(*attributes)
        attributes.each do |_attribute|
          attribute _attribute
        end
      end

      def xml_parser
        Nori.new(convert_tags_to: lambda { |tag| tag.snakecase.to_sym })
      end
    end
  end
end
