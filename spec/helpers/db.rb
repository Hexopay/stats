require 'active_record'

class Operation < ActiveRecord::Base
  self.table_name = :hexo_operations
  belongs_to :shop
  belongs_to :merchant
  belongs_to :gateway
  belongs_to :financial_transaction, class_name: "Transaction::Base", foreign_key: "transaction_id", optional: true
end

class Merchant < ActiveRecord::Base
  has_many :operations
  has_many :shops
end

class Shop < ActiveRecord::Base
  has_many :operations
  belongs_to :merchant
  has_many :orders
end

module Transaction
  class Base < ActiveRecord::Base
    self.table_name = :hexo_transactions
    has_one :operation
    belongs_to :order
  end

  class Authorization < Base
  end
end

class Order < ActiveRecord::Base
  self.table_name = :hexo_orders
  belongs_to :shop
  # belongs_to :payment_method,  polymorphic: true,
  #                              autosave: true,
  #                              dependent: :destroy,
  #                              optional: true
  belongs_to :gateway, optional: true
  has_one    :merchant, through: :shop
end

class Gateway < ActiveRecord::Base
  has_many :operations
  has_many :merchants
  self.inheritance_column = nil
end
class Paypal < Gateway; end
class Stripe < Gateway; end

ActiveRecord::Base.establish_connection(
  advisory_locks: false,
  adapter: 'postgresql',
  encoding: 'unicode',
  host: 'localhost',
  pool: 5,
  username: 'postgres',
  password: '',
  database: 'wls_test'
)
