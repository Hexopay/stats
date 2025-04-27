# frozen_string_literal: true

# require 'dotenv/load'
require_relative 'http_helper'
require_relative 'currency_cache'
require 'bigdecimal'

module Stats
  class CurrencyConverter
    include Stats::HttpHelper

    attr_reader :value, :base_currency, :target_currency, :date,
                :date_string, :is_today, :stored_currencies, :currency_pair, :full_currency_key,
                :currency_cache_reader, :currency_cache_writer, :api_key, :api_url

    # This method is for compatibility with legacy call to CurrencyConversion.convert_currency(...)
    def self.convert_currency(value, base_currency, target_currency, date)
      new(value, base_currency, target_currency, date).convert
    end

    def initialize(value, base_currency, target_currency, date)
      @value = value
      @base_currency = base_currency
      @target_currency = target_currency
      @date = date

      set_params
    end

    def convert
      return value if base_currency == target_currency

      (rate * value).round(2)
    end

    # private

    def set_params
      @date_string = date.is_a?(String) ? date : date.strftime('%Y-%m-%d')
      @is_today = date_string == Date.today.strftime('%Y-%m-%d')
      @stored_currencies ||= {}
      @currency_pair = "#{base_currency}_#{target_currency}"
      @full_currency_key = "#{date_string}-#{currency_pair}"
      @currency_cache_reader = CurrencyCache.cache_reader
      @currency_cache_writer = CurrencyCache.cache_writer
      @api_key = ENV['CURRENCY_LOOKUP_API_KEY'] # Reserve for the future use with the other api.
      @api_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{date_string}/v1/currencies/#{base_currency.downcase}.json"
    end

    def try_cache_for_lookup
      currency_cache_reader.call(currency_pair, date_string) unless is_today # use cache by default
    rescue StandardError
      nil
    end

    # def rate_from_api
    #
    # response
    # {
    #   "meta": {
    #     "last_updated_at": "2024-06-30T23:59:59Z"
    #   },
    #   "data": {
    #     "USD": {
    #       "code": "USD",
    #       "value": 1.0736869994
    #     }
    #   }
    # }
    #
    def rate_from_api
      response = Env.production? ? get(api_url, {}) : test_response
      return unless response[:status] == 200

      JSON.parse(response[:body]).dig(base_currency.downcase, target_currency.downcase)
    end

    def test_response
      {
        status: 200,
        body: {
          'date': '2025-04-16',
          'eur': {
            'gbp': 6.73046224,
            'pln': 0.0083232376,
            'usd': 1.74579324,
            'chf': 4.15935811,
            'aud': 82.22115587,
          },
          'pln': {
            'eur': 6.73046224,
            'gbp': 6.73046224
          },
          'usd': {
            'eur': 6.73046224,
            'gbp': 6.73046224
          },
          'chf': {
            'eur': 6.73046224,
            'gbp': 6.73046224
          },
          'aud': {
            'eur': 6.73046224,
            'gbp': 6.73046224
          }
        }.to_json
      }
    end

    def rate
      return stored_currencies[full_currency_key] if stored_currencies.key?(full_currency_key)

      res = rate_from_cache = try_cache_for_lookup&.fetch(currency_pair, nil)
      res ||= rate_from_api
      raise StandardError, "No Currency Data Found for #{full_currency_key}" unless res

      res = BigDecimal(res) if res.is_a?(String)
      currency_cache_writer.call(currency_pair, res, date_string) unless rate_from_cache
      # put in hash
      stored_currencies[full_currency_key] = res
    end
  end
end
