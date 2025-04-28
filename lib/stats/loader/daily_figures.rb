require_relative '../currency_converter'

module Stats
  class Loader
    class DailyFigures
      attr_reader :date, :currency_converter

      def initialize(date, currency_converter=nil)
        @date = date
        @currency_converter = currency_converter || CurrencyConverter
      end

      def load_for_date
        merchants = Merchant.pluck(:id, :name).to_h
        shops = Shop.pluck(:id, :name).to_h
        gateways = Gateway.pluck(:id, :type).to_h
        countries = Operation.pluck(:country).uniq
        statuses = Operation.pluck(:status).uniq
        # statuses = %w[successful failed pending expired incomplete]
        # keys = %i[merchant_id]

        Operation
          .where('created_at >= ? AND created_at <= ?', date.beginning_of_day, date.end_of_day)
          .group_by { |o| [o.merchant_id, o.shop_id, o.gateway_id, o.status, o.country, o.currency, o.transaction_type] }
          .map do |keys, ops|
            merchant_id, shop_id, gateway_id, status, country, currency, transaction_type = keys
            volume = ops.sum(&:amount).to_f
            count = ops.count.to_s
            {
              merchant: merchants[merchant_id],
              back_office_merchant_id: merchant_id,
              shop: shops[shop_id],
              back_office_shop_id: shop_id,
              gateway: gateways[gateway_id].demodulize,
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
