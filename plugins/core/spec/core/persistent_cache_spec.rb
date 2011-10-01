
require "spec_helper"

PersistentCache = Redcar::PersistentCache

describe PersistentCache do
  before do
    PersistentCache.storage_dir = storage_dir
    FileUtils.rm_rf(storage_dir)
    @shouldnt_calculate = false
    @calculation = false
  end
  
  after do
    FileUtils.rm_rf(storage_dir)
  end

  def storage_dir
    File.expand_path(File.join(File.dirname(__FILE__), "scratch"))
  end
  
  def cache_file_exists?(name)
    File.exist?(File.join(File.dirname(__FILE__), "scratch", name)).should be_true
  end

  def expect_no_calculation
    @shouldnt_calculate = true
  end
  
  def it_should_have_calculated
    @calculation.should be_true
  end
  
  def reset_calculation
    @calculation = false
  end
  
  def test_block
    lambda do
      if @shouldnt_calculate
        raise "shouldn't be calculating here"
      end
      @calculation = true
      [1, 2, 3]
    end  
  end
  
  def spec_glob
    File.expand_path(File.dirname(__FILE__)) + "/*"
  end
  
  def expected_result
    [1, 2, 3]
  end

  it "should create a cache file" do
    cache = PersistentCache.new("test1")
    cache.cache(&test_block).should == expected_result
    it_should_have_calculated
    cache_file_exists?("test1.cache")
  end

  it "should not calculate a second time" do
    cache = PersistentCache.new("test1")
    cache.cache(&test_block).should == expected_result

    cache = PersistentCache.new("test1")
    expect_no_calculation
    cache.cache(&test_block).should == expected_result
    cache_file_exists?("test1.cache")
  end
  
  it "should let you get a list of all defined caches" do
    PersistentCache.all.should == []
    cache = PersistentCache.new("test1")
    cache.cache(&test_block)
    PersistentCache.all.map(&:name).should == ["test1"]
  end
  
  it "should let you clear a cache" do
    PersistentCache.all.should == []
    cache = PersistentCache.new("test1")
    cache.cache(&test_block)
    it_should_have_calculated
    PersistentCache.all.map(&:name).should == ["test1"]
    cache.clear
    PersistentCache.all.should == []
    cache = PersistentCache.new("test1")
    cache.cache(&test_block)
    it_should_have_calculated
    PersistentCache.all.map(&:name).should == ["test1"]
  end
end







