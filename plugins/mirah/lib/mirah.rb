
require 'java'
require 'mirah/syntax_checker'

module Redcar
  class Mirah

    def self.load_dependencies
      unless @loaded
        require File.join(File.dirname(__FILE__),'..','vendor','mirah-parser')
        import  'mirah.impl.MirahParser'
        import  'jmeta.ErrorHandler'
        require 'mirah/my_error_handler'
        @loaded = true
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('mirah')
        storage.set_default('check_for_warnings', true)
        storage
      end
    end
  end
end