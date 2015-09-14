require 'rubygems'
require 'bundler/setup'
require 'restclient'
require 'base64'

xml = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<transactionList>
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
      <param>CustomerAddress=SmFuIEtvbHdhc2tp|CustomerNRB=92874710181271009158695384|VerificationStatus=POSITIVE</param>
    </transaction>
  </transactions>
  <docHash>e1202437c9dbea3c1444aa0f38f7c5fb</docHash>
</transactionList>
EOS

RestClient.log = Logger.new STDOUT
puts RestClient.post 'http://localhost:3000/itn_verification', { transactions: Base64.encode64(xml) } , {:content_type => :xml}
