module BluemediaPayments
  class Company
    include Base

    define_attributes :id, :name, :profile, :bank_account,
      :address, :postal_code, :city, :country,
      :nip, :regon, :edg, :krs, :kind,
      :service, :person, :beneficial_owner

    LONG_INT_MAXIMUM = 2**32
    WSDL = 'http://paybmapi-accept.blue.pl/api/ws/service?wsdl'
    TRADE_VALUES = %w( DELICATESSEN HOME_AND_GARDEN CHILDREN CONSUMER_ELECTRONICS HOBBY COMPUTERS BOOKS_AND_MULTIMEDIA
      AUTOMOTIVE CLOTHES GIFTS_AND_ACCESSORIES SPORT_AND_TRAVEL HEALTH_AND_BEAUTY OTHER
    )
    KIND_VALUES = %w( PROPRIETORSHIP CIVIL_PARTNERSHIP GENERAL_PARTNERSHIP SP_ZOO SA
      LIMITED_PARTNERSHIP LIMITED_JOINT_STOCK_PARTNERSHIP SOCIETY FOUNDATION
    )

    def create
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
      time = Time.now
      header = {
        platform_id: ENV['PLATFORM_ID'],
        message_time: time,
        request_id: (time.to_f * 1000).to_i % LONG_INT_MAXIMUM,
        hash: URI.escape(hash(company))
      }
      client = Savon.client(wsdl:BluemediaPayments::Company::WSDL, log_level: :debug, logger: Logger.new($stdout), log:true)
      response = client.call(:register_company, message: { header:header, company: company })
      binding.pry
    end

    # funkcja(wartości_pola_1_komunikatu + "|” + wartości_pola_2_komunikatu + "|” + ... + "|” + wartości_pola_n_komunikatu + "|” + klucz_współdzielony);
    def hash(company)
      Digest::SHA256.digest(company.keys.join('|') + "|" + ENV['SHARED_KEY'])
    end
  end
end
