require 'test/unit/failure'
require 'test/unit/error'

module Test
  module Unit
    BACKTRACE_INFO_RE = /.+:\d+:in `.+?'/
    class Failure
      alias_method :original_long_display, :long_display
      def long_display
        extract_backtraces_re =
          /^    \[(#{BACKTRACE_INFO_RE}(?:\n     #{BACKTRACE_INFO_RE})+)\]:$/
        original_long_display.gsub(extract_backtraces_re) do |backtraces|
          $1.gsub(/^     (#{BACKTRACE_INFO_RE})/, '\1') + ':'
        end
      end
    end

    class Error
      alias_method :original_long_display, :long_display
      def long_display
        original_long_display.gsub(/^    (#{BACKTRACE_INFO_RE})/, '\1')
      end
    end
  end
end
