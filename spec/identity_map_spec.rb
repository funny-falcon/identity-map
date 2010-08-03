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
	
    describe "creation and deletion:" do
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
        
        after(:each) do
            @billy.destroy unless @billy.destroyed?
        end
	end
    
    describe "switching identity map:" do
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
    
	after(:each) do
		ActiveRecord::Base.drop_identity_map
	end
	
end
