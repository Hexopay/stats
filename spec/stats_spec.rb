# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

describe Stats do
  let(:brand) { OpenStruct.new(:name => 'master') }
  let!(:merchant1) { OpenStruct.new(:name => 'merchant 1') }
  let!(:gateway) do
    OpenStruct.new(
      id: 1,
      enabled: true,
      supported_currencies: ['USD'],
      brands: [brand])
  end
  let!(:gateway2) do
    OpenStruct.new(
      id: 2,
      enabled: true,
      supported_currencies: ['USD'],
      brands: [brand])
  end
  let!(:gateways) { Collection.new([gateway, gateway2]) }
  let!(:shop) { OpenStruct.new(id: 1, gateways: gateways, smart_routing_version: 1) }
  # let!(:key) { "test_gateways:shop:#{shop.id}" }
  class Collection
    include Enumerable

    def initialize(items)
      @items = items
    end

    def each(&block)
      @items.each(&block)
    end

    def shuffle
      @items.sort
    end
  end

  class Storage
    def rpush(key, value=[]); end
    def lrange(key, start_index, end_index); end
    def lpop(key); end
  end

  let!(:storage) { Storage.new }
  let(:main) { ::Stats::Main.new }
  let(:report_type_1) { 'daily_figures' }
  let(:report_type_2) { 'merchant_order_stats' }
  let(:main_2) { ::Stats::Main.new(report_type: 'merchant_order_stats', period: 'date=2025-04-16') }
  describe '#main' do
    it 'initialize with default params' do
      expect(main.report_type).to eq('daily_figures')
      expect(main.dates).to eq([Date.yesterday])
    end

    it 'initialize with merchant_order_stats' do
      expect(main_2.report_type).to eq(report_type_2)
      expect(main_2.dates).to eq([Date.parse('2025-04-16')])
    end
  end
end
