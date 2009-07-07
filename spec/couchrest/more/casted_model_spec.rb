require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require File.join(FIXTURE_PATH, 'more', 'card')

class WithCastedModelMixin < Hash
  include CouchRest::CastedModel
  include CouchRest::Parent
  property :name
end

class DummyModel < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  raise "Default DB not set" if TEST_SERVER.default_database.nil?
  property :casted_attribute, :cast_as => 'WithCastedModelMixin'
  property :keywords,         :cast_as => ["String"]
  property :subs,             :cast_as => ["WithCastedModelMixin"], :default => lambda { CouchRest::Array.new() }
end

describe CouchRest::CastedModel do
  
  describe "A non hash class including CastedModel" do
    it "should fail raising and include error" do
      lambda do
        class NotAHashButWithCastedModelMixin
          include CouchRest::CastedModel
          property :name
        end
        
      end.should raise_error
    end
  end
  
  describe "isolated" do
    before(:each) do
      @obj = WithCastedModelMixin.new
    end
    it "should automatically include the property mixin and define getters and setters" do
      @obj.name = 'Matt'
      @obj.name.should == 'Matt' 
    end
  end
  
  describe "casted as attribute" do
    before(:each) do
      @obj = DummyModel.new(:casted_attribute => {:name => 'whatever'})
      @obj.subs.push(WithCastedModelMixin.new())
      @obj.subs << WithCastedModelMixin.new()
      @casted_obj = @obj.casted_attribute
    end
    
    it "should be available from its parent" do
      @casted_obj.should be_an_instance_of(WithCastedModelMixin)
    end
    
    it "should have the getters defined" do
      @casted_obj.name.should == 'whatever'
    end
    
    it "should know who casted it" do
      @casted_obj.casted_by.should == @obj
    end

    it "should know as typ of CouchRest::Array" do
      @obj.subs.should be_a_kind_of(CouchRest::Array)
    end

    it "should have a parent" do
      @obj.subs.parent.should be_a_kind_of(DummyModel)
    end

    it "should have a document" do
      @obj.subs.document.should be_a_kind_of(DummyModel)
    end

    it "should have a document on subs item" do
      @obj.subs[0].document.should be_a_kind_of(DummyModel)
      @obj.subs[1].document.should be_a_kind_of(DummyModel)
    end

    it "should have a parent on subs item" do
      @obj.subs[0].parent.should be_a_kind_of(CouchRest::Array)
      @obj.subs[1].parent.should be_a_kind_of(CouchRest::Array)
    end

  end
  
  describe "casted as an array of a different type" do
    before(:each) do
      @obj = DummyModel.new(:keywords => ['couch', 'sofa', 'relax', 'canapé'])
    end
    
    it "should cast the array propery" do
      @obj.keywords.should be_an_kind_of(Array)
      @obj.keywords.first.should == 'couch'
    end
    
  end
  
  describe "saved document with casted models" do
    before(:each) do
      reset_test_db!
      @obj = DummyModel.new(:casted_attribute => {:name => 'whatever'})
      @obj.save.should be_true
      @obj = DummyModel.get(@obj.id)
    end
    
    it "should be able to load with the casted models" do
      casted_obj = @obj.casted_attribute
      casted_obj.should_not be_nil
      casted_obj.should be_an_instance_of(WithCastedModelMixin)
    end
    
    it "should have defined getters for the casted model" do
      casted_obj = @obj.casted_attribute
      casted_obj.name.should == "whatever"
    end
    
    it "should have defined setters for the casted model" do
      casted_obj = @obj.casted_attribute
      casted_obj.name = "test"
      casted_obj.name.should == "test"
    end
    
  end
  
end
