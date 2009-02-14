
module Redcar
  class BundleInfoCommand < Redcar::Command
    norecord
    
    def initialize(bundle)
      @bundle = bundle
    end
    
    def execute
      string =<<END
      Name: #{@bundle.name}
      Author: #{@bundle.info["contactName"]}
      Email: #{(@bundle.info["contactEmailRot13"]||"").tr!("A-Za-z", "N-ZA-Mn-za-m")}
      Description: #{@bundle.info["description"]}
END
      dialog = Gtk::MessageDialog.new(Redcar.win,
        Gtk::Dialog::DESTROY_WITH_PARENT,
        Gtk::MessageDialog::INFO,
        Gtk::MessageDialog::BUTTONS_CLOSE,
        string)
      dialog.title = "Plugin Information"
      dialog.run
      dialog.destroy
    end
  end
end
