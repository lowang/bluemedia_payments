# kind of ITN used exclusively for service verification callback
module BluemediaPayments
  class Verification
    include Base
    include Itn
    SERVICE_VALIDATION_SCOPE = :verification

    attribute :merchant_id, type: Integer
    attribute :order_id, type: String
    attribute :transaction_id, type: String
    attribute :transaction_date, type: Date
    attribute :amount, type: BigDecimal
    attribute :currency
    attribute :payway_id, type: Integer
    attribute :status_date, type: DateTime
    attribute :status, type: Integer
    attribute :properties
    attribute :hash_signature

    attr_accessor :service, :raw_properties
    attr_writer :confirmation_status

    validates *attributes.keys, presence: true

    HASH_SIGNATURE_KEYS_ORDER = %w( merchant_id order_id transaction_id transaction_date amount currency payway_id status_date status raw_properties verification_shared_key )
    
    class << self
      # BlueMedia: despite array form, ITN describe single transaction
      def from_itn(itn_xml, service)
        result = self.xml_parser.parse(itn_xml)
        transaction = result[:transaction_list][:transactions][:transaction]
        new(merchant_id: result[:transaction_list][:merchant_id], order_id: transaction[:order_id],
          transaction_id: transaction[:trans_id], transaction_date: transaction[:trans_date],
          amount: transaction[:amount], currency: transaction[:currency], payway_id: transaction[:payway_id],
          status_date: transaction[:status_date], status: transaction[:status],
          properties: self.parse_param(transaction[:param]),
          raw_properties: transaction[:param],
          hash_signature: result[:transaction_list][:doc_hash], service: service
        )
      end

      # <param>CustomerAddress=Base64(<adres_klienta>)|CustomerNRB=<numer_konta>|VerificationStatus=<status_weryfikacji></param>
      def parse_param(param)
        properties = {}
        param.split("|").each do |element|
          result = CGI.parse element
          key = result.keys.first
          properties[key.snakecase.to_sym] = if result['CustomerAddress'].present?
            Base64.decode64(result['CustomerAddress'].last)
          else
            result[key].first
          end
        end
        properties
      end
    end

    def hash_signature_verified?
      hash = BluemediaPayments::Hash.new(logger: logger, service: service, method: :md5, keys_order: HASH_SIGNATURE_KEYS_ORDER,
              params: attributes.merge({status_date: status_date.strftime('%Y%m%d%H%M%S'),
                transaction_date: transaction_date.strftime('%Y%m%d'), amount: '%.2f' % amount,
                raw_properties: raw_properties, verification_shared_key: service.verification_shared_key}.stringify_keys))
      hash_signature == hash.hash
    end

    def xml_response
      confirmation_hash_signature = [service.merchant_id, order_id, confirmation_status, service.verification_shared_key].join('')
      logger.debug "COMPUTED CONFIRMATION HASH KEYS: #{confirmation_hash_signature}" if logger?
      confirmation_hash_signature = Digest::MD5.hexdigest(confirmation_hash_signature)
      logger.debug "COMPUTED CONFIRMATION HASH: #{confirmation_hash_signature}" if logger?
      xml =<<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<confirmationList>
  <merchantID>#{service.merchant_id}</merchantID>
  <transactionsConfirmations>
    <transactionConfirmed>
      <orderID>#{order_id}</orderID>
      <confirmation>#{confirmation_status}</confirmation>
    </transactionConfirmed>
  </transactionsConfirmations>
  <docHash>#{confirmation_hash_signature}</docHash>
</confirmationList>
      EOS
    end

    def service_id
      order_id_parts = order_id.split('_')
      order_id_parts[0]
    end
  end
end
