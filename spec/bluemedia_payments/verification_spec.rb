require 'spec_helper'

describe BluemediaPayments::Verification do
  let(:itn_xml) {
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <transactionList>
      <merchantID>1</merchantID>
      <transactions>
        <transaction>
          <orderID>11_4234</orderID>
          <transID>9F1LQWXK</transID>
          <transDate>20010101</transDate>
          <amount>11.11</amount>
          <currency>PLN</currency>
          <paywayID>1</paywayID>
          <statusDate>20010101111111</statusDate>
          <status>1</status>
          <param>CustomerAddress=SmFuIEtvbHdhc2tp|CustomerNRB=92874710181271009158695384|VerificationStatus=POSITIVE</param>
        </transaction>
      </transactions>
      <docHash>355ec265ee8e3321b7aa32c6e63ad1f4</docHash>
    </transactionList>
    EOS
  }

  let(:service_params) do
    { verification_shared_key: 'ver', merchant_id: 1 }
  end
  let(:service) { BluemediaPayments::Service.new(service_params) }
  let(:verification_itn) { BluemediaPayments::Verification.from_itn(itn_xml, service) }

  describe 'parse itn' do
    subject { verification_itn }

    it { is_expected.to be_kind_of(BluemediaPayments::Verification) }

    it { expect(subject.order_id).to eq('11_4234') }
    it { expect(subject.transaction_id).to eq('9F1LQWXK') }
    it { expect(subject.transaction_date).to eq(Date.parse "2001-01-01") }
    it { expect(subject.amount).to eq(BigDecimal.new('11.11')) }
    it { expect(subject.currency).to eq('PLN') }
    it { expect(subject.payway_id).to eq(1) }
    it { expect(subject.status_date).to eq(DateTime.parse '2001-01-01 11:11:11') }
    it { expect(subject.status).to eq(1) }
    it { expect(subject.properties).to be_kind_of(Hash) }
    it { expect(subject.properties[:customer_address]).to eq('Jan Kolwaski') }
    it { expect(subject.properties[:customer_nrb]).to eq('92874710181271009158695384') }
    it { expect(subject.properties[:verification_status]).to eq('POSITIVE') }
    it { expect(subject.hash_signature).to eq('355ec265ee8e3321b7aa32c6e63ad1f4') }
    it { expect(subject.service_id).to eq('11') }
    it { expect(subject.hash_signature_verified?).to be_truthy }
    it { expect(subject.valid?).to be_truthy, subject.errors.full_messages.join("\n") }
  end

  describe 'respond to itn' do
    let(:expected_confirmation_status) { 'CONFIRMED'}
    let(:expected_hash) { '2e898b19152af74f2b7f52b1f4a3b6ea'}
    let(:xml_confirmation) { <<-EOS }
<?xml version="1.0" encoding="UTF-8"?>
<confirmationList>
  <merchantID>1</merchantID>
  <transactionsConfirmations>
    <transactionConfirmed>
      <orderID>11_4234</orderID>
      <confirmation>#{expected_confirmation_status}</confirmation>
    </transactionConfirmed>
  </transactionsConfirmations>
  <docHash>#{expected_hash}</docHash>
</confirmationList>
EOS
    subject { verification_itn.xml_response }

    describe 'and confirm' do
      before { verification_itn.confirmation_status = true}
      it { is_expected.to eq(xml_confirmation) }
    end

    describe 'without confirmation' do
      let(:expected_confirmation_status) { 'NOTCONFIRMED'}
      let(:expected_hash) { 'f91e0c0f0ce56271ec4905af6dc968dd'}
      describe 'by declining confirmation' do
        it { is_expected.to eq(xml_confirmation) }
        it { expect(verification_itn.valid?).to be_truthy }
      end
      describe 'by verification hash mismatch' do
        before do
          verification_itn.confirmation_status = true
          verification_itn.hash_signature = '1'*32
        end
        it { is_expected.to eq(xml_confirmation) }
        it { expect(verification_itn.valid?).to be_falsey }
      end
    end
  end

  describe 'validation' do
    let(:service) { BluemediaPayments::Service.new }
    it "wont be valid with invalid service" do
      expect(service.valid?(:verification)).to be_falsey
      expect(verification_itn.valid?).to be_falsey
      expect(verification_itn.errors.keys).to eq([:hash_signature, :service])
    end
  end
end
