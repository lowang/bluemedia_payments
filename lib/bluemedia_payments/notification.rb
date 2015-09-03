module BluemediaPayments
  class Notification
    include Base

    attribute :merchant_id, type: Integer
    attribute :order_id, type: Integer
    attribute :transaction_id, type: Integer
    attribute :transaction_date, type: Date
    attribute :amount, type: BigDecimal
    attribute :currency
    attribute :payway_id, type: Integer
    attribute :status_date, type: DateTime
    attribute :status, type: Integer
    attribute :properties

    # include Base
    #
    # define_attributes :merchant_id, :order_id, :transaction_id, :transaction_date, :amount, :currency, :payway_id, :status_date, :status, :properties

    validates *attributes.keys, presence: true

    def self.from_itn(itn_xml)
      parser = Nori.new(convert_tags_to: lambda { |tag| tag.snakecase.to_sym })
      result = parser.parse(itn_xml)
      result[:transaction_list][:transactions].collect do |transaction|
        transaction = transaction.last
        new(merchant_id: result[:transaction_list][:merchant_id], order_id: transaction[:order_id],
          transaction_id: transaction[:trans_id], transaction_date: transaction[:trans_date],
          amount: transaction[:amount], currency: transaction[:currency], payway_id: transaction[:payway_id],
          status_date: transaction[:status_date], status: transaction[:status], properties: self.parse_param(transaction[:param])
        )
      end
    end

    # <param>CustomerAddress=Base64(<adres_klienta>)|CustomerNRB=<numer_konta>|VerificationStatus=<status_weryfikacji></param>
    def self.parse_param(param)
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
end
