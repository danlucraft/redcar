require 'test/unit'
require "prefix_tree"


class TestPrefixTree < Test::Unit::TestCase
  def setup
    @words = %w(abba abakus abbrechen finden döner keiner einer einerseits anders ohne mit mittels mittlerweile foo foobar bar)
    @tree = PrefixTree.new
    
    @words.each do |word|
      @tree << word
    end
  end
  
  def test_size
    assert_equal(@tree.number_of_words, @words.size)
  end
  
  def test_empty_prefix
    check_values(@words, "")
  end
  
  def test_find_all_with_axx
    check_values(%w(abba abakus abbrechen anders), "a")
    check_values(%w(abba abakus abbrechen), "ab")
  end
  
  def test_subtree_eine
    check_values(%w(einer einerseits), "eine")
    check_values(%w(einerseits), "einers")
    check_values(%w(einerseits), "einerseits")
    check_values(%w(einer einerseits), "einer")
  end
  
  def test_non_existing_prefixes
    check_values([], "einersksksjdl")
    check_values([], "asfasdfsa")
  end
  
  def check_values(values, prefix)
    actual = @tree.all_with_prefix(prefix)
    assert_equal(true, contain_same_elements?(values, actual), "\nexpected: #{values.inspect}\n#{actual.inspect}")
  end
  
  def contain_same_elements?(a, b)
    if a.size != b.size
      return false
    end
    
    return a.sort == b.sort
  end
end
