module BluemediaPayments
  class Service
    include Base

    define_attributes :url, :notification_url, :return_url, :commission_model

    validates :commission_model, numericality: true
    validates *attributes.keys, presence: true
  end
end
