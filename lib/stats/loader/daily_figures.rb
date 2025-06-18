# frozen_string_literal: true
# rubocop:disable Layout/HashAlignment
require 'ostruct'

module Stats
  class Loader
    class DailyFigures
      attr_reader :date, :transactions

      def initialize(date)
        @date = date
        @transactions = nil
      end

      def grouped_operations
        ops = Operation
          .joins(:merchant, :shop)
          .where(created_at: date.beginning_of_day.utc..date.end_of_day.utc)
          .group(
            'hexo_operations.merchant_id',
            'merchants.company_name',
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
            'merchants.company_name',
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
        ops.map do |row|
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

      def load_for_date_0
        res = []
        grouped_operations.to_a.each_slice(BATCH_SIZE) do |slice|
          res << slice.map do |op|
            {
              merchant: op.merchant_name,
              back_office_merchant_id: op.merchant_id.to_s,
              shop: op.shop_name,
              back_office_shop_id: op.shop_id.to_s,
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

      def load_for_date
        @transactions = _load_transactions
        _build_stats
      end

      private

      def _load_transactions
        opts = {
          from:             date.strftime('%Y-%m-%d'),
          to:               date.strftime('%Y-%m-%d'),
          group_period:     nil,
          card_type:        nil,
          date_range:       'paid_at',
          time_zone:        'Etc/UTC',
          merchant:         '0',
          shop:             '0',
          gateway_type:     '0',
          country:          '0',
          currency:         '0',
          transaction_type: '0',
          status:           '0'
        }

        r = Builders::TransactionReport.new(opts).build
        r.generate
        r.rows
      end

      def _build_stats
        res = []
        transactions.to_a.each_slice(BATCH_SIZE) do |slice|
          res << slice.map do |item|
            {
              merchant:               item['company_name'],
              back_office_merchant_id: item['merchant_id'].to_s,
              shop:                   item['shop_name'],
              back_office_shop_id:     item['shop_id'].to_s,
              gateway:                item['gateway_type'].demodulize,
              status:                 item['status'].capitalize,
              country:                item['country'],
              currency:               item['currency'],
              transaction_type:       item['transaction_type'].demodulize,
              volume:                 item['volume'].to_f / 100,
              volume_eur:             item['volume_eur'].to_f / 100,
              volume_gbp:             item['volume_gbp'].to_f / 100,
              count:                  item['count'],
              export_time:            Time.now,
              created_at:             date.strftime('%Y-%m-%d'),
              card:                   ''
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
