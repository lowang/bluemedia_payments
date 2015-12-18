require 'spec_helper'

describe BluemediaPayments::Notification do
  let(:itn_xml) {
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <transactionList>
        <serviceID>4</serviceID>
        <transactions>
            <transaction>
                <orderID>1</orderID>
                <remoteID>96MAETW8</remoteID>
                <amount>1.20</amount>
                <currency>PLN</currency>
                <gatewayID>106</gatewayID>
                <paymentDate>20151009103646</paymentDate>
                <paymentStatus>SUCCESS</paymentStatus>
                <paymentStatusDetails>AUTHORIZED</paymentStatusDetails>
            </transaction>
        </transactions>
        <hash>964d3ee2aa2515f8d3ebe550f9779869c01c6d5264429268a55432ca3a7f49ac</hash>
    </transactionList>
    EOS
  }
  let(:service_params) do
    { service_key: 'ser', service_id: 4 }
  end
  let(:service) { BluemediaPayments::Service.new(service_params) }
  let(:itn) { BluemediaPayments::Notification.from_itn(itn_xml, service) }

  describe 'parse itn' do
    describe 'parse itn' do
      subject { itn }
      #before { BluemediaPayments::Notification.logger = Logger.new(STDOUT)}
      it { is_expected.to be_kind_of(BluemediaPayments::Notification) }

      it { expect(subject.order_id).to eq(1) }
      it { expect(subject.remote_id).to eq('96MAETW8') }
      it { expect(subject.amount).to eq(BigDecimal.new('1.2')) }
      it { expect(subject.currency).to eq('PLN') }
      it { expect(subject.gateway_id).to eq(106) }
      it { expect(subject.payment_date).to eq(DateTime.parse '2015-10-09 10:36:46') }
      it { expect(subject.payment_status).to eq('SUCCESS') }
      it { expect(subject.payment_status_details).to eq('AUTHORIZED') }
      it { expect(subject.hash_signature).to eq('964d3ee2aa2515f8d3ebe550f9779869c01c6d5264429268a55432ca3a7f49ac') }
      it { expect(subject.hash_signature_verified?).to be_truthy }
      it { expect(subject.valid?).to be_truthy, subject.errors.full_messages.join("\n") }
    end
  end

  describe 'respond to itn' do
    let(:expected_confirmation_status) { 'CONFIRMED'}
    let(:expected_hash) { 'a61a1cb1d6daa6a62efd9ae627f2fea7'}
    let(:xml_confirmation) { <<-EOS }
<?xml version="1.0" encoding="UTF-8"?>
<confirmationList>
  <serviceID>4</serviceID>
  <transactionsConfirmations>
    <transactionConfirmed>
      <orderID>1</orderID>
      <confirmation>#{expected_confirmation_status}</confirmation>
    </transactionConfirmed>
  </transactionsConfirmations>
  <hash>#{expected_hash}</hash>
</confirmationList>
EOS
    subject { itn.xml_response }

    describe 'and confirm' do
      before { itn.confirmation_status = true}
      it { is_expected.to eq(xml_confirmation) }
    end

    describe 'without confirmation' do
      let(:expected_confirmation_status) { 'NOTCONFIRMED'}
      let(:expected_hash) { '4e684390ee195dc1c29913f63c5f725a'}
      describe 'by declining confirmation' do
        it { is_expected.to eq(xml_confirmation) }
        it { expect(itn.valid?).to be_truthy }
      end
      describe 'by verification hash mismatch' do
        before do
          itn.confirmation_status = true
          itn.hash_signature = '1'*32
        end
        it { is_expected.to eq(xml_confirmation) }
        it { expect(itn.valid?).to be_falsey }
      end
    end
  end
end
