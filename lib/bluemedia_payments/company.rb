module BluemediaPayments
  class Company
    include Base

    define_attributes :id, :name, :profile, :bank_account,
      :address, :postal_code, :city, :country,
      :nip, :regon, :edg, :krs, :kind,
      :service, :person, :beneficial_owner

    attr_accessor :logger, :logging_enabled, :soap_response, :response

    class SoapError < StandardError; end
    class Response < OpenStruct
      def initialize(hash=nil)
        register_response = hash.delete(:register_response)
        super(hash.merge(register_response))
      end
    end

    validates *(attributes.keys - %w( edg krs beneficial_owner )), presence: true
    validate do
      unless service.valid?(:company_create)
        service.errors.full_messages.map { |message| errors.add(:service, "service: #{message}") }
      end
    end

    LONG_INT_MAXIMUM = 2**32
    WSDL = 'http://paybmapi-accept.blue.pl/api/ws/service?wsdl'
    TRADE_VALUES = %w( DELICATESSEN HOME_AND_GARDEN CHILDREN CONSUMER_ELECTRONICS HOBBY COMPUTERS BOOKS_AND_MULTIMEDIA
      AUTOMOTIVE CLOTHES GIFTS_AND_ACCESSORIES SPORT_AND_TRAVEL HEALTH_AND_BEAUTY OTHER
    )
    KIND_VALUES = %w( PROPRIETORSHIP CIVIL_PARTNERSHIP GENERAL_PARTNERSHIP SP_ZOO SA
      LIMITED_PARTNERSHIP LIMITED_JOINT_STOCK_PARTNERSHIP SOCIETY FOUNDATION
    )

    def create
      return false unless valid?
      _service = {
        name: name,
        service_url: service.url,
        url_itn: service.notification_url,
        return_url: service.return_url,
        trade: profile || TRADE_VALUES.last,
        settlement_nrb: bank_account,
        commission_model: service.commission_model
      }
      _address = {
        address: address,
        postal_code: postal_code,
        city: city,
        country: country || 'POLAND'
      }
      company = {
        company_remote_id: id,
        name: name,
        address: _address,
        nip: nip,
        regon: regon,
        edg: edg,
        krs: krs,
        email: person.email,
        phone: person.phone,
        representing_person_first_name: person.first_name,
        representing_person_last_name: person.last_name,
        representing_person_pesel: person.pesel,
        service: _service,
        activity_kind: kind,
        is_beneficial_owner: beneficial_owner.present?.to_s.upcase
      }
      time = Time.now - service.time_offset # use time_offset when receiving HEADER_MESSAGE_TIME_OUTDATED
      header = {
        platform_id: service.platform_id,
        message_time: time.strftime("%Y-%m-%dT%H:%M:%S"),
        request_id: (time.to_f * 1000).to_i % LONG_INT_MAXIMUM,
      }
      header[:hash] = hash(header)
      key_converter = method(:savon_key_converter).to_proc

      _logger = logger || Logger.new('/dev/null')

      client = Savon.client(wsdl:BluemediaPayments::Company::WSDL, log_level: :debug, logger: _logger, log: logging_enabled, convert_request_keys_to: key_converter)
      self.soap_response = client.call(:register_company, message: { Header:header, Company: company })
      handle_response
    end

    SAVON_SPECIAL_KEYS = {
      url_itn: 'UrlITN',
      settlement_nrb: 'SettlementNRB',
      is_beneficial_owner: 'isBeneficialOwner'
    }
    def savon_key_converter(key)
      BluemediaPayments::Company::SAVON_SPECIAL_KEYS[key.to_sym] || Gyoku::XMLKey.create(key.to_sym, {key_converter: :camelcase})
    end

    def hash(header)
      Digest::SHA256.hexdigest(header.values.join('') + service.soap_shared_key.to_s)
    end

    def handle_response
      soap_result = self.soap_response.body[:register_company_resp]
      if soap_result[:result]  == 'ERROR'
        if soap_result[:error_status] == 'COMPANY_NIP_NOT_UNIQUE'
          errors.add(:nip, :taken)
        else
          raise SoapError.new(soap_result[:error_status])
        end
        false
      else
        self.response = Response.new(soap_result)
      end
    end

  end
end
