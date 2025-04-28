# frozen_string_literal: true

require_relative 'args_handler'

# Main class
module Stats
  class Main
    include Logger
    attr_reader :report_type, :dates, :data, :period

    def initialize(options = {})
      @report_type = options.fetch(:report_type) || 'daily_figures'
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
      log('Start loading ' + report_type)
      @data = Loader.new(report_type:, dates:).load
      log('End loading ' + report_type)
    end

    def _publish
      log('Start publishing' + report_type)
      Publisher.new(report_type, data).publish
      log('End publishing' + report_type)
    end
  end
end
