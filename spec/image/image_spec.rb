
require 'spec/spec_helper'

def load_image
  Redcar.Image.new(:sources => ["spec/image/fixtures/*.yaml",
                                "spec/image/fixtures/*/*.yaml"],
                   :cache_dir => "spec/image/fixtures/")
end

def remove_cache
  FileUtils.rm_f "spec/image/fixtures/cache.img"
end

describe Redcar.Image do
  before :each do 
    remove_cache
    @image = load_image
  end
  
  it 'should load from sources' do
    @image.size.should == 6
  end
  
  it 'should have access to the latest version by uuid' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.should_not be_nil
    item.should be_an_instance_of(Redcar.Image.Item)
    item[:name].should == "Caprica V2.0"
  end
  
  it 'should have access to any version by uuid' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c", 1]
    item.should_not be_nil
    item[:name].should == "Caprica"
  end
  
  it 'should have access to any version and type by uuid' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c", 1, :user]
    item.should_not be_nil
    item[:name].should == "Caprica User"
  end
  
  it 'should find items with a given tag' do
    @image.find_with_tag(:menuitem).length.should == 2
  end
  
  it 'should find items with all the given tags' do
    @image.find_with_tags(:menuitem, :core).length.should == 1
  end
  
  it 'should save new data by id' do
    @image["ca72aab0-1517-012a-209c-000ae4ee635c"] = {
      :name => "Caprica V3.0"
    }
    @image.cache
    @image = load_image
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.version.should == 3
    item.type.should == :user
    item[:name].should == "Caprica V3.0"
  end
end

describe Redcar.Image.Item do
  before :each do 
    remove_cache
    @image = load_image
  end
  
  it 'should allow us to inspect item metadata' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.version.should == 2
    item.type.should == :master
  end
end

describe Redcar.Image, 'cache' do
  before :each do 
    remove_cache
    @original = File.read("spec/image/fixtures/source2.yaml")
    @image = load_image
  end
  
  after :each do
    # restore original
    File.open("spec/image/fixtures/source2.yaml", "w") do |f|
      f.puts @original
    end
    remove_cache
  end
  
  it 'should save the data in the cache' do
    File.exists?("spec/image/fixtures/cache.img").should be_true
  end
  
  it 'should check for updates after loading from the cache' do
    item = @image["dffc3af0-1517-012a-209c-000ae4ee635c"]
    item.version.should == 1
    item[:name].should == "Geminon"
    
    # alter file
    yaml = YAML.load(@original)
    yaml["dffc3af0-1517-012a-209c-000ae4ee635c"][:definitions] << 
      {:type=>:master, 
      :version=>2, 
      :data=>{:name=>"Geminon V2.0"}}
    sleep 1
    File.open("spec/image/fixtures/source2.yaml", "w") do |f|
      f.puts yaml.to_yaml
    end
    @image = load_image
    
    item = @image["dffc3af0-1517-012a-209c-000ae4ee635c"]
    item.version.should == 2
    item[:name].should == "Geminon V2.0"
  end
  
  it 'should add items from new sources when loading from cache' do
    b4 = @image.size
    @image = Redcar.Image.new(:sources => ["spec/image/fixtures/*.yaml",
                                           "spec/image/fixtures/*/*.yaml",
                                           "spec/image/fixtures/*.yml"],
                              :cache_dir => "spec/image/fixtures/")
    @image.size.should == b4 + 1
  end
end
