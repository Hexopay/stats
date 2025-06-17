# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Stats::Loader::DailyFigures do
  let(:merchant) { FactoryBot.create :merchant }
  let(:shop) { FactoryBot.create :shop, merchant: }
  let!(:operation) { FactoryBot.create(:operation, merchant:, shop:) }
  let!(:operation1) { FactoryBot.create(:operation, merchant:, shop:) }
  let(:date) { Date.current }
  let(:daily_figures) { described_class.new(date) }
  let(:date_in_past) { Date.current - 10.days }
  let(:daily_figures_in_past) { described_class.new(date_in_past) }

  describe '#load_for_date' do
    context 'when operations exist' do
      it 'returns operation data with correct structure' do
        result = daily_figures.load_for_date
        expect(result).to be_an(Array)
        expect(result).not_to be_empty
        expect(result).to eq(
          [{
            merchant: merchant.company_name,
            back_office_merchant_id: merchant.id.to_s,
            shop: shop.name,
            back_office_shop_id: shop.id.to_s,
            gateway: 'Stripe',
            status: 'Completed',
            country: 'US',
            currency: 'USD',
            transaction_type: 'Sale',

            created_at: Date.current.strftime('%Y-%m-%d'),
            export_time: result.first[:export_time],
            card: '',
            volume: 20.0,
            volume_eur: 17.0,
            volume_gbp: 15.0,
            count: 2
          }]
        )
      end
    end

    context 'when no operations exist' do
      it 'returns an empty Array' do
        expect(daily_figures_in_past.load_for_date).to eq([])
      end
    end
  end
end
