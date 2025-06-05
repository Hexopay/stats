# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Stats::Loader::DailyFigures do
  let(:date) { Date.new(2023, 1, 1) }
  let(:daily_figures) { described_class.new(date) }

  # Stub для Operation
  let(:operation_stub) do
    double('Operation').tap do |op|
      allow(op).to receive(:joins).with(:merchant, :shop).and_return(op)
      allow(op).to receive(:select).and_return(op)
      allow(op).to receive(:where).with(created_at: date).and_return(op)
      allow(op).to receive(:group).and_return(op)
      allow(op).to receive(:to_a).and_return(op)
      allow(op).to receive(:map).and_return(operation_data)
      allow(op).to receive(:each_slice).with(500).and_return(operation_data)
    end
  end

  before do
    stub_const('Operation', operation_stub)
  end

  describe '#load_for_date' do
    context 'when operations exist' do
      let(:operation_data) do
        [
          {
            created_at: '2023-01-01',
            card: '',
            back_office_merchant_id: 1,
            merchant: 'Test Merchant',
            back_office_shop_id: 1,
            shop: 'Test Shop',
            status: 'Completed',
            country: 'US',
            currency: 'USD',
            gateway: 'Stripe',
            transaction_type: 'Sale',
            export_time: Time.now,
            count: 2,
            total_amount: '30.0',
            total_eur_amount: '25.5',
            total_gbp_amount: '22.5'
          }
        ]
      end

      before do
        allow(operation_stub).to receive(:map).and_return(operation_data)
      end

      it 'returns an Array' do
        expect(daily_figures.load_for_date).to be_an(Array)
      end

      it 'returns non-empty array when operations exist' do
        expect(daily_figures.load_for_date).not_to be_empty
      end

      it 'returns operation data with correct structure' do
        result = daily_figures.load_for_date.first
        expect(result).to eq({
          merchant: 'Test Merchant',
          back_office_merchant_id: 1,
          shop: 'Test Shop',
          back_office_shop_id: 1,
          gateway: 'Stripe',
          status: 'Completed',
          country: 'US',
          currency: 'USD',
          transaction_type: 'Sale',
          created_at: '2023-01-01',
          export_time: result[:export_time],
          card: '',
          total_amount: '30.0',
          total_eur_amount: '25.5',
          total_gbp_amount: '22.5',
          count: 2
        })
      end
    end

    context 'when no operations exist' do
      let(:operation_data) {[]}
      it 'returns an empty Array' do
        expect(daily_figures.load_for_date).to eq([])
      end
    end
  end
end
