require 'spec_helper'

describe BluemediaPayments::Hash do
  describe 'notification itn' do
    let(:itn_params) do {
      serviceID: 4,
      orderID: 1,
      remoteID: '96MAETW8',
      amount: '1.2',
      currency: 'PLN',
      gatewayID: 106,
      paymentDate: '20151009103646',
      paymentStatus: 'SUCCESS',
      paymentStatusDetails: 'AUTHORIZED' }
    end
    let(:separator) { '|' }
    let(:hash_model) do
      BluemediaPayments::Hash.from_params(itn_params.merge(service_key: 'ser')).tap do |hash|
        hash.separator = separator
        hash.logger = Logger.new(STDOUT)
      end
    end
    subject { hash_model.hash }
    it { is_expected.to eq('c4b851da23e64cc058bb2c0fa4e3fa6119a6fa2cb12f946ec5c3e16e5fdd7298') }
  end
  describe 'verification itn' do
    let(:itn_params) do {
      merchantID: 1,
      orderID: '11_4234',
      transID: '9F1LQWXK',
      transDate: '20010101',
      amount: '11.11',
      currency: 'PLN',
      paywayID: 1,
      statusDate: '20010101111111',
      status: 1,
      param: 'CustomerAddress=SmFuIEtvbHdhc2tp|CustomerNRB=92874710181271009158695384|VerificationStatus=POSITIVE' }
    end
    let(:hash_model) do
      BluemediaPayments::Hash.from_params(itn_params.merge(service_key: 'ver')).tap do |hash|
        hash.logger = Logger.new(STDOUT)
        hash.method = :md5
      end
    end
    subject { hash_model.hash }
    it { is_expected.to eq('355ec265ee8e3321b7aa32c6e63ad1f4') }
  end
end
