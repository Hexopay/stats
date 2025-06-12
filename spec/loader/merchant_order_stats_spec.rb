# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Stats::Loader::MerchantOrderStats do
  let(:date) { Date.current }
  let(:stats_loader) { described_class.new(date) }

  # Mock data
  let(:merchant1) { create :merchant, company_name: 'c1' }
  let(:merchant2) { create :merchant, company_name: 'c2' }
  let(:gateway2) { create :gateway, type: 'Gateway::Paypal' }
  let(:gateway1) { create :gateway, type: 'Gateway::Stripe' }
  let(:shop1) { create :shop, merchant: merchant1 }
  let(:shop2) { create :shop, merchant: merchant2 }

  let(:order1) { create :order, gateway: gateway1, shop: shop1, test: false }
  let(:order2) { create :order, gateway: gateway2, shop: shop2, test: false }
  let(:order_test) { create :order, gateway: gateway1, shop: shop1, test: true }

  let(:transaction1) { create :transaction, status: 'successful', order: order1 }
  let(:transaction2) { create :transaction, status: 'failed', order: order1 }
  let(:transaction3) { create :transaction, status: 'pending', order: order2 }
  let(:transaction4) { create :transaction, status: 'completed', order: order2 }
  let(:transaction_test) { create :transaction, status: 'successful', order: order_test }
  let(:arr) { [transaction1, transaction2, transaction3] }
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
      it 'returns stats for all combinations' do
        result = stats_loader.load_for_date

        expect(result).to be_an(Array)
        expect(result.size).to eq(19) # 5 statuses * (1 All + 2 merchants + 2 gateways + 4 combinations) - those_with_count_0

        # Check All merchants + All gateways
        all_all = result.find { |r| r[:merchant] == 'All' && r[:gateway] == '' }
        expect(all_all[:count]).to eq(4)

        # Check merchant-specific
        merchant1_all = result.find { |r| r[:merchant] == 'c1' && r[:gateway] == '' }
        expect(merchant1_all[:count]).to eq(2)

        # Check gateway-specific
        all_gateway2 = result.find { |r| r[:merchant] == 'All' && r[:gateway] == 'Paypal' }
        expect(all_gateway2[:count]).to eq(2)

        # Check merchant+gateway specific
        merchant1_gateway1 = result.find { |r| r[:merchant] == 'c1' && r[:gateway] == 'Stripe' }
        expect(merchant1_gateway1[:count]).to eq(2)

        merchant2_gateway2 = result.find { |r| r[:merchant] == 'c2' && r[:gateway] == 'Paypal' }
        expect(merchant1_gateway1[:count]).to eq(2)
      end

      it 'excludes test transactions' do
        allow(stats_loader).to receive(:_load_transactions).and_return(arr_test)
        result = stats_loader.load_for_date
        expect(result.any? { |r| r[:count] == 2 }).to be false
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
      stats_loader.send(:_load_transactions)
    end

    describe '#_merchants' do
      it 'returns unique merchants' do
        merchants = stats_loader.send(:_merchants)
        expect(merchants).to contain_exactly(
          { name: 'Merchant 1', id: 1 },
          { name: 'Merchant 2', id: 2 }
        )
      end
    end

    describe '#_gateways' do
      it 'returns unique gateways' do
        gateways = stats_loader.send(:_gateways)
        expect(gateways).to contain_exactly(
          { name: 'Stripe', id: 1 },
          { name: 'Paypal', id: 2 }
        )
      end
    end

    describe '#_filter_transactions' do
      it 'filters by merchant' do
        merchant = { name: 'Merchant 1', id: 1 }
        gateway = described_class::ALL_GATEWAY
        filtered = stats_loader.send(:_filter_transactions, merchant, gateway)
        expect(filtered).to eq([transaction1, transaction3])
      end

      it 'filters by gateway' do
        merchant = described_class::ALL_MERCHANT
        gateway = { name: 'Paypal', id: 2 }
        filtered = stats_loader.send(:_filter_transactions, merchant, gateway)
        expect(filtered).to eq([transaction2])
      end

      it 'filters by both merchant and gateway' do
        merchant = { name: 'Merchant 1', id: 1 }
        gateway = { name: 'Stripe', id: 1 }
        filtered = stats_loader.send(:_filter_transactions, merchant, gateway)
        expect(filtered).to eq([transaction1, transaction3])
      end
    end

    describe '#_build_combinations' do
      it 'builds stats for all statuses' do
        merchant = described_class::ALL_MERCHANT
        gateway = described_class::ALL_GATEWAY
        combinations = stats_loader.send(:_build_combinations, merchant, gateway)

        expect(combinations.size).to eq(4) # All statuses except zero counts
        expect(combinations.map { |c| c[:status] }).to contain_exactly('success', 'failed', 'pending', 'All')
      end

      it 'calculates correct percentages' do
        merchant = { name: 'Merchant 1', id: 1 }
        gateway = described_class::ALL_GATEWAY
        combinations = stats_loader.send(:_build_combinations, merchant, gateway)

        success = combinations.find { |c| c[:status] == 'success' }
        expect(success[:percentage]).to eq(50.0) # 1 of 2
      end
    end
  end
end
