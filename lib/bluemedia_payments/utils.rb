module BluemediaPayments
  module Utils
    def cast_value(value)
      case value.presence
        when DateTime then value.strftime('%Y%m%d%H%M%S')
        when Date then value.strftime('%Y%m%d')
        when BigDecimal then '%.2f' % value
        else value.presence
      end
    end
    module_function :cast_value
  end
end
