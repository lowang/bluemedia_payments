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
    end
  end
end
