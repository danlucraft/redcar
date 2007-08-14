
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
    @image.size.should == 4
  end
  
  it 'should have access to the item by uuid' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.should_not be_nil
    item.should be_an_instance_of(Redcar.Image.Item)
    item[:name].should == "Caprica"
    item.type.should == :source
  end
  
  it 'should find items with a given tag' do
    @image.find_with_tag(:menuitem).length.should == 2
  end
  
  it 'should find items with all the given tags' do
    @image.find_with_tags(:menuitem, :core).length.should == 1
  end
  
  it 'should update data by id without changing tags' do
    @image["ca72aab0-1517-012a-209c-000ae4ee635c"] = {
      :name => "Caprica V2.0"
    }
    @image.cache
    @image = load_image
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.type.should == :user
    item.tags.should == [:menuitem]
    item[:name].should == "Caprica V2.0"
  end
  
  it 'should update data by id and changing tags' do
    @image["ca72aab0-1517-012a-209c-000ae4ee635c"] = {
      :name => "Caprica V2.0",
      :tags => [:foobar]
    }
    @image.cache
    @image = load_image
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.type.should == :user
    item.tags.should == [:foobar]
    item[:name].should == "Caprica V2.0"
  end
  
  it 'should add new data with tags' do
    id = @image.add :name => "Pikon", :tags => [:foo]
    @image.cache
    @image = load_image
    item = @image[id]
    item.type.should == :user
    item[:name].should == "Pikon"
  end
  
  it 'should tag items (and create user versions)' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.type.should == :source
    
    @image.tag("ca72aab0-1517-012a-209c-000ae4ee635c", :foobar)
    
    @image.cache
    @image = load_image
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.type.should == :user
    item.tags.should == [:menuitem, :foobar]
  end
end

describe Redcar.Image.Item do
  before :each do 
    remove_cache
    @image = load_image
  end
  
  it 'should allow us to inspect item metadata' do
    item = @image["ca72aab0-1517-012a-209c-000ae4ee635c"]
    item.type.should == :source
    item.tags.should == [:menuitem]
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
    item[:name].should == "Geminon"
    
    # alter file
    yaml = YAML.load(@original)
    yaml["dffc3af0-1517-012a-209c-000ae4ee635c"] = {
      :name => "Geminon V2.0",
      :tags => [:menuitem, :core],
      :created => Time.now
    }
    sleep 1
    File.open("spec/image/fixtures/source2.yaml", "w") do |f|
      f.puts yaml.to_yaml
    end
    @image = load_image
    
    item = @image["dffc3af0-1517-012a-209c-000ae4ee635c"]
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
