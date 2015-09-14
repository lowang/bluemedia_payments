require 'rubygems'
require 'bundler/setup'
require 'restclient'
require 'base64'

xml = <<-EOS
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<transactionList>
    <serviceID>417</serviceID>
    <transactions>
        <transaction>
            <orderID>1</orderID>
            <remoteID>96MAETW8</remoteID>
            <amount>10.20</amount>
            <currency>PLN</currency>
            <gatewayID>106</gatewayID>
            <paymentDate>20151009103646</paymentDate>
            <paymentStatus>SUCCESS</paymentStatus>
            <paymentStatusDetails>AUTHORIZED</paymentStatusDetails>
        </transaction>
    </transactions>
    <hash>3111ae3e9e1c8ec417834a1d9a67fbee66ad0d8e4c2ff0c33e8163bd13300ac0</hash>
</transactionList>
EOS

RestClient.log = Logger.new STDOUT
puts RestClient.post 'http://localhost:3000/itn', { transactions: Base64.encode64(xml) } , {:content_type => :xml}
