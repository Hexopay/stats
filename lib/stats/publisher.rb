# frozen_string_literal: true

require_relative 'http_helper'

module Stats
  class Publisher
    include HttpHelper
    include Logger
    attr_reader :data, :report_type, :index_name, :settings, :elastic_url, :proxy_url, :headers

    FIELDS_FOR_UNIQ_ID_BITS = {
      daily_figures: %i[
        back_office_merchant_id
        back_office_shop_id
        gateway
        status
        country
        currency
        transaction_type
        time_series
      ],
      merchant_order_stats: %i[
        merchant
        gateway
        status
        time_series
      ]
    }

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
          sleep(publishing_timeout)
        end
      end
    end

    def publishing_timeout
      Env.production? ? 0.1 : 0
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

    def _unique_id_bits(item)
      FIELDS_FOR_UNIQ_ID_BITS[report_type.to_sym].map do |field_name|
        item[field_name]
      end.join('-')
    end

    def _unique_id(item)
      "#{item[:created_at]}-#{Digest::MD5.hexdigest _unique_id_bits(item)}"
    end

    def _push_to_elastic(item)
      doc_id = _unique_id(item)
      log("Publishing [id:#{doc_id}] #{item}")
      post("#{elastic_url}/#{index_name}/_doc/#{doc_id}", item.to_json, headers, proxy_url)
    end
  end
end
