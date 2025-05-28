# frozen_string_literal: true
module Stats
  class Loader
    class MerchantOrderStats
      attr_reader :date

      STATUSES = %i[All successful failed pending incomplete].freeze
      ALL_MERCHANT = { name: 'All', id: nil }.freeze
      ALL_GATEWAY = { name: 'All', id: nil }.freeze

      def initialize(date)
        @date = date
        @transactions = nil
      end

      def load_for_date
        load_transactions
        build_stats
      end

      private

      def load_transactions
        @transactions =
          query
          .where('hexo_transactions.created_at >= ? AND hexo_transactions.created_at <= ?',
                 date.beginning_of_day, date.end_of_day)
          .where('hexo_orders.test != ?', true) # transaction.order.test == [true]
          .includes(order: [:gateway, { shop: :merchant }])
          .to_a
      end

      def build_stats
        results = []

        # Add the "All merchants, All gateways" combinations first
        results += build_combinations(ALL_MERCHANT, ALL_GATEWAY)

        # Add all merchant-specific combinations with "All gateways"
        merchants.each do |merchant|
          results += build_combinations(merchant, ALL_GATEWAY)
        end

        # Add all gateway-specific combinations with "All merchants"
        gateways.each do |gateway|
          results += build_combinations(ALL_MERCHANT, gateway)
        end

        # Add all merchant+gateway specific combinations
        merchants.each do |merchant|
          gateways.each do |gateway|
            results += build_combinations(merchant, gateway)
          end
        end

        results
      end

      def build_combinations(merchant, gateway)
        filtered = filter_transactions(merchant, gateway)
        total = filtered.size.to_f

        STATUSES.map do |status|
          count = status == :All ? total : filtered.count { |t| t.status == status.to_s }
          next if count.zero?

          {
            merchant: merchant[:name],
            gateway: gateway[:name] == 'All' ? '' : gateway[:name],
            export_time: Time.now,
            created_at: date,
            time_series: Time.now,
            status: status == :successful ? 'success' : status.to_s,
            count: count.to_i,
            percentage: total.zero? ? 0.0 : ((count / total) * 100).round(1)
          }
        end.compact
      end

      def filter_transactions(merchant, gateway)
        @transactions.select do |t|
          (merchant[:name] == 'All' || t.order.shop.merchant_id == merchant[:id]) &&
            (gateway[:name] == 'All' || t.order.gateway_id == gateway[:id])
        end
      end

      def merchants
        @merchants ||= @transactions
                       .map { |t| { name: t.order.shop.merchant.name, id: t.order.shop.merchant_id } }
                       .uniq
      end

      def gateways
        @gateways ||= @transactions
                      .map { |t| { name: t.order.gateway.type.demodulize, id: t.order.gateway.id } }
                      .uniq
      end

      def query
        Transaction::Base.eager_load(order: %i[gateway shop])
      end
    end
  end
end

# dd = Loader::MerchantOrderStats.new(Date.yesterday)
# ddd = dd.load_for_date

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
#         "time_series": {
#           "type": "date"
#         },
#         "times_series": {
#           "type": "date"
#         }
#       }
#     }
#   }
# }
