
require 'pp'
require 'fileutils'
require 'open3'
require 'open4'
require 'tempfile'
require 'uri'
require 'cgi'

# GTK dependencies
require 'gtk2'
require 'gconf2'

$:.push(File.expand_path(File.dirname(__FILE__) + "/../vendor/zerenity/lib"))
require 'zerenity'

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

# require 'test/unit'

require 'active_support/vendor'
require 'active_support/basic_object'
require 'active_support/duration'
require 'active_support/core_ext'
require 'active_support/multibyte'

