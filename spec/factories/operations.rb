FactoryBot.define do
  factory :operation do
    merchant
    shop
    status { 'completed' }
    country { 'US' }
    currency { 'USD' }
    gateway_type { 'Gateway::Stripe' }
    transaction_type { 'Transaction::Sale' }
    transaction_id { rand(Time.now.to_i) }
    amount { 1000 }
    eur_amount { 850 }
    gbp_amount { 750 }
    created_at { Date.current }
    generated_at { Time.current.utc }
    paid_at { Time.current.utc }
  end
end
