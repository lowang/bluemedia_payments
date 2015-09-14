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
      verify_hash_signture = [ service.service_id, order_id, remote_id,
        amount, currency, gateway_id, payment_date.strftime('%Y%m%d%H%M%S'), payment_status, payment_status_details ]
      verify_hash_signture = (verify_hash_signture << service.service_key.to_s).join("|")
      logger.debug "COMPUTED HASH KEYS: #{verify_hash_signture}" if logger?
      verify_hash_signture = Digest::SHA256.hexdigest(verify_hash_signture)
      logger.debug "COMPUTED HASH: #{verify_hash_signture}" if logger?
      logger.debug "SUPPLIED HASH: #{hash_signature}, CHECK?: #{hash_signature == verify_hash_signture}" if logger?
      hash_signature == verify_hash_signture
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
