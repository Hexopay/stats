# frozen_string_literal: true

require_relative 'stats/env'
require_relative 'stats/settings'
require_relative 'stats/logger'
require_relative 'stats/main'
require_relative 'stats/loader'
require_relative 'stats/publisher'

module Stats
  class Stats
    autoload :Env, 'stats/env'
    autoload :Settings, 'stats/settings'
    attr_reader :options, :logger

    def initialize(options)
      @options = options
      @logger = options.fetch(:logger) { Logger.new }
    end

    def run
      Main.new(options).run
    rescue StandardError => e
      logger.error("Error: #{e.message}")
    end
  end
end
