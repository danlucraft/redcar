
module Redcar
  class EditTabPlugin
    preference "Appearance/Tab Font" do
      default "Monospace 12"
      widget  { EditTabPlugin.font_chooser_button("Appearance/Tab Font") }
      change do
        Redcar.win.tabs.each do |tab|
          if tab.is_a? EditTab
            tab.view.modify_font(Pango::FontDescription.new(Redcar::Preference.get("Appearance/Tab Font")))
          end
        end
      end
    end

    preference "Appearance/Tab Theme" do |p|
      type :combo
      default "Mac Classic"
      values { Gtk::Mate::Theme.themes.map(&:name).sort_by(&:downcase) }
      change do
        Redcar.win.collect_tabs(Redcar::EditTab).each do |tab|
          theme_name = Redcar::Preference.get("Appearance/Tab Theme")
          tab.view.set_theme_by_name(theme_name)
        end
      end
    end

    preference "Editing/Indent size" do |p|
      type    :integer
      bounds  [0, 20]
      step    1
      default 2
      change do
        Redcar.win.collect_tabs(Redcar::EditTab).each do |tab|
          tab.view.set_tab_width(Redcar::Preference.get("Editing/Indent size").to_i)
        end
      end
    end

    preference "Editing/Use spaces instead of tabs" do |p|
      type    :toggle
      default true
    end

    preference "Editing/Indent pasted text" do |p|
      type    :toggle
      default true
    end

    preference "Editing/Wrap words" do
      type    :toggle
      default true
      change do
        Redcar.win.collect_tabs(Redcar::EditTab).each do |tab|
          if Redcar::Preference.get("Editing/Wrap words").to_bool
            tab.view.wrap_mode = Gtk::TextTag::WRAP_WORD
          else
            tab.view.wrap_mode = Gtk::TextTag::WRAP_NONE
          end
        end
      end
    end

    preference "Editing/Show line numbers" do
      default true
      type    :toggle
      change do
        value = Redcar::Preference.get("Editing/Show line numbers").to_bool
        Redcar.win.collect_tabs(EditTab).each do |tab|
          tab.view.show_line_numbers = value
        end
      end
    end
  end
end
