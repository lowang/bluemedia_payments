module BluemediaPayments
  class Hash
    class IncorrectKeyOrder < StandardError; end
    include Base
    include Utils

    attr_writer :hash, :method
    attr_accessor :params, :separator

    def self.from_params(params)
      new(params:params)
    end

    def hash
      @hash || begin
        logger && logger.debug("COMPUTED HASH KEY: #{hash_signature_values.inspect}")
        hash_signature = hash_signature_by_method(hash_signature_values)
        logger && logger.debug("COMPUTED HASH: #{hash_signature}")
        hash_signature
      end
    end

    private

    def keys_order
      params.try(:keys)
    end

    def hash_signature_values
      hash_signature_values = keys_order.map do |attribute|
        cast_value(params[attribute])
      end.compact
      hash_signature_values.join(separator.to_s)
    end

    # different Bluemedia models are using different hash methods
    # allow to change by calling: hash_object.method = :md5
    def hash_signature_by_method(values)
      case @method
        when :md5 then Digest::MD5.hexdigest(values)
        else Digest::SHA256.hexdigest(values)
      end
    end

  end
end
