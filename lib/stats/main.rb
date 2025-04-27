# frozen_string_literal: true

require_relative 'args_handler'

# Main class
module Stats
  class Main
    attr_reader :report_type, :dates, :data, :period

    def initialize(options = {})
      @report_type = options.fetch(:report_type) || 'daily_stats'
      @period = options.fetch(:period) || 'yesterday'
      _set_params
    end

    def run
      _load_data
      _publish
    end

    private

    def _set_params
      @runtime_opts = ArgsHandler.new([report_type, period])
      @dates = @runtime_opts.dates
    end

    def _load_data
      @data = Loader.new(report_type:, dates:).load
    end

    def _publish
      Publisher.new(report_type, data).publish
    end
  end
end
