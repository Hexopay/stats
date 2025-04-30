# frozen_string_literal: true

require_relative 'args_handler'

# Main class
module Stats
  class Main
    include Logger
    attr_reader :report_type, :period, :dates, :data

    def initialize(options = {})
      @report_type = options.fetch(:report_type, 'daily_figures')
      @period = options.fetch(:period, 'yesterday')
      args_handler = options.fetch(:args_handler, ArgsHandler)
      runtime_opts = args_handler.new([report_type, period])
      @dates = runtime_opts.dates
    end

    def run
      _load_data
      _publish
    end

    private

    def _load_data
      log('Start loading ' + report_type)
      @data = Loader.new(report_type:, dates:).load
      log('End loading ' + report_type)
    end

    def _publish
      log('Start publishing ' + report_type)
      Publisher.new(report_type, data).publish
      log('End publishing ' + report_type)
    end
  end
end
