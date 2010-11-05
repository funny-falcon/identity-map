require 'rubygems'
begin
  require 'spec'
rescue LoadError
  require 'rspec'
end
require 'active_support'
require 'active_support/test_case'
require 'active_record'
begin
    require 'active_record/railtie'
rescue MissingSourceFile
end
require 'active_record/test_case'
require 'action_controller'
require 'action_view'
require 'identity_map'

#ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Base.establish_connection(
    :adapter=>'sqlite3',
    :database=>'spec/identity_map.test.sqlite3'
)

ActiveRecord::Schema.define(:version => 0) do
  puts "Creating Schema"
  create_table :customers, :force => true do |t|
    t.string :name
    t.integer :value, :default=>1
  end
  create_table :phone_numbers, :force => true do |t|
    t.string :number
    t.references :customer
  end
  create_table :buildings, :force => true do |t|
    t.string :name
  end
  create_table :addresses, :force => true do |t|
    t.string :name
  end
  create_table :addresses_buildings, :force => true, :id => false do |t|
    t.references :building
    t.references :address
  end
end

class Customer < ActiveRecord::Base
  use_id_map
  has_many :phone_numbers
end

customer = Customer.create(:name => "Boneman")

class PhoneNumber < ActiveRecord::Base
  use_id_map
  belongs_to :customer
end

phone_number = customer.phone_numbers.create(:number => "8675309")

class Building < ActiveRecord::Base
  use_id_map
  has_and_belongs_to_many :addresses
end

building = Building.create(:name => 'GoOne')

class Address < ActiveRecord::Base
  use_id_map
  has_and_belongs_to_many :customers
end

address1 = Address.create(:name=>'volga')
address2 = Address.create(:name=>'don')
building.addresses << address1
building.addresses << address2
