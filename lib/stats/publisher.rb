# frozen_string_literal: true

require_relative 'http_helper'

module Stats
  class Publisher
    include HttpHelper
    attr_reader :data, :report_type, :index_name, :settings, :elastic_url, :headers

    def initialize(report_type, data, settings = Settings)
      @data = data
      @report_type = report_type
      @index_name = _set_index_name
      @settings = settings
      @elastic_url = settings.elastic.url
      @headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Basic #{Base64.strict_encode64(settings.elastic.credentials)}"
      }
    end

    def publish
      data.each do |item|
        _push_to_elastic(item)
      end
    end

    private

    def _set_index_name
      report_type
    end

    def _push_to_elastic(item)
      puts "Publishing #{item}"

      post("#{elastic_url}/#{index_name}/_doc/", item.to_json, headers)
    end
  end
end
