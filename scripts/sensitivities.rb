
module Redcar
  Sensitivity.add(:open_text_tabs?, 
                  :hooks => [:after_tab_close, :after_new_tab]) do 
    !Redcar.current_window.all_tabs.empty?
  end
  
  Sensitivity.add(:unsaved_text_tabs?,
                  :hooks => [
                             :after_new_tab,
                             :after_close_tab,
                             :after_save_tab
                             ]) do
    Redcar.current_window.all_tabs.find do |tab| 
      tab.modified? if tab.respond_to? :modified?
    end
  end
  
  Sensitivity.add(:text_selected?,
                  :hooks => [:after_select, :after_focus, :tab_focus, :tab_clicked, :tab_changed]) do
    Redcar.current_tab and Redcar.current_tab.selected?
  end
  
  Sensitivity.add(:undo_info?,
                  :hooks => [:after_undo_status, :after_tab_focus]) do
    Redcar.current_tab.any_undo?
  end
  
  Sensitivity.add(:can_paste?,
                  :hooks => [:after_new_tab, :after_tab_close, 
                             :after_focus, :after_clipboard_added]) do
    !Clipboard.to_a.empty? and Redcar.current_window.focussed_tab.respond_to? :paste
  end
end
