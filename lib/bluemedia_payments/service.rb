module BluemediaPayments
  class Service
    include Base

    VERIFICATION_ATTRIBUTES = [:merchant_id, :verification_shared_key]
    COMPANY_ATTRIBUTES = [:commission_model, :soap_shared_key, :platform_id, :url, :notification_url, :return_url]
    ORDER_ATTRIBUTES = [:service_id, :service_key, :gateway_url]

    define_attributes :url, :notification_url, :return_url, :commission_model, :platform_id
    define_attributes :merchant_id, :soap_shared_key, :verification_shared_key
    define_attributes *ORDER_ATTRIBUTES
    attribute :time_offset, default: 0

    validates :commission_model, numericality: true, on: :company_create
    validates *COMPANY_ATTRIBUTES, presence: true, on: :company_create
    validates *VERIFICATION_ATTRIBUTES, presence: true, on: :verification
    validates *ORDER_ATTRIBUTES, presence: true, on: :order
  end
end
