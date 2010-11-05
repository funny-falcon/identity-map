require File.dirname(__FILE__) + '/spec_helper'

describe "Customers" do
	
	before(:each) do
		ActiveRecord::Base.create_identity_map
	end
	
	it "should load the same model twice" do
		c1 = Customer.first
		c2 = Customer.first
		c1.__id__.should == c2.__id__
	end
    
  it "should fetch loaded model from cache" do
    c1 = Customer.first
    Customer.connection.should_not_receive(:select_all)
    c2 = Customer.find(c1.id)
  end
	
	it "should work for has_many associations" do
		p1 = PhoneNumber.first
		ps = Customer.first.phone_numbers
    p2 = ps.first
		p1.__id__.should == p2.__id__
	end
	
	it "should work for belongs_to assocations" do
		d1 = Customer.first
		p1 = PhoneNumber.first
    Customer.connection.should_not_receive(:select_all)
    d2 = p1.customer
		d1.__id__.should == d2.target.__id__
	end
    
  it "should fetch same model with not handled conditions" do
    d1 = Customer.first
    d2 = Customer.find(:first, :conditions=>["id = ?", d1.id])
    d1.__id__.should == d2.__id__
  end
  
  it "should refetch to fill missed attributes" do
    d1 = Customer.find(:first, :select => 'id, name')
    d1.read_attribute(:value).should be_nil
    d2 = Customer.find(d1.id)
    d2.__id__.should == d1.__id__
    d1.value.should_not be_nil
  end
	
  context "creation and deletion:" do
    before(:each) do
      @billy = Customer.create(:name => "billy")
    end
    
    it "should work for creating objects" do
      c2 = Customer.find_by_name("billy")
      @billy.__id__.should == c2.__id__
      Customer.connection.should_not_receive(:select_all)
      c3 = Customer.find(@billy.id)
      @billy.__id__.should == c3.__id__
    end

    it "should work for destroyed objects" do
      @billy.destroy
      c2 = Customer.find_by_id(@billy.id)
      c2.should be_nil
    end
    
    it "should reload adequatly" do
      Customer.connection.update_sql('update customers set value=2;')
      @billy.reload
      @billy.value.should == 2
    end
    
    it "should leave changed columns" do
      @billy.value = 3
      b = Customer.find_by_name("billy")
      b.value.should == 3
      b.value_changed?.should be_true
      b.changes.should == {'value'=>[1,3]}
      Customer.connection.update_sql('update customers set value=2;')
      b = Customer.find_by_name("billy")
      b.changes.should == {'value'=>[2,3]}
    end
    
    after(:each) do
      @billy.destroy unless @billy.destroyed?
    end
	end
    
  context "switching identity map:" do
    it "should disable id_map with `without_id_map`" do
      c1, c2, c3 = Customer.first, nil, nil
      Customer.without_id_map do
        c2 = Customer.first
        c3 = Customer.first
      end
      c1.__id__.should_not == c2.__id__
      c1.__id__.should_not == c3.__id__
      c3.__id__.should_not == c2.__id__
    end
    
    it "should use current id_map with `with_id_map(false)`" do
      c1, c2, c3 = Customer.first, nil, nil
      Customer.with_id_map(false) do
        c2 = Customer.first
        Customer.connection.should_not_receive(:select_all)
        c3 = Customer.find(c2.id)
      end
      c1.__id__.should == c2.__id__
      c1.__id__.should == c3.__id__
      c3.__id__.should == c2.__id__
    end
    
    it "should create new id_map with `with_id_map`" do
      c1, c2, c3 = Customer.first, nil, nil
      Customer.with_id_map do
        c2 = Customer.first
        Customer.connection.should_not_receive(:select_all)
        c3 = Customer.find(c2.id)
      end
      c1.__id__.should_not == c2.__id__
      c1.__id__.should_not == c3.__id__
      c3.__id__.should == c2.__id__
    end
    
    it "should reenable id_map with `with_id_map`" do
      c1, c2, c3 = Customer.first, nil, nil
      Customer.without_id_map do
        Customer.with_id_map do
          c2 = Customer.first
          Customer.connection.should_not_receive(:select_all)
          c3 = Customer.find(c2.id)
        end
      end
      c1.__id__.should_not == c2.__id__
      c1.__id__.should_not == c3.__id__
      c3.__id__.should == c2.__id__
    end
  end
  
  context "has and belongs to many" do
    before(:each) do
      gotwo = Building.create(:name=>'GoTwo')
      Address.find(:all).each do |address|
        gotwo.addresses << address
      end
    end
    
    it "should load habtm adequatly" do
      buildings = Building.find(:all, :include=>:addresses)
      buildings[0].addresses.loaded?.should be_true
      buildings[0].addresses.to_a.size.should == 2
      buildings[1].addresses.loaded?.should be_true
      buildings[1].addresses.to_a.size.should == 2
    end
  end
    
	after(:each) do
		ActiveRecord::Base.drop_identity_map
	end
	
end
