
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::Storage do
  it "acts like a hash" do
    storage = Redcar::Plugin::Storage.new('test')
    storage[:some_key] = "some value"
    storage[:some_key].should == "some value"
    storage[:some_key] = "some other value"
    storage[:some_key].should == "some other value"
  end

  it "rolls back to an empty hash if it hasn't been saved" do
    storage = Redcar::Plugin::Storage.new('test')
    storage[:some_key] = "some value"
    storage[:some_key].should == "some value"
    storage.rollback
    storage[:some_key].should be_nil
  end

  it "saves to disk" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key] = "some value"
    storage.save
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key].should == "some value"
    
    FileUtils.rm_rf(storage.send(:path))
  end
end
