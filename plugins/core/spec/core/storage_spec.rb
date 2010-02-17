
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::Storage do
  
  it "acts like a hash" do
    storage = Redcar::Plugin::Storage.new('test')
    storage[:some_key] = "some value"
    storage[:some_key].should == "some value"
    storage[:some_key] = "some other value"
    storage[:some_key].should == "some other value"
    
    FileUtils.rm_rf(storage.send(:path))
  end

  it "saves to disk" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key] = "some value"
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key].should == "some value"
    
    FileUtils.rm_rf(storage.send(:path))
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key].should be_nil
  end
  
  it "has a set default method" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage.set_default('a', 'b')
    storage['a'].should == 'b'
    storage['a'] = 'c'
    storage['a'].should == 'c'
  end
    
  
end
