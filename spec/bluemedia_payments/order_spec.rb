require 'spec_helper'

describe BluemediaPayments::Order do
  let(:service_params) do { service_id: 354, service_key: '12'*16, gateway_url: 'http://pay-accept.bm.pl/merchant' } end
  let(:service) { BluemediaPayments::Service.new(service_params) }
  let(:valid_attributes) do { order_id: 1, amount: 10.2, title: 'zakup',
    description: 'zakup punktów reklamowych',
    customer_email: 'przemyslaw.wroblewski+test1@nokaut.pl',
    customer_ip: '81.210.106.10', gateway_id: 106, service: service  }
  end
  before do
    allow(Time).to receive(:now).and_return(Time.parse '2015-10-15 18:45:54') # stub request time
  end

  describe 'incomplete order' do
    subject { BluemediaPayments::Order.new(order_id: 1, amount: 10.2, service: service) }
    it 'serializes an order' do
      expect(subject.serializable_hash).to eq({"OrderID"=>1, "Amount"=>"10.20", "Description"=>nil, "Currency"=>"PLN",
        "CustomerEmail"=>nil, "CustomerIP"=>nil, "Title"=>nil, "ServiceID"=>"354", "GatewayID"=>nil,
        "Hash" => "b0959ef0dd5d9a91ff6e8b8d93bd28af030d2682f01b000c6a6dd834cdd92f5f",
        "LinkValidityTime" => "2015-10-15 19:45:54", "ValidityTime" => "2015-10-15 18:45:54"
      })
    end
    it 'is not valid' do
      expect(subject.valid?).to be_falsy
    end
  end

  describe '#serializable_hash' do
    subject { BluemediaPayments::Order.new(valid_attributes).serializable_hash }
    it "uses valid BlueMedia params" do
      expect(subject.keys).to eq(%w( OrderID GatewayID Description CustomerEmail CustomerIP Title Amount Currency ServiceID ValidityTime LinkValidityTime Hash ))
    end
  end

  describe '#hash_signature' do
    subject { BluemediaPayments::Order.new(valid_attributes) }
    it 'preserves order on attributes' do
      expect(BluemediaPayments::Order::HASH_SIGNATURE_KEYS_ORDER).to eq(%i( service_id order_id serialized_amount description gateway_id currency customer_email customer_ip title validity_time link_validity_time))
    end
    it 'calculates hash' do
      expect(subject.hash_signature).to eq('d8ef58c0d243ed84801cc527877bf10fd3e02f80df2869f91b8a5a4f196d6478')
    end
  end

  describe '#create' do
    describe 'success' do
      let(:response_success) { <<EOS }
<!-- PAYWAY FORM BEGIN -->
<form action="https://pg-accept.blue.pl/gateway/test/index.jsp" name="formGoPBL" method="POST"><input type="hidden" name="transaction" value="123254"><input type="hidden" name="merchantId" value="6009"><input type="hidden" name="shopName" value="Firma testowa"><input type="hidden" name="orderId" value="96MAVAC4"><input type="hidden" name="email" value="przemyslaw.wroblewski+test1@nokaut.pl"><input type="hidden" name="amount" value="10.20"><input type="hidden" name="currency" value="PLN"><input type="hidden" name="firstName" value="Jan"><input type="hidden" name="lastName" value="Kowalski"><input type="hidden" name="street" value="Jasna"><input type="hidden" name="streetHouseNo" value="6"><input type="hidden" name="streetStaircaseNo" value="A"><input type="hidden" name="streetPremiseNo" value="3"><input type="hidden" name="city" value="Warszawa"><input type="hidden" name="postalCode" value="10-234"><input type="hidden" name="title" value="BPID:96MAVAC4 zakup punktów reklamowych"><input type="hidden" name="senderNRB" value="26105014451000002276470461"><input type="hidden" name="receiverNRB" value="34567890123456789012345689"><input type="hidden" name="date" value="2015-10-15 19:16"><input type="hidden" name="accountingDate" value="2015-10-15"></form><script type="text/javascript">document.forms[0].submit();</script>
<!-- PAYWAY FORM END -->
EOS
      before do
        allow(response_success).to receive(:body).and_return(response_success)
        allow(response_success).to receive(:code).and_return(200)
      end
      let(:order) { BluemediaPayments::Order.new(valid_attributes) }
      subject { order.create }
      it 'creates an order' do
        expect(RestClient).to receive(:post).with("http://pay-accept.bm.pl/merchant", order.serializable_hash, {"BmHeader"=>"pay-bm"}).and_return(response_success)
        expect(subject).to be_kind_of String
        expect(subject).to start_with('<!-- PAYWAY FORM BEGIN -->')
        expect(subject).to end_with("<!-- PAYWAY FORM END -->\n")
      end
    end

    describe 'errors' do
      let(:response_status) { "406 NotAcceptable" }
      let(:response_error) do
        exception = RestClient::NotAcceptable.new
        exception.response = response_error_xml
        exception
      end
      let(:order) { BluemediaPayments::Order.new(valid_attributes) }
      before do
        expect(RestClient).to receive(:post).with("http://pay-accept.bm.pl/merchant", order.serializable_hash, {"BmHeader"=>"pay-bm"}).and_raise(response_error)
      end
      subject { order.create }

      describe 'invalid_hash error' do
        let(:response_error_xml) { <<EOS }
<?xml version="1.0" encoding="UTF-8"?>
<error>
    <statusCode>7</statusCode>
    <name>INVALID_HASH</name>
    <description>invalid hash : 68f51b0bcc1856413e93dc259156643f36c6cdaa05067855a5a6c0d8a61d10db</description>
</error>
EOS
        it 'handles an error' do
          expect{subject}.to raise_error(BluemediaPayments::Order::Exception) do |ex|
            expect(ex.response).to eq(response_error_xml)
            expect(ex.restclient_exception).to eq(response_error)
            expect(ex.status_code).to eq(7)
            expect(ex.name).to eq('INVALID_HASH')
            expect(ex.message).to eq('invalid hash : 68f51b0bcc1856413e93dc259156643f36c6cdaa05067855a5a6c0d8a61d10db')
          end
        end
      end
      describe 'invalid_format error' do
        let(:response_error_xml) { <<EOS }
<?xml version="1.0" encoding="UTF-8"?>
<error>
    <statusCode>2</statusCode>
    <name>INVALID_FORMAT</name>
    <description>invalid format for serviceId </description>
</error>
EOS
        it 'handles an error' do
          expect{subject}.to raise_error(BluemediaPayments::Order::Exception) do |ex|
            expect(ex.response).to eq(response_error_xml)
            expect(ex.status_code).to eq(2)
            expect(ex.name).to eq('INVALID_FORMAT')
            expect(ex.message).to eq('invalid format for serviceId ')
          end
        end
      end
    end
  end
end
