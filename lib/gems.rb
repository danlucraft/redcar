
require 'pp'
require 'fileutils'
require 'open3'

# GTK dependencies
require 'gtk2'

# RubyGem dependencies
require 'rubygems'
require 'oniguruma'
ORegexp = Oniguruma::ORegexp

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

require 'test/unit'

require 'active_support/vendor'
require 'active_support/basic_object'
require 'active_support/duration'
require 'active_support/core_ext'
require 'active_support/multibyte'
