
module Redcar
  class EditTab < Tab
    extend Redcar::PreferenceBuilder
    attr_reader :view
    
    preference "Appearance/Tab Font" do
      default "Monospace 12"
      widget  { EditTab.font_chooser_button("Appearance/Tab Font") }
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            tab.view.set_font(Redcar::Preference.get("Appearance/Tab Font"))
          end
        end
      end
    end
    
    preference "Appearance/Tab Font" do
      default "Monospace 12"
      widget  { EditTab.font_chooser_button("Appearance/Tab Font") }
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            tab.view.set_font(Redcar::Preference.get("Appearance/Tab Font"))
          end
        end
      end
    end
    
    preference "Appearance/Entry Font" do
      default "Monospace 12"
      widget { EditTab.font_chooser_button("Appearance/Entry Font") }
    end
    
    preference "Appearance/Tab Theme" do |p|
      type :combo
      default "Mac Classic"
      values { EditView::Theme.theme_names }
      change do 
        win.tabs.each do |tab|
          if tab.respond_to? :view
            theme_name = Redcar::Preference.get("Appearance/Tab Theme")
            tab.view.set_theme(EditView::Theme.theme(theme_name))
          end
        end
      end
    end
    
    preference "Appearance/Entry Theme" do |p|
      type :combo
      default "Mac Classic"
      values { EditView::Theme.theme_names }
    end
    
    preference "Editing/Wrap words" do
      default true
      type    :toggle
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            if Redcar::Preference.get("Editing/Wrap words")
              tab.view.wrap_mode = Gtk::TextTag::WRAP_WORD
            else
              tab.view.wrap_mode = Gtk::TextTag::WRAP_NONE
            end
          end
        end
      end
    end
    
    def self.font_chooser_button(name)
      gtk_image = Gtk::Image.new(Gtk::Stock::SELECT_FONT, 
                                 Gtk::IconSize::MENU)
      gtk_hbox = Gtk::HBox.new
      gtk_label = Gtk::Label.new(Redcar::Preference.get(name))
      gtk_hbox.pack_start(gtk_image, false)
      gtk_hbox.pack_start(gtk_label)
      widget = Gtk::Button.new
      widget.add(gtk_hbox)
      class << widget
        attr_accessor :preference_value
      end
      widget.preference_value = Redcar::Preference.get(name)
      widget.signal_connect('clicked') do
        dialog = Gtk::FontSelectionDialog.new("Select Application Font")
        dialog.font_name = widget.preference_value
        dialog.preview_text = "So say we all!"
        if dialog.run == Gtk::Dialog::RESPONSE_OK
          puts font = dialog.font_name
          font = dialog.font_name
          widget.preference_value = font
          gtk_label.text = font
        end
        dialog.destroy
      end
      widget
    end
    
    def initialize(pane)
      @view = Redcar::EditView.new
      super pane, @view, :scrolled? => true
    end
    
    def document
      @view.buffer
    end
  end
end
