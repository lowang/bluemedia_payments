module BluemediaPayments
  class Person
    include Base

    define_attributes :email, :phone, :first_name, :last_name, :pesel

    validates :pesel, numericality: true
    validates *attributes.keys, presence: true
  end
end
