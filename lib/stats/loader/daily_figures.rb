# frozen_string_literal: true

module Stats
  class Loader
    class DailyFigures
      attr_reader :date

      def initialize(date)
        @date = date
      end

      def grouped_operations
        Operation
          .joins(:merchant, :shop)
          .where(created_at: date)
          .group(
            'hexo_operations.merchant_id',
            'merchants.name',
            'hexo_operations.shop_id',
            'shops.name',
            'hexo_operations.status',
            'hexo_operations.country',
            'hexo_operations.currency',
            'hexo_operations.gateway_type',
            'hexo_operations.transaction_type'
          )
          .pluck(
            'hexo_operations.merchant_id',
            'merchants.name',
            'hexo_operations.shop_id',
            'shops.name',
            'hexo_operations.status',
            'hexo_operations.country',
            'hexo_operations.currency',
            'hexo_operations.gateway_type',
            'hexo_operations.transaction_type',
            Arel.sql('COUNT(*)'),
            Arel.sql('SUM(hexo_operations.eur_amount) / 100.0'),
            Arel.sql('SUM(hexo_operations.gbp_amount) / 100.0'),
            Arel.sql('SUM(hexo_operations.amount) / 100.0')
          )
          .map do |row|
            OpenStruct.new(
              merchant_id: row[0],
              merchant_name: row[1],
              shop_id: row[2],
              shop_name: row[3],
              status: row[4],
              country: row[5],
              currency: row[6],
              gateway_type: row[7],
              transaction_type: row[8],
              count: row[9],
              total_eur_amount: row[10],
              total_gbp_amount: row[11],
              total_amount: row[12]
            )
          end
      end

      def load_for_date
        res = []

        grouped_operations.to_a.each_slice(BATCH_SIZE) do |batch|
          res << batch.map do |op|
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
              volume: op.total_amount.to_f,
              volume_eur: op.total_eur_amount.to_f,
              volume_gbp: op.total_gbp_amount.to_f,
              count: op.count
            }
          end
          sleep(LOAD_TIMEOUT)
        end
        res.flatten
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
