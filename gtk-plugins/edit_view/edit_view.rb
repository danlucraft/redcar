
module Redcar
  class EditViewPlugin < Redcar::Plugin
    def self.load(plugin) #:nodoc:
      Redcar::EditView::Indenter.lookup_indent_rules
      Redcar::EditView::AutoPairer.lookup_autopair_rules

      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin) #:nodoc:
      plugin.transition(FreeBASE::RUNNING)
    end

    def self.stop(plugin) #:nodoc:
#       Redcar::EditView::Theme.cache
      plugin.transition(FreeBASE::LOADED)
    end
  end  
end

require Redcar::ROOT + '/vendor/gtksourceview2/src/gtksourceview2'
require Redcar::ROOT + '/vendor/gtkmateview/dist/gtkmateview'
Gtk::Mate.textmate_dir = Redcar::ROOT + "/textmate"

load File.dirname(__FILE__) + "/lib/document.rb"
load File.dirname(__FILE__) + "/lib/edit_view.rb"
Dir[File.dirname(__FILE__) + "/lib/*.rb"].each {|f| load f}
load File.dirname(__FILE__) + "/commands/snippet_command.rb"
Dir[File.dirname(__FILE__) + "/commands/*.rb"].each {|f| load f}
