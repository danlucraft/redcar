
Redcar.menu("_Edit") do |menu|
  menu.command("Undo", :undo, :undo, "ctrl z", :sensitize_to => :undo_info?) do |pane, tab|
    tab.undo
  end
  
  menu.separator
  
  menu.command("Cu_t", :cut, :cut, "ctrl x", :sensitize_to => :text_selected?) do |pane, tab|
    tab.cut
  end
  
  menu.command("_Copy", :copy, :copy, "ctrl c", :sensitize_to => :text_selected?) do
    Redcar.current_tab.copy
  end
  
  menu.command("_Paste", :paste, :paste, "ctrl v", 
               :sensitize_to => :can_paste?) do
    Redcar.current_tab.paste
  end
  
  menu.separator
  
  menu.command("Select _All", :select_all, nil, "", :sensitize_to => :open_text_tabs?) do
    ct = Redcar.current_tab
    ct.select(0, ct.length)
  end
  
  menu.separator
  
#   menu.command("_Find", :find, :find, "ctrl f") do
#     dialog = Redcar::Dialog.build(:title => "Find",
#                                   :buttons => [:find, :ok],
#                                   :entry => [
#                                              {:name => :query_string, :type => :text}
#                                             ])
#     dialog.on_button(:ok) { dialog.close }
#     dialog.on_button(:find) do 
#       tab = Redcar.tabs.current
#       if tab
#         unless tab.selected?
#           loc = tab.find_next(dialog.query_string)
#           first = false
#         else
#           tab.cursor += 1
#           loc = tab.find_next(dialog.query_string)
#         end
#         tab.select(loc, dialog.query_string.length) if loc
#       end
#     end
#     dialog.show
#   end
  
  menu.command("_Find", :find, :find, "ctrl f", :sensitize_to => :open_text_tabs?) do
    if $sb_find
      $sb_find.close
      $sb_find = nil
    else
      speedbar = Redcar::Speedbar.build(:title => "Find",
                                        :buttons => [:find, :ok],
                                        :entry => [
                                                   {:name => :query_string, :type => :text}
                                                  ])
      $sb_find = speedbar
      speedbar.on_button(:ok) { speedbar.close; $sb_find = nil }
      speedbar.on_button(:find) do 
        tab = Redcar.tabs.current
        if tab
          unless tab.find_next(speedbar.query_string)
            Redcar.StatusBar.main = "not found"
          end
        end
      end
      speedbar.show
    end
  end
   
#   menu.command("Find/_Replace", :find_replace, :find_and_replace, "ctrl r") do
#     if tab = Redcar.tabs.current
#       dialog = Redcar::Dialog.build(:title => "Find",
#                                     :buttons => [:find, :replace, :ok],
#                                     :entry => [
#                                        {:name => :query_string, :type => :text, :legend => "Find"},
#                                        {:name => :replace_string, :type => :text, :legend => "Replace"}
#                                     ])
      
#       dialog.on_button(:ok) { dialog.close }
#       dialog.on_button(:find) do 
#         unless tab.selected?
#           loc = tab.find_next(dialog.query_string)
#           first = false
#         else
#           tab.cursor += 1
#           loc = tab.find_next(dialog.query_string)
#         end
#         tab.select(loc, dialog.query_string.length) if loc
#       end
#       dialog.on_button(:replace) do
#         tab.delete(tab.cursor, tab.selection_end)
#         tab.insert(tab.cursor, dialog.replace_string)
#       end
#       dialog.show
#     end
#   end
  
  menu.command("_Regexp Find", :regexp_find, nil, "", {:sensitize_to => :open_text_tabs?}) do 
    if tab = Redcar.tabs.current
      dialog = Redcar::Dialog.build(:title => "Regexp Find",
                                    :buttons => [:find, :ok],
                                    :entry => [
                                       {:name => :query_regexp, :type => :text, :legend => "Regexp"},
                                    ])
    end
    dialog.on_button(:ok) { dialog.close }
    dialog.on_button(:find) do
      if tab.selected?
        tab.cursor += 1
      end
      md = Regexp.new(dialog.query_regexp).match(tab.contents_from_cursor)
      if md
        tab.select(tab.cursor + md.offset(0)[0], md.offset(0)[1]-md.offset(0)[0])
      end
    end
    dialog.show
  end
  
  menu.command("R_egexp Find/Replace", :regexp_find_replace, nil, "", :sensitize_to => :open_text_tabs?) do 
    if tab = Redcar.tabs.current
      dialog = Redcar::Dialog.build(:title => "Regexp Replace",
                                    :buttons => [:find, :replace, :ok],
                                    :entry => [
                                       {:name => :query_regexp, :type => :text, :legend => "Find"},
                                       {:name => :replace_string, :type => :text, :legend => "Replace"}
                                    ])
    end
    md = nil
    dialog.on_button(:ok) { dialog.close }
    dialog.on_button(:find) do
      if tab.selected?
        tab.cursor += 1
      end
      md = Regexp.new(dialog.query_regexp).match(tab.contents_from_cursor)
      if md
        tab.select(tab.cursor + md.offset(0)[0], md.offset(0)[1]-md.offset(0)[0])
      end
    end
    dialog.on_button(:replace) do
      if md and tab.selected?
        tab.delete(tab.cursor, tab.selection_end)
        replace_text = md[0].gsub!(Regexp.new(dialog.query_regexp), dialog.replace_string)
        tab.insert(tab.cursor, replace_text)
      end
      dialog.press_button(:find)
    end
    dialog.show
  end
  
  menu.command("Speedbar Rege_xp Find/Replace", :speedbar_regexp_find_replace, :find, "<ctl>g", 
               :sensitize_to => :open_text_tabs?) do 
    if $sb_regexp_find_replace
      $sb_regexp_find_replace.close
      $sb_regexp_find_replace = nil
    else
      if tab = Redcar.tabs.current
        dialog = Redcar::Speedbar.build(:title => "Regexp Replace",
                                        :buttons => [:find, :replace, :ok],
                                        :entry => [
                                                   {:name => :query_regexp, :type => :text, :legend => "Find"},
                                                   {:name => :replace_string, :type => :text, :legend => "Replace"}
                                                  ])
        $sb_regexp_find_replace = dialog
        md = nil
        dialog.on_button(:ok) { dialog.close; $sb_regexp_find_replace = nil}
        dialog.on_button(:find) do
          if tab.selected?
            tab.cursor += 1
          end
          md = Regexp.new(dialog.query_regexp).match(tab.contents_from_cursor)
          if md
            tab.select(tab.cursor + md.offset(0)[0], md.offset(0)[1]-md.offset(0)[0])
          end
        end
        dialog.on_button(:replace) do
          if md and tab.selected?
            tab.delete(tab.cursor, tab.selection_end)
            replace_text = md[0].gsub!(Regexp.new(dialog.query_regexp), dialog.replace_string)
            tab.insert(tab.cursor, replace_text)
          end
          dialog.press_button(:find)
        end
        dialog.show
      end
    end
  end
  
  menu.separator
  
  menu.command("Backward Word", :backward_word, nil, "<ctl>k", :sensitize => :open_text_tabs?) do |pane, tab|
    tab.backward_word
  end
  
  menu.command("Forward Word", :forward_word, nil, "<ctl>l", :sensitize => :open_text_tabs?) do |pane, tab|
    tab.forward_word
  end
  
  menu.command("Transpose", :transpose, nil, "<ctl>t", :sensitize => :open_text_tabs?) do |pane, tab|
    tab.transpose
  end
  
  menu.command("Transpose Word", :transpose_word, nil, "<ctl>y", :sensitize => :open_text_tabs?) do |pane, tab|
    tab.transpose_word
  end
end
