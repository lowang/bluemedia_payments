require 'rubygems'
require 'bundler/setup'
require 'restclient'
require 'bluemedia_payments'
require 'dotenv'
require 'pry'

Dotenv.load('../.env')

service = BluemediaPayments::Service.new(service_id: ENV['SERVICE_ID'], service_key: ENV['SERVICE_KEY'], gateway_url: ENV['GATEWAY_URL'])
valid_attributes = { order_id: 1, amount: 10.2, title: 'zakup',
    description: 'zakup punktów reklamowych',
    customer_email: 'przemyslaw.wroblewski+test1@nokaut.pl',
    customer_ip: '81.210.106.10', service: service, gateway_id: 106  }
order = BluemediaPayments::Order.new(valid_attributes)
puts "valid? #{order.valid?}"
unless order.valid?
  p order.errors
  exit 1
end
result = order.create
p result
File.open('../output.html','w+') { |f| f.write result }
`open ../output.html`
