require 'rubygems'
require 'bundler/setup'
require 'restclient'
require 'bluemedia_payments'
require 'dotenv'
require 'pry'

Dotenv.load('../.env')

# http://www.bogus.ovh.org/generatory/all.html

service_params = {
  url: "http://#{ENV['EXTERNAL_WEB']}",
  notification_url: "http://#{ENV['EXTERNAL_WEB']}/itn",
  return_url: "http://#{ENV['EXTERNAL_WEB']}/payment_complete",
  commission_model: 1
}
person_params = {
  email: 'jan.kowalski@example.pl',
  phone: '555100200',
  first_name:'Jan',
  last_name: 'Kowalski',
  pesel: '80121503875',
}
valid_params = { id:1, name: 'Firma testowa', profile: 'OTHER', bank_account: '92 8747 1018 1271 0091 5869 5384'.gsub(/ /, ''),
  address: 'Sportowa 8B', postal_code: '81-300', city: 'Gdynia', country: 'Polska',
  nip: '4750005268', regon: '951889253', krs: '0000440039', kind: 'SP_ZOO',
  service: BluemediaPayments::Service.new(service_params), person: BluemediaPayments::Person.new(person_params), beneficial_owner: false
}

company = BluemediaPayments::Company.new(valid_params)
company.logging_enabled = true
company.platform_id = ENV['PLATFORM_ID']
company.shared_key = ENV['SOAP_SHARED_KEY']
result = company.create
p result
# puts
# puts CGI.unescapeHTML(result[:register_response][:activation_link])
