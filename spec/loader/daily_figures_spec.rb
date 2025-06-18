# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Stats::Loader::DailyFigures do
  let(:merchant1) { create :merchant, company_name: 'c1', id: 1 }
  let(:merchant2) { create :merchant, company_name: 'c2', id: 2 }
  let(:merchant_test) { create :merchant, company_name: 'test', id: 3 }
  let(:gateway1) { create :gateway, type: 'Gateway::Stripe', id: 1 }
  let(:gateway2) { create :gateway, type: 'Gateway::Paypal', id: 2 }
  let(:shop1) { create :shop, merchant: merchant1 }
  let(:shop2) { create :shop, merchant: merchant2 }

  let(:merchant) { FactoryBot.create :merchant, id: 4 }
  let(:shop) { FactoryBot.create :shop, merchant: }
  let!(:operation) { FactoryBot.create(:operation, merchant:, shop:) }
  let!(:operation1) { FactoryBot.create(:operation, merchant:, shop:) }
  let(:date) { Date.current }
  let(:daily_figures) { described_class.new(date) }
  let(:date_in_past) { Date.current - 10.days }
  let(:daily_figures_in_past) { described_class.new(date_in_past) }
    let(:tr_data) {
    [
      {
        "merchant_id" => merchant1.id,
        "shop_id" => shop1.id,
        "gateway_type" => gateway1.type,
        "country" => 'US',
        "currency" => "USD",
        "transaction_type" => "Transaction::Sale",
        "status" => "Completed",
        "count" => 2,
        "volume" => 2000,
        "volume_eur" => 1700,
        "volume_gbp" => 1500,
        "company_name" => merchant1.company_name,
        "shop_name" => shop1.name
      },
      {
        "merchant_id" => merchant1.id,
        "shop_id" => shop1.id,
        "gateway_type" => gateway2.type,
        "country" => nil,
        "currency" => "USD",
        "transaction_type" => "Transaction::Payment",
        "status" => "successful",
        "count" => 2,
        "volume" => 2000,
        "volume_eur" => 1700,
        "volume_gbp" => 1500,
        "company_name" => merchant1.company_name,
        "shop_name" => shop1.name
      },
      {
        "merchant_id" => merchant2.id,
        "shop_id" => shop1.id,
        "gateway_type" => gateway2.type,
        "country" => nil,
        "currency" => "USD",
        "transaction_type" => "Transaction::Payment",
        "status" => "successful",
        "count" => 2,
        "volume" => 2000,
        "volume_eur" => 1700,
        "volume_gbp" => 1500,
        "company_name" => merchant2.company_name,
        "shop_name" => shop2.name
      }
    ]
  }

  describe '#load_for_date' do
    context 'when operations exist' do
      before do
        allow(daily_figures).to receive(:_load_transactions).and_return(tr_data)
      end

      it 'returns operation data with correct structure' do
        result = daily_figures.load_for_date
        expect(result).to be_an(Array)
        expect(result).not_to be_empty
        expect(result.first).to eq(
          {
            merchant: merchant1.company_name,
            back_office_merchant_id: merchant1.id.to_s,
            shop: shop1.name,
            back_office_shop_id: shop1.id.to_s,
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
          }
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
