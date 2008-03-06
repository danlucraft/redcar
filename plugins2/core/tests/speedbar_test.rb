
module Redcar
  module PluginTests
    class SpeedbarTest < Test::Unit::TestCase
      def test_build
        win.speedbar.build do
          label   "Find:"
          textbox :find_text
          label   "Match _case"
          toggle  :match_case?, "Alt+C"
          button  "Find _Next", "Alt+N | Return" do |sb|
            puts "Find next"
          end
        end
      end
    end
  end
end
