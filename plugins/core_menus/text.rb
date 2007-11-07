
module Redcar::Plugins::CoreMenus
  module TextMenu
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    
    command "Core/Text/Statistics" do |c|
      c.menu = "Text/Statistics"
      c.icon = :INFO
      c.sensitive = :open_text_tabs?
      c.command %q{
        def statistics(tab)
          chars = tab.contents.length
          lines = tab.contents.to_s.split(/\\n/).length
          words = tab.contents.to_s.split(/\\s/).length
          return chars, lines, words
        end
        dialog = Redcar::Dialog.build(:title => "Tab Statistics",
                              :buttons => [:Update, :ok],
                             :entry => [
                                        {:name => :chars, :type => :label, :legend => "Characters"},
                                        {:name => :lines, :type => :label, :legend => "Lines"},
                                        {:name => :words, :type => :label, :legend => "Words"}
                                       ]
                                      )
        dialog.on_button(:ok) {dialog.close}
        dialog.on_button(:Update) do
          ct = Redcar.current_tab
          dialog.chars, dialog.lines, dialog.words = statistics(ct)
        end
        dialog.show { dialog.press_button(:Update) }
     }
    end
  end
end
