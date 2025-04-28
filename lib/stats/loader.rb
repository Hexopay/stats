# frozen_string_literal: true

require_relative 'loader/daily_figures'
require_relative 'loader/merchant_order_stats'

module Stats
  class Loader
    attr_reader :report_type, :dates, :klass

    def initialize(options)
      @report_type = options.fetch(:report_type)
      @dates = options.fetch(:dates)
      @klass = [self.class.name, report_type.camelize].join('::').constantize
    end

    def load
      dates.map do |date|
        {
          date:,
          data: klass.new(date).load_for_date
        }
      end
    end
  end
end
