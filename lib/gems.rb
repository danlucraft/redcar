
require 'pp'
require 'log4r'
require 'fileutils'

# GTK dependencies
require 'gtk2'
require 'gtksourceview'

# RubyGem dependencies
require 'rubygems'
if RUBY_VERSION == "1.9.0"
  module Oniguruma
    ORegexp = Regexp
    OPTION_CAPTURE_GROUP = 1
  end
  ORegexp = Regexp
else
  require 'oniguruma'
  ORegexp = Oniguruma::ORegexp
end

module Oniguruma #:nodoc:
  class ORegexp #:nodoc:
    def _dump(_)
      self.source
    end
    def self._load(str)
      self.new(str, :options => Oniguruma::OPTION_CAPTURE_GROUP)
    end
  end
end

require 'active_support/core_ext/blank'
require 'active_support/multibyte'
require 'active_support/core_ext/string'
