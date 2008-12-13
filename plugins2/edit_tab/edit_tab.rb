
module Redcar
  class EditTabPlugin < Redcar::Plugin
    def self.load(plugin) #:nodoc:
      Hook.register :tab_changed
      Hook.register :tab_save
      Hook.register :tab_load
      
      Sensitive.register(:edit_tab, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab]) do
        Redcar.win and Redcar.tab and Redcar.tab.is_a? EditTab
      end
      
      Sensitive.register(:modified?, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab, :tab_changed, 
                          :after_tab_save]) do
        Redcar.tab and Redcar.tab.is_a? EditTab and Redcar.tab.modified
      end
      
      Sensitive.register(:modified_and_filename?, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab, :tab_changed, 
                          :after_tab_save]) do
        Redcar.tab and Redcar.tab.is_a? EditTab and Redcar.tab.modified and Redcar.tab.filename
      end
      
      Hook.attach :after_open_window do
        Redcar::EditTab.create_grammar_combo
        Redcar::EditTab.create_line_col_status
      end

      Hook.attach :after_focus_tab do |tab|
        gtk_combo_box = bus('/gtk/window/statusbar/grammar_combo').data
        gtk_line_label = bus('/gtk/window/statusbar/line').data
        # TODO remove this hardcoded reference
        if tab and tab.is_a? EditTab
          list = Gtk::Mate::Buffer.bundles.map{|b| b.grammars }.flatten.map(&:name).sort
          gtk_combo_box.sensitive = true
          if tab.document.parser
            gtk_combo_box.active = list.index(tab.document.parser.grammar.name)
          end
          gtk_line_label.sensitive = true
        else
          gtk_combo_box.sensitive = false
          gtk_combo_box.active = -1
          gtk_line_label.sensitive = false
        end
      end

#       Sensitive.register(:selected_text, 
#                          [:open_window, :new_tab, :close_tab, 
#                           :after_focus_tab]) do
#         win and tab and tab.is_a? EditTab
#       end

      Dir[File.dirname(__FILE__) + "/lib/*"].each {|f| Kernel.load f}
      Dir[File.dirname(__FILE__) + "/tabs/*"].each {|f| Kernel.load f}
      Kernel.load File.dirname(__FILE__) + "/commands/edit_tab.rb"
      Dir[File.dirname(__FILE__) + "/commands/*"].each {|f| Kernel.load f}
      Kernel.load File.dirname(__FILE__) + "/widgets/font_chooser_button.rb"
      Kernel.load File.dirname(__FILE__) + "/preferences.rb"

      bus("/redcar/bundles/").children.each do |child_slot|
#        p child_slot.name
        bundle = child_slot.data
        commands_slot = child_slot["commands"]
        bundle.commands.each do |uuid, hash|
#          p hash["name"] if hash["name"] == "New Method"
          #          p Bundle.translate_key_equivalent(hash["keyEquivalent"])
          new_command = Class.new(Redcar::ShellCommand)
          new_command.range Redcar::EditTab
          if key = Bundle.translate_key_equivalent(hash["keyEquivalent"], bundle.name + " | " + hash["name"])
            new_command.key key
          end
          new_command.scope hash["scope"]
          if hash["input"]
            new_command.input hash["input"].underscore.intern
          end
          if hash["fallbackInput"]
            new_command.fallback_input hash["fallbackInput"].underscore.intern
          end
          if hash["output"]
            new_command.output hash["output"].underscore.intern
          end
          
          new_command.tm_uuid = uuid
          new_command.bundle = bundle
          new_command.shell_script = hash["command"]
          new_command.name = hash["name"]

          command_slot = commands_slot[uuid]
          command_slot.data = new_command
        end
      end

      Bundle.build_bundle_menus

      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin) #:nodoc:
      plugin.transition(FreeBASE::RUNNING)
    end

  end
end
