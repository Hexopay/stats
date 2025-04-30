# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/stats'
require 'ostruct'

describe Stats do
  allow(Stats::Env::Rails).to_receive(:env).and_return('test')
  let(:brand) { OpenStruct.new(:name => 'master') }
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
  let!(:key) { "test_gateways:shop:#{shop.id}" }
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
  describe '#gateway' do
    context 'when ask for one' do
      let(:gateway_ids) { [gateway.id] }
      it 'returns one gateway from one' do
        allow(
          storage
        ).to receive(:rpush).and_return(1)
        allow(
          storage
        ).to receive(:lrange).and_return([gateway.id])
        allow(
          storage
        ).to receive(:lpop).and_return(gateway.id)
        allow(
          storage
        ).to receive(:rpush).and_return(1)

        expect(SmartRouting.get_gateway(
                 shop: shop,
                 storage: storage,
                 key: key,
                 gateways: gateways
               )).to eq gateway
      end

      let(:gateway_ids_3) { [gateway.id] }

      it 'returns one gateway if storage initially not empty' do
        allow(
          storage
        ).to receive(:rpush).with(key, gateway_ids_3).and_return(1)
        allow(
          storage
        ).to receive(:lrange).with(key, 0, -1).and_return(gateway_ids_3)
        allow(
          storage
        ).to receive(:lpop).with(key).and_return(gateway.id)

        expect(SmartRouting.get_gateway(
                 shop: shop,
                 storage: storage,
                 key: key,
                 gateways: gateways
               )).to be_included_in shop.gateways
      end

      let(:gateway_ids_shuffled) { [gateway.id, gateway2.id].shuffle }

      it 'returns one gateway if storage initialy empty' do
        allow(storage).to receive(:rpush).and_return(1)
        allow(
          storage
        ).to receive(:lrange).with(key, 0, -1).and_return([])
        allow(
          storage
        ).to receive(:lpop).with(key).and_return(gateway.id)
        expect(SmartRouting.get_gateway(
                 shop: shop,
                 storage: storage,
                 key: key,
                 gateways: gateways
               )).to be_included_in shop.gateways
      end
      it 'raises KeyError if :gateways did not supplied' do
        expect do
          SmartRouting.get_gateway(
            shop: shop,
            storage: storage,
            key: key
            # gateways: gateways ##LEAVE HERE commnted line for documentation purpose
          )
        end .to raise_error KeyError, /Gateways/
      end
      it 'raises KeyError if :shop did not supplied' do
        expect do
          SmartRouting.get_gateway(
            refresh: true,
            # shop: shop,  ##LEAVE HERE commented line for documentation purpose
            storage: storage,
            key: key,
            gateways: gateways
          )
        end .to raise_error KeyError, /Shop/
      end
    end
  end
end
