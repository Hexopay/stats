# frozen_string_literal: true

# Environemnts
module Stats
  module Env
    ENVIRONMENTS = %w[development test staging production].freeze

    class << self
      ENVIRONMENTS.each do |environment|
        define_method environment do
          ENV['stats_environmnent'] = environment
        end
        define_method "#{environment}?" do
          ENV['stats_environmnent'] == environment
        end
      end

      def current
        ENV['stats_environmnent']
      end

      def set(env)
        ENV['stats_environmnent'] = env
      end

      def default
        ENVIRONMENTS.first
      end
    end

    set Rails.env
  end
end
