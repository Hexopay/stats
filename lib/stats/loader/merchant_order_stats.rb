module Stats
  class Loader
    class MerchantOrderStats
      attr_reader :date

      STATUSES = %i[All successful failed pending incomplete].freeze

      def initialize(date)
        @date = date
      end

      def load_for_date
        res = []
        merchants_gateways.each do |m_g|
          merchant = m_g[:merchant]
          gateway = m_g[:gateway]
          total = 0.0
          STATUSES.each do |status|
            puts [status, 'start:', Time.now.strftime("%H:%M:%S")].join (' ')
            count =
              by_date
              .where(conditions(status, merchant, gateway))
              .count
            total = count.to_f if status == :All
            next if count.zero?

            percentage = total.zero? ? total : (100 / total * count).round(1)
            status = status == :successful ? 'success' : status.to_s
            res << {
              merchant: merchant[:name],
              gateway: gateway[:name],
              export_time: Time.now,
              created_at: date,
              time_series: Time.now,
              status:,
              count:,
              percentage:
            }
            puts [status, 'end:', Time.now.strftime("%H:%M:%S")].join (' ')
          end
        end
        res
      end

      def conditions(status, merchant, gateway)
        res = status == :All ? {} : { status: }
        res[:shop] = { merchant_id: merchant[:id] } if merchant[:name] != 'All'
        res[:order] = { gateway_id: gateway[:id] } if gateway[:name] != 'All'
        res
      end

      def merchants
        by_date.map { |t| { name: t.merchant.name, id: t.merchant_id } }.uniq
      end

      def gateways
        by_date.map { |t| { name: t.gateway.type.demodulize, id: t.gateway.id } }.uniq
      end

      def merchants_gateways
        [{ merchant: { name: 'All' }, gateway: { name: 'All' } }] +
          merchants.map { |m| gateways.map { |g| [merchant: m, gateway: g] } }.flatten
      end

      def query
        Transaction::Base
          .eager_load(order: %i[gateway shop])
      end

      def by_date
        query
          .where(
            'hexo_transactions.created_at >= ? AND hexo_transactions.created_at <= ?',
            date.beginning_of_day, date.end_of_day
          )
      end

      # Merchant Gateway Status
      # All      All     All
      # All      All     success
      # All      All     failed
      # All      All     pending
      # All      All     incomplete
    end
  end
end

# {
#   "mappings": {
#     "_doc": {
#       "properties": {
#         "count": {
#           "type": "long"
#         },
#         "created_at": {
#           "type": "date"
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
#         "percentage": {
#           "type": "long"
#         },
#         "status": {
#           "type": "keyword"
#         },
#         "times_series": {
#           "type": "date"
#         }
#       }
#     }
#   }
# }
