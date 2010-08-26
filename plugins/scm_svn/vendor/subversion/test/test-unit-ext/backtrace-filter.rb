require 'test/unit/util/backtracefilter'

module Test
  module Unit
    module Util
      module BacktraceFilter
        TEST_UNIT_EXT_PREFIX = File.dirname(__FILE__)

        alias_method :original_filter_backtrace, :filter_backtrace
        def filter_backtrace(backtrace, prefix=nil)
          original_result = original_filter_backtrace(backtrace, prefix)
          original_filter_backtrace(original_result, TEST_UNIT_EXT_PREFIX)
        end
      end
    end
  end
end
