FactoryBot.define do
  factory :shop do
    # merchant
    sequence(:name) { |n| "Shop #{n}" }
  end
end
