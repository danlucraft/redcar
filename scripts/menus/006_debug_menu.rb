$debug_puts = false

Redcar.menu("_Debug") do |menu|
  menu.command("Toggle Debug Puts", :toggle_debug_puts) do
    $debug_puts = !$debug_puts
  end
  
  menu.command("Redcar Interaction", :redcar_interaction) do
    Redcar.new_tab(Redcar::RedcarInteractionTab).focus
  end
  
  menu.command("_Current Tab", :current_tab, nil, "<ctl>t") do |pane, tab|
    tab = Redcar.current_tab
    tab.contents += "\nThis One!!\n"
  end
    
  menu.command("_View Clipboard", :view_clipboard, :dnd_multiple, "<control><alt>v") do
    unless nt = Redcar.tabs["#clipboard"]
      nt = Redcar.tabs.new
      nt.name = "#clipboard"
    end
    nt.contents = Clipboard.to_a.join("\n"+"-"*50+"\n")
    nt.focus  
    nt.modified = false
  end
  
  def indented_array(array, indent, instr)
    str = instr
    array.each do |el|
      if el.is_a? Array
        str = indented_array(el, indent+2, str)
      else
        str << " "*indent+el.inspect+"\n"
      end
    end
    str
  end
  
  menu.command("View Undo Stack", :view_undo_stack) do |pane, tab|
    unless nt = Redcar.tabs["#undo"]
      nt = pane.new_tab
      nt.name = "#undo"
    end
    nt.contents = indented_array(tab.undo_stack, 0, "")
    nt.focus  
    nt.modified = false
  end
  
  menu.command("View Command History", :view_command_history) do |pane, tab|
    unless nt = Redcar.tabs["#commands"]
      nt = Redcar.new_tab
      nt.name = "#commands"
    end
    str = tab.command_history.reverse.map{|arr| arr[0].to_s+"("+arr[1].map(&:inspect).join(", ") + ")"}
    nt.contents = "Command History\n(most recent first)\n\n"+
      str.join("\n")
    nt.focus
    nt.modified = false
  end
      
  menu.command("View Keystroke History", :view_keystroke_history) do
    unless nt = Redcar.tabs["#keystrokes"]
      nt = Redcar.new_tab
      nt.name = "#keystrokes"
    end
    backkeys = Redcar.keystrokes.history.reverse
    p backkeys
    keys = backkeys.map {|el| (el.to_s==" "? '" "' : el.to_s)}
    commands = backkeys.map do |el| 
      com=Redcar::Keymap.get_keymap(el).get_keymap(el)
    end.tap{|list| puts list; puts}.map do |com|
      com[0].to_s+"("+com[1].map(&:inspect).join(", ")+")"
    end
    str = ""
    max_key_length = keys.map {|k| k.length+3}.max
    keys.zip(commands) do |k, c|
      str << k+" "*(max_key_length-k.length)+
        "-> "+c +"\n"
    end
    nt.contents = "Keystroke History\nsize:#{Redcar.keystrokes.history_size}\n"+
      "(most recent first)\n\n"+str
    nt.focus
    nt.modified = false
  end
  
  menu.command("Colour Buffer", :colour_buffer) do |pane, tab|
    th = $themes["Twilight"]
    tab.apply_theme(th)
    sc = Redcar::Syntax::Scope.new(:pattern => $grammars['Ruby'],
                   :grammar => $grammars['Ruby'],
                   :start => Redcar::Syntax::TextLoc.new(0, 0))
    pr = Redcar::Syntax::Parser.new(sc, [$grammars['Ruby']], "")
    start1 = Time.now
    pr.add_lines(tab.contents)
    end1 = Time.now
    diff1 = end1-start1
    puts "parsed in #{diff1}"
    start2 = Time.now
    colr = Redcar::Colourer.new(th)
    colr.colour(tab.buffer, pr.scope_tree)
    end2 = Time.now
    diff2 = end2-start2
    puts "coloured in #{diff2}"
#     Thread.new do
#       pr.add_lines(tab.get_lines(50..-1).join)
#       colr.colour(tab.buffer, pr.scope_tree)
#     end
  end
  
  menu.command("_Modified?", :modified) do
    ct = Redcar.tabs.current
    ct.contents += ct.modified?.to_s
  end
  
  menu.separator
  
  menu.command("Replace Test", :replace_test) do |pane, tab|
    lines = tab.contents.to_s.split("\n")
    newlines = lines.collect do |line|
      if rand < 0.2
        p :rand
        line[10] = "foo"
      end
      line
    end
    p newlines.join("\n")
    tab.contents.replace(newlines.join("\n"))
  end
  
  menu.command("Command Speedbar", :command_speedbar, :execute, "<ctl>e") do |pane, tab|
    speedbar = Redcar::Speedbar.build(:title => "Command",
                                      :buttons => [:Execute, :ok],
                                      :entry => [
                                                 {:name => :command_string, :type => :text}
                                                ])
    speedbar.on_button(:ok) { speedbar.close; $sb_find = nil }
    speedbar.on_button(:Execute) do 
      tab.instance_eval do
        begin
          pp eval(speedbar.command_string)
        rescue Object => e
          p e
        end
      end
    end
    speedbar.show
  end
  
  menu.command("Tabs", :tabs) do
    pp Redcar.current_window.panes.tabs_array
  end
end
