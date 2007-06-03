
Bundles = []

require 'pp'

Redcar.menu("_Textmate") do |menu|
  menu.command("XML to _plist", :xml_to_plist) do |pane, tab|
    new_tab = Redcar.new_tab
    p new_tab.class
    result = Redcar::Plist.plist_from_xml(tab.to_s)
    str = ""
    def str.write(text)
      self << text
    end
    $stdout = str
    pp result
    $stdout = STDOUT
    new_tab.contents = str
    new_tab.focus
    new_tab.modified = false
    tab.modified = false
  end
  
  menu.command("plist to _XML", :plist_to_xml) do |pane, tab|
    new_tab = Redcar.new_tab
    plist = eval(tab.contents)
    result = Redcar::Plist.plist_to_xml(plist)
    new_tab.contents = result
    new_tab.focus
    new_tab.modified = false
    tab.modified = false
  end
end

module Redcar
  class TextmateBundle
    def initialize(dir)
      @dir = dir
      info_plist = IO.readlines(@dir + 'info.plist').join
      @bundle_info = Redcar::Plist.plist_from_xml(info_plist)[0]
      @bundle_items = {}
      load_snippets
      load_commands
      Bundles << self
    end
    
    def load_snippets
      @snippets = {}
      Dir.glob(@dir+"Snippets/*").each do |file|
        snippet = {}
        key = nil
        content = nil
        contents = IO.readlines(file).join
        snippet_xml = REXML::Document.new(contents)
        snippet_xml.root.each_element do |dict|
          dict.each_element do |node|
            #  puts "#{node.name}: #{node.text}"
            if node.name == "key"
              key = node.text
            else
              snippet[key] = node.text
            end
          end
        end
        @snippets[snippet["tabTrigger"]] = snippet
        @bundle_items[snippet["uuid"]] = snippet
        #  p snippet
      end
    end

    def load_commands
      @commands = {}
      Dir.glob(@dir+"Commands/*").each do |file|
        # puts
        # p file
        command = {}
        key = nil
        content = nil
        contents = IO.readlines(file).join
        command_xml = REXML::Document.new(contents)
        command_xml.root.each_element do |dict|
          dict.each_element do |node|
            #  puts "#{node.name}: #{node.text}"
            if node.name == "key"
              key = node.text
            else
              command[key] = node.text
            end
          end
        end
        @commands[command['name']] = command
        @bundle_items[command["uuid"]] = command
        #  p command
      end
    end
    
    def build_menu(menu, menu_hash=@bundle_info['mainMenu']['items'])
      menu_hash.each do |uuid|
        if uuid =~ /---------/
          bundle_menu_item = Gtk::SeparatorMenuItem.new
          menu.separator
        elsif item = @bundle_items[uuid]
          menu.command(item['name'].gsub("_", "-")+"//"+item['tabTrigger'].to_s, item['name'].downcase.intern) do
            puts "activated #{item['name']}"
            Redcar.tabs.current.contents = item['command']
          end
        elsif @bundle_items[uuid] == nil
          submenu_hash = @bundle_info['mainMenu']['submenus'][uuid]
          if submenu_hash
            menu.submenu(submenu_hash['name']) do |submenu|
              build_menu(submenu, submenu_hash['items'])
            end
          end
        end
      end
    end
    
    def check_for_tab_trigger(string)
      @snippets.each do |key, value|
        unless key == nil
          puts "#{key.inspect} : #{string[(string.length-key.length)..(string.length-1)].inspect}"
          if string[(string.length-key.length)..(string.length-1)] == key
            return value
          end
        else
          puts "nil key for snippet"
        end
      end
      nil
    end
  end
end

ruby = Redcar::TextmateBundle.new(Redcar.ROOT_PATH+'/textmate/bundles/Ruby.tmbundle/')
Redcar.menu("Ruby") do |menu|
  ruby.build_menu(menu)
end
