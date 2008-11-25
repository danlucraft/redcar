
require 'pp'
require 'log4r'
require 'fileutils'

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


require 'active_support'
