
module Redcar
  class MenuEditDialog
    def initialize
      @glade = GladeXML.new("lib/glade/menu_edit_dialog.glade", 
                            nil, 
                            "Redcar", 
                            nil, 
                            GladeXML::FILE) {|handler| method(handler)}
#       super("Edit Menus", 
#             Redcar.current_window,
#             Gtk::Dialog::DESTROY_WITH_PARENT,
#             [ Gtk::Stock::APPLY, Gtk::Dialog::RESPONSE_APPLY ],
#             [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ])
#       signal_connect('response') do |_, id|
#         if id == Gtk::Dialog::RESPONSE_DELETE_EVENT
#           self.destroy
#         end
#       end
#       hbox1 = Gtk::HBox.new
#       vbox.pack_start(hbox1, true)
      
#       @treestore = Gtk::TreeStore.new(String)
#       @treeview = Gtk::TreeView.new(@treestore)
#       hbox1.pack_start(@treeview, true)
      
#       vbox1 = Gtk::VBox.new
#       hbox1.pack_start(vbox1, true)
      
#       vbox1.pack_start(Gtk::Label.new("Edit Command").show)
#       vbox1.pack_start(Gtk::Button.new("foo"), true)
      
#       show_all
    end
  end
end
