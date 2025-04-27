require_relative 'elasticsearch/publisher'
require 'json'

module Stats
  class Hexostats
    class << self
      def elastic_search_options
        @elastic_search_options ||= {
          elasticsearch_url: ENV['ELASTICSEARCH_URL'],
          http_headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Basic #{Base64.strict_encode64(ENV['ELASTIC_SEARCH_CREDENTIALS'])}"
          }
        }
      end

      def store_currency_rate(currency_pair, conversion_rate, date)
        # we should only store currencies rates on the day they are valid...
        # store under date specific keu and generic key so that we can easily fallback to a rate if no rate for date found...
        ["#{currency_pair}", "#{date}-#{currency_pair}"].each do |unique_id|
          Elasticsearch::Publisher.publish('currencies',
                                           {
                                             date: date,
                                             currency_pair: currency_pair,
                                             conversion_rate: conversion_rate,
                                             timestamp: Time.now
                                           }, elastic_search_options, unique_id)
        end
      end

      def fetch_currency_rate(currency_pair, date)
        # get by date if possible...
        fetch_currency_rate_for(currency_pair, "#{date}-#{currency_pair}")
      rescue StandardError
        fetch_currency_rate_for(currency_pair, currency_pair)
      end

      def fetch_currency_rate_for(currency_pair, unique_id)
        result = Elasticsearch::Publisher.get_document_by_id('currencies', unique_id, elastic_search_options)
        raise "Issue With Elastic Search #{result[:body]}" unless result[:status] == 200

        response = JSON.parse(result[:body]) # don;t symbolise as we don't do this for currency lookups..
        {
          currency_pair => response['_source']['conversion_rate']
        }
      end

      def purge_data(index_name, start_date, end_date)
        query = {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "created_at": {
                      "gte": start_date.strftime('%Y-%m-%d'),
                      "lte": end_date.strftime('%Y-%m-%d'),
                      "format": 'strict_date_optional_time'
                    }
                  }
                }
              ],
              "filter": [],
              "should": [],
              "must_not": []
            }
          }
        }

        result = Elasticsearch::Publisher.execute_purge(index_name, query, elastic_search_options)
        raise 'Error Communicating with Elasticsearch' if result[:status] != 200
      end

      def get_gateways_for_merchant(merchant_name, gateways_used_since)
        query = {
          "aggs": {
            "gateways": {
              "terms": {
                "field": 'gateway'
              }
            }
          },
          "size": 0,
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "created_at": {
                      "gte": gateways_used_since,
                      "format": 'strict_date_optional_time'
                    }
                  }
                }
              ],
              "filter": [
                {
                  "match_phrase": {
                    "merchant": merchant_name
                  }
                }
              ],
              "should": [],
              "must_not": []
            }
          }
        }

        result = Elasticsearch::Publisher.execute_search('daily_figures', query, elastic_search_options)

        raise 'Error Communicating with Elasticsearch' if result[:status] != 200

        aggregate_results = Elasticsearch::Publisher.get_aggregate_results(JSON.parse(result[:body],
                                                                                      symbolize_names: true))

        aggregate_results[:gateways][:buckets].map { |bucket| bucket[:key] }
        # {
        #         "gateways": {
        #             "doc_count_error_upper_bound": 0,
        #             "sum_other_doc_count": 0,
        #             "buckets": [
        #                 {
        #                     "key": "Paydoo",
        #                     "doc_count": 90
        #                 },
        #                 {
        #                     "key": "UPaySafeDirect",
        #                     "doc_count": 24
        #                 },
        #                 {
        #                     "key": "WonderlandPay",
        #                     "doc_count": 4
        #                 }
        #             ]
        #         }
        #     }
        #
      end
    end
  end
end
