
class Array
  # Finds the first point in the enumerable where
  # blocks returns true. Assumes that self.map(&block)
  # has the form [false]*N + [true]*M.
  def find_flip(&block)
    ix = self.find_flip_index(&block)
    if ix
      self[ix]
    else
      nil
    end
  end
  
  def find_flip_index(&block)
    return nil if self.empty?
    if block[self[0]]
      return 0
    elsif block[self[-1]] and !block[self[-2]]
      return self.length-1
    end
    find_flip_index1(&block)
  end
  
  def find_flip_index1(low=0, high=self.length-1, &block)
    return nil if high < low
    mid = (2*high+low)/3
    midv = block[self[mid]]
    if mid == 0 and midv
      return mid
    elsif mid == 0 and !midv
      if self[mid+1] and block[self[mid+1]]
        return mid+1
      else
        return nil
      end
    elsif mid == self.length-1 and midv
      return midv
    elsif mid == self.length-1 and !midv
      return nil
    elsif midv and !block[self[mid-1]]
      return mid
    elsif !midv and block[self[mid+1]]
      return mid+1
    elsif midv
      return self.find_flip_index1(low, mid-1, &block)
    elsif !midv
      return self.find_flip_index1(mid+1, high, &block)
    else
      puts "hmmm.."
    end
  end
  
  # Finds all elements e where the :transform of e is :value
  # and assumes that the array is in the form:
  #    els_less_than_value + els_equal_to_value + els_greater_than_value
  def select_flip(options)
    unless options[:value] and options[:transform]
      raise ArgumentError, "select_flip needs :value and :options"
    end
    first_flip_index = self.find_flip_index do |v| 
      options[:transform][v] > options[:value]-1 
    end
    second_flip_index = self.find_flip_index do |v| 
      options[:transform][v] > options[:value]
    end
    return [] unless first_flip_index
    second_flip_index = self.length unless second_flip_index
    self[first_flip_index..(second_flip_index-1)]
  end
end

alias :fn :lambda

if $0 == __FILE__
  require 'test/unit'
  
  class TestSelectFlip < Test::Unit::TestCase
    def test_simple
      assert_equal([4.5, 4.9, 4], 
                   [1.2, 2.6, 3.3, 4.5, 4.9, 4, 5.0, 5, 6].select_flip( 
                      :value => 4, :transform => fn {|v| v.floor }))
      assert_equal([4.5, 4.9, 4], 
                   [4.5, 4.9, 4, 5.0, 5, 6].select_flip( 
                      :value => 4, :transform => fn {|v| v.floor }))
      assert_equal([4.5, 4.9, 4], 
                   [1.2, 2.6, 3.3, 4.5, 4.9, 4].select_flip( 
                      :value => 4, :transform => fn {|v| v.floor }))
      assert_equal([], 
                   [1.2, 2.6, 3.3].select_flip( 
                      :value => 4, :transform => fn {|v| v.floor }))
    end
  end
  
  class TestFindFlip < Test::Unit::TestCase
    def test_simple
      assert_equal 3, [1, 3].find_flip {|v| v >= 2}
      assert_equal 4, [1, 2, 3, 4, 5, 6, 7].find_flip {|v| v >= 4}
      assert_equal 10, [1, 10, 100, 1000].find_flip {|v| v >= 5}
      assert_equal("foo", 
                   (["asd", "poi"]*3+["foo", "pokf"]).find_flip{|v| v=~ /f/})
    end
    
    def test_boundary
      assert_equal 10, [10, 20, 30].find_flip {|v| v >= 10}
      assert_equal 30, [10, 20, 30].find_flip {|v| v >= 22}
    end
    
    def test_fails
      assert_equal nil, [10, 20, 30].find_flip {|v| v >= 100}
      assert_equal nil, [10, 20, 30].find_flip {|v| v <= 1}
    end
  end
end
