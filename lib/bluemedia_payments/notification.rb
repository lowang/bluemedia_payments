# regular ITN used for payment verification callback
module BluemediaPayments
  class Notification
    include Base
    include Itn
    SERVICE_VALIDATION_SCOPE = :notification

    attribute :service_id, type: Integer
    attribute :order_id, type: Integer
    attribute :remote_id
    attribute :amount, type: BigDecimal
    attribute :currency
    attribute :gateway_id, type: Integer
    attribute :payment_date, type: DateTime
    attribute :payment_status
    attribute :payment_status_details
    attribute :hash_signature

    attr_accessor :service
    attr_writer :confirmation_status

    validates *attributes.keys, presence: true

    HASH_SIGNATURE_KEYS_ORDER = %w( service_id order_id remote_id amount currency gateway_id payment_date payment_status payment_status_details )

    class << self
      # BlueMedia: despite array form ITN describe single transaction
      def from_itn(itn_xml, service)
        result = self.xml_parser.parse(itn_xml)
        transaction = result[:transaction_list][:transactions][:transaction]
        new(service_id: result[:transaction_list][:service_id], order_id: transaction[:order_id],
          remote_id: transaction[:remote_id], amount: transaction[:amount], currency: transaction[:currency],
          gateway_id: transaction[:gateway_id], payment_date: transaction[:payment_date],
          payment_status: transaction[:payment_status], payment_status_details: transaction[:payment_status_details],
          hash_signature: result[:transaction_list][:hash], service: service
        )
      end
    end

    def hash_signature_verified?
      hash = BluemediaPayments::Hash.new(logger: logger, service: service, separator: '|', keys_order: HASH_SIGNATURE_KEYS_ORDER,
        params: attributes.merge('payment_date' => payment_date.strftime('%Y%m%d%H%M%S')))
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
  <serviceID>#{service.service_id}</serviceID>
  <transactionsConfirmations>
    <transactionConfirmed>
      <orderID>#{order_id}</orderID>
      <confirmation>#{confirmation_status}</confirmation>
    </transactionConfirmed>
  </transactionsConfirmations>
  <hash>#{confirmation_hash_signature}</hash>
</confirmationList>
      EOS
    end

  end
end
