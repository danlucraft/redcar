
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

require 'active_support/core_ext/blank'
require 'active_support/multibyte'
require 'active_support/core_ext/string'
