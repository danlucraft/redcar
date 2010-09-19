
require File.dirname(__FILE__) + '/../../spec_helper'

describe Redcar::Macros::Predictive::SequenceFinder do
  SequenceFinder = Redcar::Macros::Predictive::SequenceFinder
  
  describe "fully repeated sequences" do
    it "should find repeated sequence of length 1" do
      SequenceFinder.new(%w(a a).reverse).first.should == %w(a)
    end
    
    it "should find repeated sequence of length 2" do
      SequenceFinder.new(%w(a b a b).reverse).first.should == %w(a b)
    end
    
    it "should find repeated sequence of length 3" do
      SequenceFinder.new(%w(a b c a b c).reverse).first.should == %w(a b c)
    end
    
    it "should find repeated sequence of length 3 with padding at the front" do
      SequenceFinder.new(%w(x x a b c a b c).reverse).first.should == %w(a b c)
    end
  end
end




__END__
  describe "find candidate sequences" do
    it "should find from 1 length partial repeat" do
      assert_equal [[1, 2, 3]],
        Redcar::DynamicMacros.find_repeated_sequences([3, 1, 2, 3, 4, 5])
    end
    
    it "should find two possibilities from 2 length partial repeat" do
      assert_equal [[1, 2, 3], [3, 1, 2]],
        Redcar::DynamicMacros.find_repeated_sequences([2, 3, 1, 2, 3])
    end
    
    it "should find three possibilites from complete repetition of length 3 sequence" do
      assert_equal [[1, 2, 3], [3, 1, 2], [2, 3, 1]],
        Redcar::DynamicMacros.find_repeated_sequences([1, 2, 3, 1, 2, 3])
    end
    
    it "should find a lot of possibilities from a short repeated sequence"do
      assert_equal [[2, 1], [1, 2, 1, 2], [2, 1, 2, 1], [1, 2], [1, 2, 1, 2], [1, 2, 1, 2, 1, 2]],
        Redcar::DynamicMacros.find_repeated_sequences([2, 1, 2, 1, 2, 1, 2, 4])
    end
  end
  
  it "should find most likely repeated sequence" do
    assert_equal {:seq => [1, 2, 3], :length => 1, :gap => 2},
      Redcar::DynamicMacros.find_repeated_sequence([3, 1, 2, 3, 4, 5])
    assert_equal {:seq => [[1, 2, 3], :length => 2, :gap => 1},
      Redcar::DynamicMacros.find_repeated_sequence([2, 3, 1, 2, 3])
    assert_equal {:seq => [[1, 2, 3], :length => 3, :gap => 0},
      Redcar::DynamicMacros.find_repeated_sequence([1, 2, 3, 1, 2, 3])
    assert_equal {:seq => [[2, 1], :length => 2, :gap => 0},
      Redcar::DynamicMacros.find_repeated_sequence([2, 1, 2, 1, 2, 1, 2, 4])
    assert_equal {:seq => [%w{a b c c}.reverse, :length => 4, :gap => 0},
      Redcar::DynamicMacros.find_repeated_sequence("abccabcc".split(//).reverse)
    assert_equal {:seq => [%w{a b r a c a d}.reverse, :length => 4, :gap => 3},
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse)
  end
  
  it "should 3"
    assert_equal {:seq => %w{a b r a c a d}.reverse, :length => 4, :gap => 3},
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse)
    assert_equal {:seq => %w{b r a c a d a}.reverse, :length => 3, :gap => 4},
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse, 4, 3)
    assert_equal {:seq => %w{r a c a d a b}.reverse, :length => 2, :gap => 5},
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse, 3, 4)
    assert_equal {:seq => %w{a b r}.reverse, :length => 1, :gap => 2},
      Redcar::DynamicMacros.find_repeated_sequence("abracadabra".split(//).reverse, 2, 5)
  end
end