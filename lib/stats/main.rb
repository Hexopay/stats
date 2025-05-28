# frozen_string_literal: true

require_relative 'args_handler'

# Main class
module Stats
  class Main
    include Logger
    attr_reader :report_type, :dates, :data, :settings

    def initialize(options = {})
      args_handler = options.fetch(:args_handler, ArgsHandler)
      runtime_opts = args_handler.new(
        [
          options[:report_type],
          options[:period]
        ]
      ).handle
      @dates = runtime_opts.dates
      @report_type = runtime_opts.report_type
      @settings = options[:settings]
    end

    def run
      _load_data
      _publish
    end

    private

    def _load_data
      log("Start loading #{report_type}, dates: #{dates}")
      @data = Loader.new(report_type:, dates:).load
      log("End loading #{report_type}, dates: #{dates}")
    end

    def _publish
      log("Start publuishing #{report_type}, dates: #{dates}")
      Publisher.new(report_type, data, settings).publish
      log("End publishing #{report_type}, dates: #{dates}")
    end
  end
end
