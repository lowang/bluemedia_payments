module BluemediaPayments
  class Order
    include Base

    GATEWAY_URL = 'https://pay-accept.bm.pl/bm'

    define_attributes :order_id, :description, :customer_email, :customer_ip, :title, :merchant_id, :service_id, :gateway_id
    attribute :amount, type: BigDecimal
    attribute :currency, default: 'PLN'

    validates :amount, numericality: true
    validates *attributes.keys, presence: true

    def create
      return unless valid?
      @response = RestClient.post GATEWAY_URL, serializable_hash
    end

    def serializable_hash
      hash = {}
      self.class.attributes.keys.each do |key|
        value = send(key)
        value = "%.02f" % value if key == 'amount' && value
        hash[key.to_s.camelize] = value
      end
      hash
    end
  end
end
