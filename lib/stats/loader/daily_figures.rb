require_relative '../currency_converter'

module Stats
  class Loader
    class DailyFigures
      attr_reader :date, :currency_converter, :rates

      def initialize(date, currency_converter=nil)
        @date = date
        @currency_converter = currency_converter || CurrencyConverter
        @rates = JSON.parse CurrencyConvertor.new(date: date).rate.dump
      end

      def grouped_operations
        Operation
          .joins(:merchant, :shop)
          .select(
            'hexo_operations.merchant_id,
             merchants.name AS merchant_name,
             hexo_operations.shop_id,
             shops.name AS shop_name,
             hexo_operations.status,
             hexo_operations.country,
             hexo_operations.currency,
             hexo_operations.gateway_type,
             hexo_operations.transaction_type,
             COUNT(hexo_operations.id) AS count,
             SUM(hexo_operations.eur_amount) AS total_eur_amount,
             SUM(hexo_operations.gbp_amount) AS total_gbp_amount,
             SUM(hexo_operations.amount) AS total_amount'
          )
          .where(created_at: date)
          .group(
            'hexo_operations.merchant_id,
             merchant_name,
             hexo_operations.shop_id,
             shop_name,
             hexo_operations.status,
             hexo_operations.country,
             hexo_operations.currency,
             hexo_operations.gateway_type,
             hexo_operations.transaction_type'
          )
      end

      def load_for_date
        grouped_operations.map do |op|
          {
            merchant: op.merchant_name,
            back_office_merchant_id: op.merchant_id,
            shop: op.shop_name,
            back_office_shop_id: op.shop_id,
            gateway: op.gateway_type.demodulize,
            status: op.status.capitalize,
            country: op.country,
            currency: op.currency,
            transaction_type: op.transaction_type.demodulize,
            export_time: Time.now,
            created_at: date.strftime('%Y-%m-%d'),
            card: '',
            volume: (op.total_amount / 100.0).to_s,
            volume_eur: (op.total_eur_amount / 100.0).to_s,
            volume_gbp: (op.total_gbp_amount / 100.0).to_s,
            count: op.count.to_s
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
