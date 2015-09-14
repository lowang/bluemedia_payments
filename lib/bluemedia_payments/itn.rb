module BluemediaPayments
  module Itn
    def self.included(klass)
      klass.class_eval do
        validate :must_have_valid_hash_signature
        validate :must_have_valid_service
      end
    end

    def must_have_valid_hash_signature
      errors.add(:hash_signature, :invalid) unless hash_signature_verified?
    end

    def must_have_valid_service
      unless service.valid?(self.class::SERVICE_VALIDATION_SCOPE)
        service.errors.full_messages.map { |message| errors.add(:service, "service: #{message}") }
      end
    end

    def confirmation_status
      (@confirmation_status && valid?) ? 'CONFIRMED' : 'NOTCONFIRMED'
    end
  end
end
