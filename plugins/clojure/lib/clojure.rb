
require 'clojure/repl_mirror'

module Redcar
  class Clojure

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Clojure REPL", OpenClojureREPL
          end
        end
      end
    end

    def self.load_dependencies
      unless @loaded
        require File.join(Redcar.asset_dir, "clojure.jar")
        require File.join(Redcar.asset_dir, "clojure-contrib.jar")
        require File.join(Redcar.asset_dir, "org-enclojure-repl-server.jar")
        require File.dirname(__FILE__) + "/../vendor/enclojure-wrapper.jar"
        @loaded = true
      end
    end

    class OpenClojureREPL < Redcar::REPL::OpenREPL
      def execute
        open_repl(ReplMirror.new)
      end
    end
  end
end