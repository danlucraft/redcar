require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plist do
  before(:each) do
    create_fixtures
    @xml   = File.new(plist_file).read
    @plist = Redcar::Plist.xml_to_plist(@xml)
    @export = Redcar::Plist.plist_to_xml(@plist)
  end

  after(:each) do
    delete_fixtures
  end

  describe "import XML property list" do
    it "should turn an xml plist into ruby" do
      @plist.should_not be_nil
    end

    it "should create Hashes" do
      @plist.is_a?(Hash).should be_true
    end

    it "should create Arrays" do
      @plist['fruit'].should_not be_nil
      @plist['fruit'].is_a?(Array).should be_true
      @plist['fruit'].size.should == 3
    end

    it "should create Strings" do
      @plist['type'].should_not be_nil
      @plist['type'].is_a?(String).should be_true
    end
  end

  describe "export Ruby property list" do
    it "should turn a ruby plist into xml" do
      @export.should_not be_nil
      @export.is_a?(String).should be_true
    end

    it "should retain original format" do
      require 'rexml/document'
      doc = REXML::Document.new(@export)
      doc.root.name.should == 'plist'
      doc.root.elements.to_a.size.should == 1
      hash = doc.root.elements.to_a.first
      hash.name.should == 'dict'
      hash.elements.to_a.size.should == 4 # two for each property
      hash.elements.to_a.detect {|e|
        e.text == 'fruit' and e.name == 'key'
        }.should_not be_nil
      hash.elements.to_a.detect {|e|
        e.text == 'type' and e.name == 'key'
        }.should_not be_nil
      hash.elements.to_a.detect {|e|
        e.text == 'food' and e.name == 'string'
      }.should_not be_nil
      hash.elements.to_a.detect {|e|
        e.elements.to_a.size == 3 and e.name == 'array'
      }.should_not be_nil
    end
  end
end