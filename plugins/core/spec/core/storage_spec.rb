
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::Storage do
  
  after do
    FileUtils.rm_rf(Redcar::Plugin::Storage.new('test_storage_saved').send(:path))
  end
  
  it "acts like a hash" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
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
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage[:some_key].should be_nil
  end
  
  it "has a set default method" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage.set_default('a', 'b')    
    storage['a'].should == 'b'
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage['a'].should == 'b'
    storage['a'] = 'c'
    storage['a'].should == 'c'
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage['a'].should == 'c'
    storage['b'] = false
    storage.set_default('b', true)
    storage['b'].should == false
  end
  
  it "should reload when the storage file itself has been elsewise modified" do
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage['a'] = 'b'
    storage['a'].should == 'b'
    storage['a'].should == 'b'
    sleep 1 # windows doesn't have finer granularity than this
    File.open(storage.send(:path), 'w') do |f|
      f.write "---
                a: new"
    end    
    storage['a'].should == 'new'
    storage['a'].should == 'new'
    storage = Redcar::Plugin::Storage.new('test_storage_saved')
    storage['a'].should == 'new'    
  end
  
end
