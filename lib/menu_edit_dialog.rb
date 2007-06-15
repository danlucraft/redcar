
module Redcar
  class MenuEditDialog
    def initialize
      @glade = GladeXML.new("lib/glade/menu_edit_dialog.glade", 
                            nil, 
                            "Redcar", 
                            nil, 
                            GladeXML::FILE) {|handler| method(handler)}
      @treeview = @glade["treeview_menu"]
      @treestore = Gtk::TreeStore.new(String)
      @treeview.model = @treestore
    end
  end
end
