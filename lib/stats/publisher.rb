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

#create the empty index
#curl -X PUT --user "elastic:ELASTIC_SEARCH_PASSWORD" -H "Content-Type: application/json" --data-binary {} http://ELASTIC_SEARCH_IP:9200/[index_name]
#send update the mappings using the daily_figures_mappings.json  file
# curl -X PUT --user "elastic:ELASTIC_SEARCH_PASSWORD" -H "Content-Type: application/json" --data-binary @merchant_income_mappings.json http://ELASTIC_SEARCH_IP:9200/index_name/_mapping

# curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary {} http://192.168.1.201:9200/staging_daily_figures
# curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary @daily_figures_mappings.json http://192.168.1.201:9200/staging_daily_figures/_mapping

# curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary {} http://192.168.1.201:9200/staging_merchant_order_stats
# curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary @merchant_order_stats_mappings.json http://192.168.1.201:9200/staging_merchant_order_stats/_mapping

# s = OpenStruct.new(proxy_url: 'http://10.10.0.103:3142', elastic: OpenStruct.new(url: "http://18.203.232.22:9200", credentials: "elastic:uIjXFICZh8pi2gZzeCWv" ) )

# class Env; class << self; def production?; true; end; end; end

# p = Stats::Publisher.new('daily_figures', [{data: ddd[0..3]}], s)
