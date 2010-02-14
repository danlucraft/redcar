
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::Storage do
  it "acts like a hash" do
    storage = Redcar::Plugin::Storage.new('test')
    storage[:some_key] = "some value"
    storage[:some_key].should == "some value"
    storage[:some_key] = "some other value"
    storage[:some_key].should == "some other value"
  end

  it "saves to disk" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key] = "some value"
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key].should == "some value"
    
    FileUtils.rm_rf(storage.send(:path))
  end
  
  it "has a get_with_default method" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved2')
    storage.get_with_default("a", "b").should == "b"
    storage['a'] = 'c'
    storage.get_with_default("a", "b").should == "c"
  end
end
