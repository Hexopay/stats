require_relative '../currency_converter'

module Stats
  class Loader
    class DailyFigures
      attr_reader :date, :currency_converter

      def initialize(date, currency_converter=nil)
        @date = date
        @currency_converter = currency_converter || CurrencyConverter
      end

      def grouped_operations
        Operation
          .eager_load(:shop, :merchant, :gateway)
          .where(created_at: date)
          .group_by do |operation|
            [
              operation.merchant_id, operation.merchant.name,
              operation.shop_id, operation.shop.name,
              operation.gateway.type,
              operation.status, operation.country, operation.currency, operation.transaction_type
            ]
          end
      end

      def load_for_date
        grouped_operations.map do |keys, ops|
          merchant_id, merchant_name, shop_id, shop_name, gateway_type,
          status, country, currency, transaction_type = keys
          volume = ops.sum(&:amount).to_f
          count = ops.count.to_s
          {
            merchant: merchant_name,
            back_office_merchant_id: merchant_id,
            shop: shop_name,
            back_office_shop_id: shop_id,
            gateway: gateway_type.demodulize,
            status: status.capitalize,
            country:,
            currency:,
            transaction_type: transaction_type.demodulize,
            export_time: Time.now,
            created_at: date.strftime('%Y-%m-%d'),

            card: '', # Ask if it is right
            volume: volume.to_s,
            volume_eur: currency_converter.new(volume, currency, 'EUR', date).convert,
            volume_gbp: currency_converter.new(volume, currency, 'GBP', date).convert,
            count:
          }
        end
      end
    end
  end
end

# {
#   "mappings": {
#     "_doc": {
#       "properties": {
#         "back_office_merchant_id": {
#           "type": "long"
#         },
#         "back_office_shop_id": {
#           "type": "long"
#         },
#         "card": {
#           "type": "keyword"
#         },
#         "count": {
#           "type": "long"
#         },
#         "country": {
#           "type": "keyword"
#         },
#         "created_at": {
#           "type": "date"
#         },
#         "currency": {
#           "type": "keyword"
#         },
#         "export_time": {
#           "type": "text"
#         },
#         "gateway": {
#           "type": "keyword"
#         },
#         "merchant": {
#           "type": "keyword"
#         },
#         "shop": {
#           "type": "keyword"
#         },
#         "status": {
#           "type": "keyword"
#         },
#         "transaction_type": {
#           "type": "keyword"
#         },
#         "volume": {
#           "type": "double"
#         },
#         "volume_eur": {
#           "type": "float"
#         },
#         "volume_gbp": {
#           "type": "double"
#         }
#       }
#     }
#   }
# }
