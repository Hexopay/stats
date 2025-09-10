# frozen_string_literal: true

# Environemnts
module Stats
  module Env
    ENVIRONMENTS = %w[development test staging production].freeze

    class << self
      ENVIRONMENTS.each do |environment|
        define_method environment do
          ENV['stats_environment'] = environment
        end
        define_method "#{environment}?" do
          ENV['stats_environment'] == environment
        end
      end

      def current
        ENV['stats_environment']
      end

      def set(env)
        ENV['stats_environment'] = env
      end

      def default
        ENVIRONMENTS.first
      end
    end
  end
end
