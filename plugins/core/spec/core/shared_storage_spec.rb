
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::SharedStorage do
  
  before do
    remove_test_files
  end
  
  after do
    remove_test_files
  end
  
  def remove_test_files
    FileUtils.rm_rf(Redcar::Plugin::Storage.new('test_shared_storage').send(:path))
  end
  
  it "should set the default when it is not already set and the value is an Array" do
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage.set_or_update_default('a', ['b', 'c'])
    storage['a'].should == ['b', 'c']
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage['a'].should == ['b', 'c']
  end
  
  it "should set the default when it is not already and the value is not an Array" do
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage.set_or_update_default('a', 'b')
    storage['a'].should == ['b']
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage['a'].should == ['b']
  end
  
  it "should update the default when it is already set and the value is an Array" do
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage.set_or_update_default('a', 'b')
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage.set_or_update_default('a', 'c')
    storage['a'].should == ['b', 'c']
  end
  
  it "should update the default when it is already set and the value is not an Array" do
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage.set_or_update_default('a', 'b')
    storage = Redcar::Plugin::SharedStorage.new("test_shared_storage")
    storage.set_or_update_default('a', ['c', 'd'])
    storage['a'].should == ['b', 'c', 'd']
  end
end