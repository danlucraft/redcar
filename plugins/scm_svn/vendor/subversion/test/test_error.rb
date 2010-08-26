require "my-assertions"

require "svn/error"

class SvnErrorTest < Test::Unit::TestCase
  def test_error_name
    Svn::Error.constants.each do |const_name|
      if /\A[A-Z0-9_]+\z/ =~ const_name and
          Svn::Error.const_get(const_name).is_a?(Class)
        class_name = Svn::Util.to_ruby_class_name(const_name)
        assert_equal(Svn::Error.const_get(class_name),
                     Svn::Error.const_get(const_name))
      end
    end
  end
end
