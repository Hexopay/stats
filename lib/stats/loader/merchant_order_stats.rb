# frozen_string_literal: true

module Stats
  class Loader
    class MerchantOrderStats
      attr_reader :date, :transactions, :merchants, :gateways

      STATUSES = %i[All successful failed pending incomplete].freeze
      ALL_MERCHANT = { name: 'All', id: nil }.freeze
      ALL_GATEWAY = { name: 'All', id: nil }.freeze

      def initialize(date)
        @date = date
        @transactions = nil
      end

      # def load_for_date
      #   # Get counts directly from SQL
      #   sql = <<~SQL
      #     SELECT
      #       m.name AS merchant_name,
      #       g.type AS gateway_type,
      #       t.status,
      #       COUNT(t.id) AS count,
      #       date_trunc('day', t.created_at) AS created_at
      #     FROM hexo_transactions t
      #     JOIN hexo_orders o ON t.order_id = o.id
      #     JOIN shops s ON o.shop_id = s.id
      #     JOIN merchants m ON s.merchant_id = m.id
      #     JOIN gateways g ON o.gateway_id = g.id
      #     WHERE t.created_at BETWEEN '#{date.beginning_of_day}' AND '#{date.end_of_day}'
      #       AND o.test = false
      #     GROUP BY GROUPING SETS (
      #       (m.name, g.type, t.status, date_trunc('day', t.created_at)),
      #       (m.name, t.status, date_trunc('day', t.created_at)),
      #       (g.type, t.status, date_trunc('day', t.created_at)),
      #       (t.status, date_trunc('day', t.created_at))
      #     )
      #   SQL

      #   results = ActiveRecord::Base.connection.execute(sql)

      #   # Process the raw SQL results into your desired format
      #   # format_results(results)
      # end

      def load_for_date
        @transactions = _load_transactions
        _build_stats
      end

      private

      def _load_transactions
        _query
          .where(created_at: date.beginning_of_day.utc..date.end_of_day.utc)
          .where('hexo_orders.test != ?', true) # transaction.order.test == [true]
          .includes(order: [:gateway, { shop: :merchant }])
          .to_a
      end

      def _build_stats
        results = []

        # Add the "All merchants, All gateways" combinations first
        results += _build_combinations(ALL_MERCHANT, ALL_GATEWAY)

        # comment follow 4 lines to not include combinations of [merchant] + All gateways
        # Add all merchant-specific combinations with "All gateways"
        # _merchants.each do |merchant|
        #   results += _build_combinations(merchant, ALL_GATEWAY)
        # end

        # Add all gateway-specific combinations with "All merchants"
        _gateways.each do |gateway|
          results += _build_combinations(ALL_MERCHANT, gateway)
        end

        # Add all merchant+gateway specific combinations
        _merchants.each do |merchant|
          _gateways.each do |gateway|
            results += _build_combinations(merchant, gateway)
          end
        end

        results
      end

      def _build_combinations(merchant, gateway)
        filtered = _filter_transactions(merchant, gateway)
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

      def _filter_transactions(merchant, gateway)
        transactions.select do |t|
          (merchant[:name] == 'All' || t.order.shop.merchant_id == merchant[:id]) &&
            (gateway[:name] == 'All' || t.order.gateway_id == gateway[:id])
        end
      end

      def _merchants
        @merchants ||= transactions
                       .map { |t| { name: t.order.shop.merchant.company_name, id: t.order.shop.merchant_id } }
                       .uniq
      end

      def _gateways
        @gateways ||= transactions
                      .map { |t| { name: t.order.gateway.type.demodulize, id: t.order.gateway.id } }
                      .uniq
      end

      def _query
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
