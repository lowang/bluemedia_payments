# BluemediaPayments

The BluemediaPayments Ruby gem provides access to the Bluemedia.pl payment and merchant API.

[by Nokaut.pl](http://nokaut.pl)

## Features

* supports background orders (your website -> bank website)
* handle order notifications - ITN's
* create new POS services via merchant API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bluemedia_payments'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bluemedia_payments

## Usage

### Multiple merchant scenario

I assume you have already got some secrets:
- BLueMedia WSDL address
- PLATFORM_ID
- SHARED_KEY for signing SOAP requests
- configured on the BlueMedia side return url to your verification page
- VERIFICATION_MERCHANT_ID
- VERIFICATION_SHARED_KEY

#### Create new Service (POS)

You can use [ our sample ](./examples/company.rb) to test if it's working properly
To make it work create `GEM_ROOT/.env` file and supply your secrets

##### Service verification

Verification ITN is hardcoded on the BlueMedia side, it's the same for all created services.
Also it's different address from order notification ITN sent to CreateCompany. The last one can be unique for each service. 
You can catch it using [ sample server ](./examples/server.rb)
Make sure that is binds to publicly available address on the internet so BlueMedia can post to it.
No it won't work on localhost.

Open <ActivationLink> url from Create new Service step in your browser, perform validation payment.
Wait for verification ITN to arrive. Make sure that you've got *VerificationStatus=POSITIVE* in <param>

If you've got VerificationStatus: POSITIVE - now you can enable this service to perform payments.

#### Payment

Use `SERVICE_ID` and `SERVICE_KEY` obtained from Create new Service step and place them in `GEM_ROOT/.env` file.
You can use [ our sample ](./examples/order.rb) to test if it's working properly.
It creates `GEM_ROOT/output.html` file and opens in your browser.
If all goes correctly it should contain auto submitting form which will redirect you to selected bank page.
Note: on test env you will be redirected to BM test payment page. No real money are exchanged there.

##### Payment notification

It will be send as an ITN to address specified in Create new Service step. 
Make sure you have a [ sample server ](./examples/server.rb) running which can catch it.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/lowang/bluemedia_payments/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
