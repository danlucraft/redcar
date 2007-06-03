
Redcar.menu("_Tab") do |menu|
  menu.command("Statistics", :statistics, :info, "", :sensitize_to => :open_text_tabs?) do |pane, tab|
    if tab
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
    end
  end
  menu.command("All Statistics", :all_statistics, :info, "", :sensitize_to => :open_text_tabs?) do
    dialog = Redcar::Dialog.build(:title => "All Tab Statistics",
                                  :buttons => [:Update, :ok],
                                  :entry => [
                                             {:name => :chars, :type => :label, :legend => "Characters"},
                                             {:name => :lines, :type => :label, :legend => "Lines"},
                                             {:name => :words, :type => :label, :legend => "Words"}
                                            ]
                                  )
    dialog.on_button(:ok) {dialog.close}
    dialog.on_button(:Update) do 
      chars, lines, words = 0, 0, 0
      Redcar.tabs.each do |tab|
        char, line, word = statistics(tab)
        chars += char
        lines += line
        words += word
      end
      dialog.chars = chars
      dialog.lines = lines
      dialog.words = words
    end
    dialog.show { dialog.press_button(:Update) }
  end          
end

def statistics(tab)
  chars = tab.contents.length
  lines = tab.contents.to_s.split(/\n/).length
  words = tab.contents.to_s.split(/\s/).length
  return chars, lines, words
end
  
