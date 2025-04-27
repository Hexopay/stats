require_relative 'hexostats'
# require 'aws-sdk-sns'

module Stats
  class CurrencyCache
    class << self
      # def populate_cache
      #   SQS.poll_sqs_for_messages(ENV['AWS_CURRENCY_CACHE_Q'], 10, 10) do |message|
      #     Stats::Hexostats.store_currency_rate(message[:currency_pair], message[:conversion_rate],  message[:date])
      #   end
      # end

      # def sns
      #   @sns ||= Aws::SNS::Resource.new(region: ENV['AWS_REGION'])
      # end

      # def topic
      #   @topic ||= sns.topic(ENV['AWS_CURRENCY_CACHE_SNS_TOPIC'])
      # end

      def cache_reader
        @currency_cache_reader ||= ->(currency_pair, date) { Stats::Hexostats.fetch_currency_rate(currency_pair, date) }
      end

      def cache_writer
        @currency_cache_writer ||= ->(currency_pair, conversion_rate, date) do
          if ENV['DISABLE_TOPIC_PUBLISH'].nil?
            # topic.publish(
            #     {
            #         message: JSON.generate({
            #                                   currency_pair: currency_pair,
            #                                   conversion_rate: conversion_rate,
            #                                   date: date,
            #                                   export_time: Time.now
            #                               })
            #     }
            # )
          else
            puts "DISABLE_TOPIC_PUBLISH -> #{currency_pair} #{conversion_rate}  #{date}"
          end
        end
      end
    end
  end
end
