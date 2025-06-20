# frozen_string_literal: true
# rubocop:disable Layout/HashAlignment

module Stats
  class Loader
    class MerchantOrderStats
      attr_reader :date, :transactions, :merchants, :gateways

      STATUSES = %i[All successful failed pending incomplete expired].freeze
      ALL_MERCHANT = { name: 'All', id: nil }.freeze
      ALL_GATEWAY = { type: 'All' }.freeze

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
        opts = {
          from:             date.strftime('%Y-%m-%d'),
          to:               date.strftime('%Y-%m-%d'),
          group_period:     nil,
          card_type:        nil,
          date_range:       'created_at',
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

      def _load_transactions_0
        _query
          .where(paid_at: date.beginning_of_day.utc..date.end_of_day.utc)
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
        # _gateways.each do |gateway|
        #   results += _build_combinations(ALL_MERCHANT, gateway)
        # end

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
        total = filtered.sum{|i| i['count']}.to_f

        return [] if filtered.empty?

        STATUSES.map do |status|
          count = status.to_s == 'All' ? total : filtered.select { |t| t['status'] == status.to_s }.sum{|i| i['count']}.to_f

          # next if count.zero?

          {
            merchant: merchant[:name],
            gateway: gateway[:type].to_s == 'All' ? '' : gateway[:type].to_s,
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
          (merchant[:name] == 'All' || t['merchant_id'] == merchant[:id]) &&
            (gateway[:type] == 'All' || t['gateway_type'].demodulize == gateway[:type])
        end
      end

      def _merchants
        @merchants ||= transactions
                       .map { |t| { name: t['company_name'], id: t['merchant_id'] } }
                       .uniq
      end

      def _gateways
        @gateways ||= transactions
                      .map { |t| { type: t['gateway_type'].demodulize } }
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
