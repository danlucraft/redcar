
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Plugin::BaseStorage do
  
  before :each do
    @tmp_dir = File.join(File.dirname(__FILE__), "tmp")
    FileUtils.mkdir_p(@tmp_dir)
  end
  
  after :each do
    FileUtils.rm_rf(@tmp_dir)
  end
  
  def get_new_storage
    Redcar::Plugin::BaseStorage.new(@tmp_dir, 'test_storage_saved')
  end
  
  it "acts like a hash" do
    storage = get_new_storage
    storage[:some_key] = "some value"
    storage[:some_key].should == "some value"
    storage[:some_key] = "some other value"
    storage[:some_key].should == "some other value"
  end

  it "saves to disk" do
    storage = get_new_storage
    storage[:some_key] = "some value"
    storage = get_new_storage
    storage[:some_key].should == "some value"
    
    FileUtils.rm_rf(storage.send(:path))
    storage = get_new_storage
    storage[:some_key].should be_nil
  end
  
  it "has a set default method" do
    storage = get_new_storage
    storage.set_default('a', 'b')    
    storage['a'].should == 'b'
    storage = get_new_storage
    storage['a'].should == 'b'
    storage['a'] = 'c'
    storage['a'].should == 'c'
    storage = get_new_storage
    storage['a'].should == 'c'
    storage['b'] = false
    storage.set_default('b', true)
    storage['b'].should == false
  end
  
  it "should raise an error when the storage file is invalid/corrupt" do
    storage = get_new_storage
    FileUtils.touch(storage.send(:path))
    lambda { storage.rollback }.should raise_error(RuntimeError)
  end
  
  it "should reload when the storage file itself has been elsewise modified" do
    storage = get_new_storage
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
    storage = get_new_storage
    storage['a'].should == 'new'    
  end
  
  it "should allow per-instance storage directory" do
    storage  = Redcar::Plugin::BaseStorage.new(@tmp_dir, 'test_storage_saved')
    storage2 = Redcar::Plugin::BaseStorage.new(File.join(@tmp_dir, "sub"), 'test_storage_saved')
    storage.send(:path).should_not == storage2.send(:path)
  end
  
end
