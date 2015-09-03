require 'spec_helper'

describe BluemediaPayments::Notification do

  describe 'parse itn' do
    let(:itn_xml) {
      <<-EOS
      <?xml version="1.0" encoding="UTF-8"?> <transactionList>
        <merchantID>1</merchantID>
        <transactions>
          <transaction>
            <orderID>11</orderID>
            <transID>91</transID>
            <transDate>20010101</transDate>
            <amount>11.11</amount>
            <currency>PLN</currency>
            <paywayID>1</paywayID>
            <statusDate>20010101111111</statusDate>
            <status>1</status>
            <param>CustomerAddress=SmFuIEtvbHdhc2tp|CustomerNRB=11114020040000370228260610|VerificationStatus=POSITIVE</param>
          </transaction>
        </transactions>
        <docHash>d64034a0b2f2863d1fe550592786307d</docHash>
      </transactionList>
      EOS
    }
    let(:itn) { BluemediaPayments::Notification.from_itn(itn_xml) }
    subject { itn.first }

    it { is_expected.to be_kind_of(BluemediaPayments::Notification) }

    it { expect(subject.order_id).to eq(11) }
    it { expect(subject.transaction_id).to eq(91) }
    it { expect(subject.transaction_date).to eq(Date.parse "2001-01-01") }
    it { expect(subject.amount).to eq(BigDecimal.new('11.11')) }
    it { expect(subject.currency).to eq('PLN') }
    it { expect(subject.payway_id).to eq(1) }
    it { expect(subject.status_date).to eq(DateTime.parse '2001-01-01 11:11:11') }
    it { expect(subject.status).to eq(1) }
    it { expect(subject.properties).to be_kind_of(Hash) }
    it { expect(subject.properties[:customer_address]).to eq('Jan Kolwaski') }
    it { expect(subject.properties[:customer_nrb]).to eq('11114020040000370228260610') }
    it { expect(subject.properties[:verification_status]).to eq('POSITIVE') }
  end
end
