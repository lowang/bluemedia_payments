# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bluemedia_payments/version'

Gem::Specification.new do |spec|
  spec.name          = "bluemedia_payments"
  spec.version       = BluemediaPayments::VERSION
  spec.authors       = ["Przemyslaw Wroblewski"]
  spec.email         = ["przemyslaw.wroblewski@nokaut.pl"]

  spec.summary       = %q{The BluemediaPayments Ruby gem provides access to the Bluemedia.pl payment and merchant API.}
  spec.description   = %q{supports background orders (your website -> bank website), handle order notifications - ITN's, create new POS services via merchant API}
  spec.homepage      = "https://github.com/lowang/bluemedia_payments"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel"
  spec.add_dependency "activesupport"
  spec.add_dependency "active_attr"
  spec.add_dependency "rest-client"
  spec.add_dependency "savon"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "sinatra"
end
