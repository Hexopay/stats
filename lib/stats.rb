# frozen_string_literal: true

require_relative 'stats/env'
require_relative 'stats/logger'
require_relative 'stats/main'
require_relative 'stats/loader'
require_relative 'stats/publisher'

module Stats
  class Stats
    include Logger
    attr_reader :options

    def initialize(options)
      @options = options
      Env.set options.fetch(:env, Env.default)
    end

    def run
      Main.new(options).run
    rescue => e
      log("Error: #{e.full_message}", :error)
    end
  end
end
