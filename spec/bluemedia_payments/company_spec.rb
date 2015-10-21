require 'spec_helper'

RSpec::Matchers.define :a_httpi_matching_body do |expected_body|
  match { |actual| actual.body == expected_body }
end

describe BluemediaPayments::Company do

  let(:service_params) {{
    url: 'http://localhost',
    notification_url: 'http://localhost/itn',
    return_url: 'http://localhost/payment_complete',
    commission_model: 1,
    platform_id: 1,
    soap_shared_key: '1k1'
  }}
  let(:person_params) {{
    email: 'jan.kowalski@example.pl',
    phone: '555100200',
    first_name:'Jan',
    last_name: 'Kowalski',
    pesel: '80121503875',
  }}
  let(:service) { BluemediaPayments::Service.new(service_params) }
  let(:valid_params) {{ id:1, name: 'Firma testowa', profile: 'OTHER', bank_account: '92 8747 1018 1271 0091 5869 5384'.gsub(/ /, ''),
    address: 'Sportowa 8B', postal_code: '81-300', city: 'Gdynia', country: 'Polska',
    nip: '5231104127', regon: '951889253', krs: '0000440039', kind: 'SP_ZOO',
    service: service, person: BluemediaPayments::Person.new(person_params), beneficial_owner: false
  }}
  let(:company) { BluemediaPayments::Company.new(valid_params) }

  describe 'validation' do
    let(:service_params) do {} end
    it "wont be valid with invalid service" do
      expect(service.valid?(:company_create)).to be_falsey
      expect(company.valid?).to be_falsey
      expect(company.errors.keys).to eq([:service])
    end
  end

  describe 'xml' do
    let(:soap_xml_request) {
      '<?xml version="1.0" encoding="UTF-8"?><env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="http://integrator/ws/" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">'+
        '<env:Body><tns:RegisterCompanyReq><Header><PlatformId>1</PlatformId><MessageTime>2015-09-11T12:48:32</MessageTime><RequestId>3154467840</RequestId>'+
        '<Hash>d3092611d53a6fbf0eaf34dc920e86ae1379656666469cf61749feeb76fcdbcd</Hash></Header><Company><CompanyRemoteId>1</CompanyRemoteId>'+
        '<Name>Firma testowa</Name><Address><Address>Sportowa 8B</Address><PostalCode>81-300</PostalCode><City>Gdynia</City><Country>Polska</Country></Address>'+
        '<Nip>5231104127</Nip><Regon>951889253</Regon><Edg xsi:nil="true"/><Krs>0000440039</Krs><Email>jan.kowalski@example.pl</Email><Phone>555100200</Phone>'+
        '<RepresentingPersonFirstName>Jan</RepresentingPersonFirstName><RepresentingPersonLastName>Kowalski</RepresentingPersonLastName>'+
        '<RepresentingPersonPesel>80121503875</RepresentingPersonPesel><Service><Name>Firma testowa</Name><ServiceUrl>http://localhost</ServiceUrl>'+
        '<UrlITN>http://localhost/itn</UrlITN><ReturnUrl>http://localhost/payment_complete</ReturnUrl><Trade>OTHER</Trade>'+
        '<SettlementNRB>92874710181271009158695384</SettlementNRB><CommissionModel>1</CommissionModel></Service><ActivityKind>SP_ZOO</ActivityKind>'+
        '<isBeneficialOwner>FALSE</isBeneficialOwner></Company></tns:RegisterCompanyReq></env:Body></env:Envelope>'
    }
    before do
      allow(Time).to receive(:now).and_return(Time.parse '2015-09-11T12:48:32') # stub request time
      allow(HTTPI).to receive(:post)
    end
    describe 'create' do
      let(:soap_xml_response) {
        '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:RegisterCompanyResp xmlns:ns2="http://integrator/ws/"><RegisterResponse><AcceptorID>123</AcceptorID><ServiceID>345</ServiceID><ServiceKey>ec5d1548956b3763d2f566d729482cb84e97e2dca22f3ec0502fa72b9b079981</ServiceKey><Hash>47c62fe1ac18043fccf76f8ba1b77615c9d8aa9c57b0a788b54dbd42209950d3</Hash><ActivationLink>https://paymentblueplprezentacje.blue.pl/partner?MerchantID=123&amp;OrderID=567_4c32796014fad013f907fd1&amp;Date=20150910&amp;Amount=1.00&amp;Description= Weryfikacja integrator&amp;Currency=PLN&amp;GatewayID=0&amp;CustomerEmail=jan.kowalski@example.pl&amp;Charset=utf-8&amp;Hash=c7ac45f51b952f7991dda59dec83cdd7&amp;Send=Wyslij</ActivationLink></RegisterResponse><Result>OK</Result><ErrorStatus xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true"/></ns2:RegisterCompanyResp></soap:Body></soap:Envelope>'
      }
      it 'creates an order' do
        expect(HTTPI).to receive(:post).with(a_httpi_matching_body(soap_xml_request), any_args).and_return(HTTPI::Response.new(200, {}, soap_xml_response))
        expect(company.create).not_to(be_falsey, company.errors.full_messages.to_s)
        expect(company.response.acceptor_id).to eq("123")
        expect(company.response.service_id).to eq("345")
        expect(company.response.service_key).to eq("ec5d1548956b3763d2f566d729482cb84e97e2dca22f3ec0502fa72b9b079981")
        expect(company.response.activation_link).to match(/https:\/\/paymentblueplprezentacje.blue.pl\/.*/)
      end
    end

    describe 'errors' do
      before do
        allow(HTTPI).to receive(:post).with(a_httpi_matching_body(soap_xml_request), any_args).and_return(HTTPI::Response.new(200, {}, soap_xml_response))
      end
      describe 'soap error1' do
        let(:soap_xml_response) {
          '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:RegisterCompanyResp xmlns:ns2="http://integrator/ws/"><Result>ERROR</Result><ErrorStatus>HEADER_MESSAGE_TIME_OUTDATED</ErrorStatus></ns2:RegisterCompanyResp></soap:Body></soap:Envelope>'
        }
        it 'raises an exception' do
          expect{company.create}.to raise_error(BluemediaPayments::Company::SoapError) do |err|
            expect(err.message).to eq('HEADER_MESSAGE_TIME_OUTDATED')
          end
        end
      end
      describe 'soap error2' do
        let(:soap_xml_response) {
          '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:RegisterCompanyResp xmlns:ns2="http://integrator/ws/"><Result>ERROR</Result><ErrorStatus>COMPANY_NIP_NOT_UNIQUE</ErrorStatus></ns2:RegisterCompanyResp></soap:Body></soap:Envelope>'
        }
        it 'raises an exception' do
          expect(company.create).to be_falsey
          expect(company.errors[:nip]).to be_present
        end
      end

    end
  end

end
