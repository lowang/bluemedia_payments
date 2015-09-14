require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'dotenv'
require 'base64'
require 'nori'
require 'pry'

Dotenv.load('../.env')

configure do
  set :port, 3000
  set :bind, '0.0.0.0'
end

post '/itn' do
  xml = Base64.decode64(params[:transactions])
  puts xml

  parser = Nori.new
  parsed_xml = parser.parse(xml)['transactionList']
  transaction = parsed_xml['transactions']['transaction']

  puts "serviceID: " + parsed_xml['serviceID']
  puts "orderID: " + transaction['orderID']
  puts "hash: " + parsed_xml['hash']

  verify_hash = [parsed_xml['serviceID'], transaction['orderID'], transaction['remoteID'], transaction['amount'],
    transaction['currency'], transaction['gatewayID'], transaction['paymentDate'],
    transaction['paymentStatus'], transaction['paymentStatusDetails'],
  ]
  verify_hash = verify_hash.join('|') + '|' + ENV['SERVICE_KEY']
  puts "IN KEY: #{verify_hash.inspect}"
  verify_hash = Digest::SHA256.hexdigest(verify_hash)
  confirmation_status = (parsed_xml['hash'] == verify_hash) ? 'CONFIRMED' : 'NOTCONFIRMED'

  status 200
  service_id = parsed_xml['serviceID']
  order_id = parsed_xml['transactions']['transaction']['orderID']
  key = [service_id, order_id, confirmation_status].join('|') + '|' + ENV['SERVICE_KEY']
  puts "OUT KEY: #{key.inspect}"
  confirmation_hash = Digest::SHA256.hexdigest(key)
  xml =<<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<confirmationList>
  <serviceID>#{service_id}</serviceID>
  <transactionsConfirmations>
    <transactionConfirmed>
      <orderID>#{order_id}</orderID>
      <confirmation>#{confirmation_status}</confirmation>
    </transactionConfirmed>
  </transactionsConfirmations>
  <hash>#{confirmation_hash}</hash>
</confirmationList>
  EOS
  body xml
end

# curl -v "http://localhost:3000/payment_complete?ServiceID=2&OrderID=100&Hash=254eac9980db56f425acf8a9df715cbd6f56de3c410b05f05016630f7d30a4ed"
get '/payment_complete' do
  # jaki jest sens weryfikacji hash?
  body <<-EOS
service_id: #{params['ServiceID']}
order_id: #{params['OrderID']}
  EOS
end

post '/itn_verification' do
  xml = Base64.decode64(params[:transactions])
  puts xml

  parser = Nori.new
  parsed_xml = parser.parse(xml)['transactionList']
  transaction = parsed_xml['transactions']['transaction']

  puts "-"*30
  puts "merchantID: " + parsed_xml['merchantID'] + " (expected: #{ENV['VERIFICATION_MERCHANT_ID']})"
  puts "orderID: " + transaction['orderID']
  parsed_params = CGI::parse(transaction['param'].gsub('|', '&'))
  puts "VerificationStatus: " + parsed_params['VerificationStatus'].first
  puts "hash: " + parsed_xml['docHash']

  verify_hash = [ENV['VERIFICATION_MERCHANT_ID'], transaction['orderID'], transaction['transID'], transaction['transDate'],
    transaction['amount'], transaction['currency'], transaction['paywayID'], transaction['statusDate'],
    transaction['status'], transaction['param']
  ]
  verify_hash = verify_hash.join('') + '' + ENV['VERIFICATION_SHARED_KEY']
  verify_hash = Digest::MD5.hexdigest(verify_hash)
  puts "IN HASH: #{verify_hash}"
  confirmation_status = (parsed_xml['docHash'] == verify_hash) ? 'CONFIRMED' : 'NOTCONFIRMED'

  status 200

  order_id = transaction['orderID']
  key = [ENV['VERIFICATION_MERCHANT_ID'], order_id, confirmation_status].join('') + '' + ENV['VERIFICATION_SHARED_KEY']
  puts "KEY: #{key.inspect}"
  confirmation_hash = Digest::MD5.hexdigest(key)
  xml =<<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<confirmationList>
  <merchantID>#{ENV['VERIFICATION_MERCHANT_ID']}</merchantID>
  <transactionsConfirmations>
    <transactionConfirmed>
      <orderID>#{order_id}</orderID>
      <confirmation>#{confirmation_status}</confirmation>
    </transactionConfirmed>
  </transactionsConfirmations>
  <docHash>#{confirmation_hash}</docHash>
</confirmationList>
  EOS
  body xml
end
