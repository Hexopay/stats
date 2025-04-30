# frozen_string_literal: true

require_relative 'stats/env'
require_relative 'stats/settings'
require_relative 'stats/logger'
require_relative 'stats/main'
require_relative 'stats/loader'
require_relative 'stats/publisher'

module Stats
  class Stats
    include Logger
    attr_reader :options, :logger

    def initialize(options)
      @options = options
    end

    def run
      require 'pry'; binding.pry;
      Main.new(options).run
    rescue StandardError => e
      log("Error: #{e.full_message}")
    end
  end
end
