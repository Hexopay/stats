# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Stats::Loader::MerchantOrderStats do
  let(:date) { Date.current }
  let(:stats_loader) { described_class.new(date) }

  # Mock data
  let(:merchant1) { create :merchant, company_name: 'c1', id: 1 }
  let(:merchant2) { create :merchant, company_name: 'c2', id: 2 }
  let(:merchant_test) { create :merchant, company_name: 'test', id: 3 }
  let(:gateway1) { create :gateway, type: 'Gateway::Stripe', id: 1 }
  let(:gateway2) { create :gateway, type: 'Gateway::Paypal', id: 2 }
  let(:shop1) { create :shop, merchant: merchant1 }
  let(:shop2) { create :shop, merchant: merchant2 }
  let(:shop_test) { create :shop, merchant: merchant_test }

  let(:order1) { create :order, gateway: gateway1, shop: shop1, test: false }
  let(:order2) { create :order, gateway: gateway2, shop: shop2, test: false }
  let(:order_test) { create :order, gateway: gateway1, shop: shop_test, test: true }

  let(:transaction1) { create :transaction, status: 'successful', order: order1, paid_at: date.beginning_of_day }
  let(:transaction2) { create :transaction, status: 'failed', order: order1, paid_at: date.beginning_of_day }
  let(:transaction3) { create :transaction, status: 'pending', order: order2, paid_at: date.beginning_of_day }
  let(:transaction4) { create :transaction, status: 'completed', order: order2, paid_at: date.beginning_of_day }
  let(:transaction_test) { create :transaction, status: 'successful', order: order_test }
  let(:arr) { [transaction1, transaction2, transaction3, transaction4] }
  let(:arr_test) { [transaction_test] }

  before do
    transaction1
    transaction2
    transaction3
    transaction4
    transaction_test
  end

  describe '#initialize' do
    it 'initializes with a date' do
      expect(stats_loader.date).to eq(date)
    end
  end

  describe '#load_for_date' do
    context 'with transactions' do
      it 'returns stats for all combinations except All merchants + All gateways' do
        result = stats_loader.load_for_date

        expect(result).to be_an(Array)
        # Expected combinations:
        # merchants with All gateways not included in tesult
        # 2 gateways with All merchants (5 statuses each) = 10
        # 4 merchant+gateway combinations (5 statuses each) = 20
        # Total = 40 minus any with zero counts
        expect(result.size).to be > 0

        # Verify All merchants + All gateways is present
        all_all = result.find { |r| r[:merchant] == 'All' && r[:gateway] == '' }
        expect(all_all).to_not be_empty

        # Check merchant-specific not included
        merchant1_all = result.find { |r| r[:merchant] == 'c1' && r[:gateway] == '' }
        expect(merchant1_all).to be_nil

        # Check gateway-specific
        all_gateway2 = result.find { |r| r[:merchant] == 'All' && r[:gateway] == 'Paypal' }
        expect(all_gateway2[:count]).to eq(2)

        # Check merchant+gateway specific
        merchant1_gateway1 = result.find { |r| r[:merchant] == 'c1' && r[:gateway] == 'Stripe' }
        expect(merchant1_gateway1[:count]).to eq(2)

        merchant2_gateway2 = result.find { |r| r[:merchant] == 'c2' && r[:gateway] == 'Paypal' }
        expect(merchant2_gateway2[:count]).to eq(2)
      end

      it 'excludes test transactions' do
        result = stats_loader.load_for_date
        merchant_test = result.find { |r| r[:merchant] == 'test' && r[:gateway] == 'Stripe' }
        expect(merchant_test).to be_nil
      end
    end

    context 'with no transactions' do
      before do
        allow(stats_loader).to receive(:_load_transactions).and_return([])
      end

      it 'returns empty array' do
        expect(stats_loader.load_for_date).to eq([])
      end
    end
  end

  describe 'private methods' do
    before do
      stats_loader.load_for_date
    end

    describe '#_merchants' do
      it 'returns unique merchants' do
        expect(stats_loader.merchants).to contain_exactly(
          { name: 'c1', id: 1 },
          { name: 'c2', id: 2 }
        )
      end
    end

    describe '#_gateways' do
      it 'returns unique gateways' do
        expect(stats_loader.gateways).to contain_exactly(
          { name: 'Stripe', id: 1 },
          { name: 'Paypal', id: 2 }
        )
      end
    end

    describe '#_filter_transactions' do
      it 'filters by merchant' do
        merchant = { name: 'c1', id: 1 }
        gateway = described_class::ALL_GATEWAY
        filtered = stats_loader.send(:_filter_transactions, merchant, gateway)
        expect(filtered).to contain_exactly(transaction1, transaction2)
      end

      it 'filters by gateway' do
        merchant = described_class::ALL_MERCHANT
        gateway = { name: 'Paypal', id: 2 }
        filtered = stats_loader.send(:_filter_transactions, merchant, gateway)
        expect(filtered).to contain_exactly(transaction3, transaction4)
      end

      it 'filters by both merchant and gateway' do
        merchant = { name: 'c1', id: 1 }
        gateway = { name: 'Stripe', id: 1 }
        filtered = stats_loader.send(:_filter_transactions, merchant, gateway)
        expect(filtered).to contain_exactly(transaction1, transaction2)
      end
    end

    describe '#_build_combinations' do
      it 'builds stats for all statuses' do
        merchant = described_class::ALL_MERCHANT
        gateway = { name: 'Paypal', id: 2 }
        combinations = stats_loader.send(:_build_combinations, merchant, gateway)

        expect(combinations.size).to eq(2) # pending, completed, All (assuming successful/failed are 0)
        expect(combinations.map { |c| c[:status] }).to include('pending', 'All')
      end

      it 'calculates correct percentages' do
        merchant = { name: 'c1', id: 1 }
        gateway = described_class::ALL_GATEWAY
        combinations = stats_loader.send(:_build_combinations, merchant, gateway)

        success = combinations.find { |c| c[:status] == 'success' }
        expect(success[:percentage]).to eq(50.0) # 1 of 2
      end
    end
  end
end
