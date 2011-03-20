
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::Storage do
  
  it "should be based on Redcar::Plugin::BaseStorage" do
    Redcar::Plugin::Storage.ancestors.should include(Redcar::Plugin::BaseStorage)
  end
  
  it "should have a default storage path" do
    Redcar::Plugin::Storage.storage_dir.should == File.join(Redcar.user_dir, "storage")
  end
  
  it "should have a configurable storage path" do
    old_storage_dir = Redcar::Plugin::Storage.storage_dir
    Redcar::Plugin::Storage.storage_dir = File.dirname(__FILE__)
    Redcar::Plugin::Storage.storage_dir.should == File.dirname(__FILE__)
    Redcar::Plugin::Storage.storage_dir = old_storage_dir
  end
  
  it "should store files inside the directory specified by storage path" do
    Redcar::Plugin::Storage.storage_dir = File.dirname(__FILE__)
    storage = Redcar::Plugin::Storage.new('test_storage')
    storage.send(:path).should == File.join(File.dirname(__FILE__), 'test_storage.yaml')
  end
    
end
