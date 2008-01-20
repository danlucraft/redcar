
module Redcar
  module ToolbarBuilder
    def toolbar(name, options)
      options = process_params(options,
                               { :icon => :MANDATORY,
                                 :tooltip => "",
                                 :sensitive => nil,
                                 :text => "",
                                 :command => :MANDATORY
                               })
      $toolbarnum ||= 0
      $toolbarnum += 1
      slot = $BUS['/redcar/toolbars/'+name]
      slot.attr_tooltip = options[:tooltip]
      slot.attr_icon = options[:icon]
      slot.attr_text = options[:text]
      slot.attr_command = options[:command]
      slot.attr_id = $toolbarnum
    end
    
    def toolbar_separator(name)
      slot = $BUS['/redcar/toolbars/'+name+'/separator_'+$toolbarnum.to_s]
      slot.attr_id = $toolbarnum
      $toolbarnum += 1
    end
  end
  
  module Toolbar
    def self.set_toolbar_widget(name, widget)
      $BUS['/redcar/gtk/toolbars/'+name].data = widget
    end
    
    def self.get_toolbar_widget(name)
      $BUS['/redcar/gtk/toolbars/'+name].data
    end
    
    def self.draw_toolbars
      $BUS['/redcar/toolbars/'].each_slot do |slot|
        self.draw_toolbar(slot.name)
      end
    end
    
    def self.draw_toolbar(name)
      slot = $BUS['/redcar/toolbars/'+name]
      widget = $BUS['/redcar/gtk/toolbars/'+name].data
      widget.show_all
      slot.children.sort_by(&its.attr_id).each do |islot|
        if islot.name =~ /separator/
          widget.append_space
        else
          gtk_tb = widget.append(Redcar::Icon.get(islot.attr_icon), 
                                 islot.attr_tooltip) do
            c = $BUS['/redcar/commands/'+islot.attr_command.to_s].data
            command = Command.new(c)
            begin
              command.execute
            rescue Object => e
              puts e
              puts e.message
              puts e.backtrace
            end
          end
        end
      end
    end
  end
end
