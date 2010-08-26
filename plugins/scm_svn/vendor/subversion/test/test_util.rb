require "my-assertions"

require "svn/core"
require "svn/util"

class SvnUtilTest < Test::Unit::TestCase

  def test_to_ruby_const_name
    assert_equal("ABC", Svn::Util.to_ruby_const_name("abc"))
    assert_equal("ABC_DEF", Svn::Util.to_ruby_const_name("abc_def"))
  end

  def test_to_ruby_class_name
    assert_equal("Abc", Svn::Util.to_ruby_class_name("abc"))
    assert_equal("AbcDef", Svn::Util.to_ruby_class_name("abc_def"))
    assert_equal("AbcDef", Svn::Util.to_ruby_class_name("ABC_DEF"))
  end
end
