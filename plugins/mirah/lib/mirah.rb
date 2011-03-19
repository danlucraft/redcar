
require 'java'
require 'mirah/syntax_checker'
require 'mirah/repl_mirror'

module Redcar
  class Mirah

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Mirah REPL", OpenMirahREPL
          end
        end
      end
    end

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

    class OpenMirahREPL < Redcar::REPL::OpenREPL
      def execute
        open_repl(ReplMirror.new)
      end
    end
  end
end