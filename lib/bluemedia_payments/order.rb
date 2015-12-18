module BluemediaPayments
  class Order
    include Base

    class Exception < StandardError
      attr_accessor :response, :restclient_exception, :status_code, :name, :description
    end

    HASH_SIGNATURE_KEYS_BACKGROUND_ORDER = [ :service_id, :order_id, :amount, :description, :gateway_id, :currency, :customer_email, :customer_ip, :title, :validity_time, :link_validity_time ].freeze
    HASH_SIGNATURE_KEYS_FRONTEND_ORDER = [ :service_id, :order_id, :amount, :description, :gateway_id, :currency, :customer_email ].freeze
    SPECIAL_KEYS = {
      service_id: 'ServiceID',
      order_id: 'OrderID',
      gateway_id: 'GatewayID',
      customer_ip: 'CustomerIP',
    }

    define_attributes :order_id, :gateway_id, :description, :customer_email, :customer_ip, :title
    attribute :amount, type: BigDecimal
    attribute :currency, default: 'PLN'
    delegate :service_id, to: :service

    validates :amount, numericality: true
    validates *attributes.keys, presence: true
    validate do
      unless service.valid?(:order)
        service.errors.full_messages.map { |message| errors.add(:service, message) }
      end
    end

    attr_accessor :service, :redirect_to_payment_form, :transaction_id

    def create
      return unless valid?
      self.redirect_to_payment_form = "".tap do |redirect_to_payment_form|
        redirect_to_payment_form << CGI.unescapeHTML(RestClient.post service.gateway_url, serializable_hash(HASH_SIGNATURE_KEYS_BACKGROUND_ORDER), 'BmHeader' => 'pay-bm')
        parse_response(redirect_to_payment_form)
      end
    rescue RestClient::NotAcceptable => exception
      parse_error(exception)
    end

    def payment_form_url
      self.gateway_id = 0 # display all payment gateways
      return unless valid?
      self.customer_ip = nil
      self.title = nil
      payment_options = serializable_hash(HASH_SIGNATURE_KEYS_FRONTEND_ORDER)
      payment_options.delete('CustomerIP')
      payment_options.delete('Title')
      url = URI.parse(service.gateway_url)
      url.query = payment_options.to_param
      url.to_s
    end

    def parse_error(restclient_exception)
      parsed_xml = self.class.xml_parser.parse(restclient_exception.response)
      exception = Exception.new(parsed_xml[:error][:description])
      exception.restclient_exception = restclient_exception
      exception.response = restclient_exception.response
      exception.status_code = parsed_xml[:error][:status_code].to_i
      exception.name = parsed_xml[:error][:name]
      raise exception
    end

    def parse_response(response_body)
      match_data = response_body.match(/<input type="hidden" name="transaction" value="(\w+)">/)
      if match_data[1]
        self.transaction_id = match_data[1]
      end
    end

    def order_time
      @order_time ||= Time.now
    end

    def validity_time
      order_time.to_s(:db)
    end

    def link_validity_time
      (order_time. + 1.hour).to_s(:db)
    end

    def serializable_hash(hash_params)
      params = {}
      hash_params.each do |attribute|
        serialized_key = SPECIAL_KEYS[attribute.to_sym] || attribute.to_s.camelize
        params[serialized_key] = BluemediaPayments::Utils.cast_value(send(attribute))
      end
      params['service_key'] = service.service_key
      params['Hash'] = BluemediaPayments::Hash.new(logger: logger, separator: '|', params: params).hash
      params.delete('service_key')
      params
    end
  end
end
