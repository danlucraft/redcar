
module Redcar
  class EditViewPlugin < Redcar::Plugin
    def self.load(plugin) #:nodoc:
      Redcar::EditView::Indenter.lookup_indent_rules
      Redcar::EditView::AutoPairer.lookup_autopair_rules
      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin) #:nodoc:
      Redcar::EditView::SnippetInserter.load_snippets
      Hook.attach :after_open_window do
#         create_grammar_combo
#         create_line_col_status
      end
      Hook.attach :after_focus_tab do |tab|
#         gtk_combo_box = bus('/gtk/window/statusbar/grammar_combo').data
#         gtk_line_label = bus('/gtk/window/statusbar/line').data
#         if tab and tab.is_a? EditTab
#           list = Redcar::EditView::Grammar.names.sort
#           gtk_grammar_combo_box.sensitive = true
#           gtk_grammar_combo_box.active = list.index(tab.view.parser.root.grammar.name)
#           gtk_line_label.sensitive = true
#         else
#           gtk_grammar_combo_box.sensitive = false
#           gtk_grammar_combo_box.active = -1
#           gtk_line_label.sensitive = false
#         end
      end
      plugin.transition(FreeBASE::RUNNING)
    end

    def self.stop(plugin) #:nodoc:
#       Redcar::EditView::Theme.cache
      plugin.transition(FreeBASE::LOADED)
    end
  end  
end

Dir[File.dirname(__FILE__) + "/commands/*"].each {|f| load f}
Dir[File.dirname(__FILE__) + "/lib/*"].each {|f| load f}
