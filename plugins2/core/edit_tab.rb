
module Redcar
  class EditTab < Tab
    extend Redcar::PreferenceBuilder
    attr_reader :document, :view
    
    preference "Tab Font" do
      default "Monospace 12"
      widget  { EditTab.font_chooser_button("Redcar::EditTab", "Tab Font") }
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            tab.view.set_font(Redcar::Preference.get("Redcar::EditTab", "Tab Font"))
          end
        end
      end
    end
    
    preference "Entry Font" do
      default "Monospace 12"
      widget { EditTab.font_chooser_button("Redcar::EditTab", "Entry Font") }
    end
    
    preference "Wrap words" do
      default true
      type    :toggle
      change do
#         win.all_tabs.each do |tab|
#           if tab.respond_to? :textview 
#             if $BUS['/redcar/preferences/Redcar::EditView/Wrap words']
#               tab.textview.wrap_mode = Gtk::TextTag::WRAP_WORD
#             else
#               tab.textview.wrap_mode = Gtk::TextTag::WRAP_NONE
#             end
#           end
#         end
      end
    end
    
    def self.font_chooser_button(scope, name)
      gtk_image = Gtk::Image.new(Gtk::Stock::SELECT_FONT, 
                                 Gtk::IconSize::MENU)
      gtk_hbox = Gtk::HBox.new
      gtk_label = Gtk::Label.new(Redcar::Preference.get(scope, name))
      gtk_hbox.pack_start(gtk_image, false)
      gtk_hbox.pack_start(gtk_label)
      widget = Gtk::Button.new
      widget.add(gtk_hbox)
      class << widget
        attr_accessor :preference_value
      end
      widget.preference_value = Redcar::Preference.get(scope, name)
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
      set_gtk_cursor_colour
      @view = Redcar::EditView.new
      @document = Redcar::Document.new
      @view.buffer = @document
      super pane, @view
    end
    
    def set_gtk_cursor_colour
      Gtk::RC.parse_string(<<-EOR)
    style "green-cursor" {
      GtkTextView::cursor-color = "grey"
    }
    class "GtkWidget" style "green-cursor"
      EOR
    end
  end
end
