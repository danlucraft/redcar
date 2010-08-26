require "test/unit"
require "test/unit/assertions"

module Test
  module Unit
    module Assertions

      def assert_true(boolean, message=nil)
        _wrap_assertion do
          assert_equal(true, boolean, message)
        end
      end

      def assert_false(boolean, message=nil)
        _wrap_assertion do
          assert_equal(false, boolean, message)
        end
      end

      def assert_nested_sorted_array(expected, actual, message=nil)
        _wrap_assertion do
          assert_equal(expected.collect {|elem| elem.sort},
                       actual.collect {|elem| elem.sort},
                       message)
        end
      end

      def assert_equal_log_entries(expected, actual, message=nil)
        _wrap_assertion do
          actual = actual.collect do |entry|
            changed_paths = entry.changed_paths
            changed_paths.each_key do |path|
              changed_path = changed_paths[path]
              changed_paths[path] = [changed_path.action,
                                     changed_path.copyfrom_path,
                                     changed_path.copyfrom_rev]
            end
            [changed_paths,
             entry.revision,
             entry.revision_properties.reject {|key, value| key == "svn:date"},
             entry.has_children?]
          end
          assert_equal(expected, actual, message)
        end
      end
    end
  end
end
