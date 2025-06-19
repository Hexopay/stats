# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'digest'

RSpec.describe Stats::Publisher do
  let(:mock_settings) do
    double(
      'Settings',
      elastic: double(
        url: 'http://elastic.example.com',
        credentials: 'user:password'
      ),
      proxy_url: 'http://proxy.example.com'
    )
  end
  let(:report_type) { 'daily_figures' }
  let(:sample_data) do
    [
      {
        data: [
          {
            back_office_merchant_id: 1,
            back_office_shop_id: 2,
            gateway: 'test_gateway',
            status: 'success',
            country: 'US',
            currency: 'USD',
            transaction_type: 'sale',
            time_series: '2023-01-01',
            created_at: '2023-01-01'
          }
        ]
      }
    ]
  end

  subject { described_class.new(report_type, sample_data, mock_settings) }

  before do
    allow(Stats::Env).to receive(:production?).and_return(false)
    allow(Stats::Env).to receive(:current).and_return('test')
    allow(subject).to receive(:post).and_return(true)
    allow(subject).to receive(:log).and_return(true)
  end

  describe '#initialize' do
    it 'sets instance variables correctly' do
      expect(subject.data).to eq(sample_data)
      expect(subject.report_type).to eq(report_type)
      expect(subject.elastic_url).to eq('http://elastic.example.com')
      expect(subject.proxy_url).to eq('http://proxy.example.com')
      expect(subject.headers).to include(
        'Content-Type' => 'application/json',
        'Authorization' => /^Basic /
      )
    end

    it 'generates correct authorization header' do
      encoded = Base64.strict_encode64('user:password')
      expect(subject.headers['Authorization']).to eq("Basic #{encoded}")
    end
  end

  describe '#publish' do
    it 'calls _push_to_elastic for each item' do
      expect(subject).to receive(:_push_to_elastic).once
      subject.publish
    end

    context 'with multiple items' do
      let(:sample_data) do
        [
          {
            data: [
              { created_at: '2023-01-01', gateway: 'gw1' },
              { created_at: '2023-01-02', gateway: 'gw2' }
            ]
          }
        ]
      end

      it 'calls _push_to_elastic for each item' do
        expect(subject).to receive(:_push_to_elastic).twice
        subject.publish
      end
    end

    context 'in production' do
      before do
        allow(Stats::Env).to receive(:production?).and_return(true)
        # Вместо мока Kernel.sleep будем проверять через allow_any_instance_of
        allow_any_instance_of(described_class).to receive(:sleep)
      end

      it 'sleeps between publishing' do
        subject.publish
        expect(subject).to have_received(:sleep).with(0.1).exactly(1).times
      end
    end

    context 'not in production' do
      before do
        allow(Stats::Env).to receive(:production?).and_return(false)
        allow_any_instance_of(described_class).to receive(:sleep)
      end

      it 'does not sleep between publishing' do
        subject.publish
        expect(subject).to have_received(:sleep).with(0).exactly(1).times
      end
    end
  end

  describe '#_index_name' do
    context 'when not in production' do
      it 'returns prefixed index name' do
        expect(subject.send(:_index_name)).to eq('test_daily_figures')
      end
    end

    context 'when in production' do
      before { allow(Stats::Env).to receive(:production?).and_return(true) }

      it 'returns non-prefixed index name' do
        expect(subject.send(:_index_name)).to eq('staging_daily_figures')
      end
    end
  end

  describe '#_unique_id_bits' do
    let(:item) do
      {
        back_office_merchant_id: 1,
        back_office_shop_id: 2,
        gateway: 'gw1',
        status: 'success',
        country: 'US',
        currency: 'USD',
        transaction_type: 'sale',
        time_series: '2023-01-01',
        extra_field: 'ignored'
      }
    end

    it 'returns correct bits for daily_figures' do
      expect(subject.send(:_unique_id_bits, item)).to eq('1-2-gw1-success-US-USD-sale-2023-01-01')
    end

    context 'with merchant_order_stats report type' do
      let(:report_type) { 'merchant_order_stats' }
      let(:item) do
        {
          merchant: 'm1',
          gateway: 'gw1',
          status: 'success',
          time_series: '2023-01-01',
          extra_field: 'ignored'
        }
      end

      it 'returns correct bits for merchant_order_stats' do
        expect(subject.send(:_unique_id_bits, item)).to eq('m1-gw1-success-2023-01-01')
      end
    end
  end

  describe '#_unique_id' do
    let(:item) do
      {
        created_at: '2023-01-01',
        back_office_merchant_id: 1,
        back_office_shop_id: 2,
        gateway: 'gw1'
      }
    end

    it 'returns MD5 hash of unique bits prefixed with created_at' do
      unique_bits = subject.send(:_unique_id_bits, item)
      expected_hash = Digest::MD5.hexdigest(unique_bits)
      expect(subject.send(:_unique_id, item)).to eq("2023-01-01-#{expected_hash}")
    end
  end

  describe '#_push_to_elastic' do
    let(:item) { { created_at: '2023-01-01', gateway: 'gw1' } }

    it 'calls post with correct parameters' do
      doc_id = subject.send(:_unique_id, item)
      expected_url = "http://elastic.example.com/test_daily_figures/_doc/#{doc_id}"

      expect(subject).to receive(:post).with(
        expected_url,
        item.to_json,
        subject.headers,
        'http://proxy.example.com'
      )

      subject.send(:_push_to_elastic, item)
    end

    it 'logs the publishing action' do
      expect(subject).to receive(:log).with(/Publishing/)
      subject.send(:_push_to_elastic, item)
    end
  end
end
