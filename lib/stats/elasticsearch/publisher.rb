require_relative '../http_helper'
require 'base64'

module Elasticsearch
  class Publisher
    class << self
      include Stats::HttpHelper

      def publish(index_name, message, meta_data, unique_id = '')
        post("#{meta_data[:elasticsearch_url]}/#{index_name}/_doc/#{unique_id}", message.to_json, meta_data[:http_headers])
      end

      def get_document_by_id(index_name, unique_id, meta_data)
        get("#{meta_data[:elasticsearch_url]}/#{index_name}/_doc/#{unique_id}", meta_data[:http_headers])
      end

      def execute_search(index_name, search_request, meta_data)
        post("#{meta_data[:elasticsearch_url]}/#{index_name}/_search", search_request.to_json, meta_data[:http_headers])
      end

      def execute_purge(index_name, search_request, meta_data)
        post("#{meta_data[:elasticsearch_url]}/#{index_name}/_delete_by_query", search_request.to_json, meta_data[:http_headers])
      end
    end

    def self.get_aggregate_results(results)
      # code here
      # {
      #     "took": 2,
      #     "timed_out": false,
      #     "_shards": {
      #         "total": 1,
      #         "successful": 1,
      #         "skipped": 0,
      #         "failed": 0
      #     },
      #     "hits": {
      #         "total": {
      #             "value": 118,
      #             "relation": "eq"
      #         },
      #         "max_score": null,
      #         "hits": []
      #     },
      #     "aggregations": {
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
      # }
      results[:aggregations]
    end
  end
end
