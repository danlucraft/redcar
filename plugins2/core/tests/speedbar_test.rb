
module Redcar
  module PluginTests
    class SpeedbarTest < Test::Unit::TestCase
      def test_build
        win.speedbar.build do
          label   "Find:"
          textbox :find_text
          toggle  :match_case?, "Alt+C"
          label   "Match _case"
          button  "Find _Next", :GO_FORWARD, "Alt+N | Return" do |sb|
            puts "Find next"
          end
        end
      end
    end
  end
end
