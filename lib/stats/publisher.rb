# frozen_string_literal: true

require_relative 'http_helper'

module Stats
  class Publisher
    include HttpHelper
    attr_reader :data, :report_type, :index_name, :settings, :elastic_url, :proxy_url, :headers

    def initialize(report_type, data, settings)
      @data = data
      @report_type = report_type
      @index_name = _index_name
      @settings = settings
      @elastic_url = settings.elastic.url
      @proxy_url = settings.proxy_url
      @headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Basic #{Base64.strict_encode64(settings.elastic.credentials)}"
      }
    end

    def publish
      data.each do |set_for_date|
        set_for_date[:data].each do |item|
          _push_to_elastic(item)
        end
      end
    end

    private

    # env                               index_name
    # production  ->             daily_figures|            merchant_order_stats
    # development -> development_daily_figures|development_merchant_order_stats
    # staging     ->     staging_daily_figures|    staging_merchant_order_stats
    # test        ->        test_daily_figures|       test_merchant_order_stats
    def _index_name
      ## TODO Change back after testing on prod
      return 'staging_' + report_type if Env.production?

      [Env.current, report_type].join('_')
    end

    def _push_to_elastic(item)
      puts "Publishing #{item}"
      post("#{elastic_url}/#{index_name}/_doc/", item.to_json, headers, proxy_url)
    end
  end
end
