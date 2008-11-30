

module Redcar::Plugins
  module TextmateSupport
    extend FreeBASE::StandardPlugin
    extend Redcar::MenuBuilder
    extend Redcar::CommandBuilder
    extend Redcar::ContextMenuBuilder
    
    BUNDLE_CACHE_FILE = "cache/bundles.yml"
    BUNDLE_COMMAND_CACHE_FILE = "cache/bundle_commands.yml"
    
    def self.load(plugin)
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin)
      bundles = load_bundle_infos
      add_bundle_infos_to_databus(bundles)
      snippets = load_bundle_snippets(bundles.keys)
      commands = load_bundle_commands(bundles.keys)
      add_commands_to_databus(commands)
      add_commands_to_menus(bundles, commands)
      load_menu
      plugin.transition(FreeBASE::RUNNING)
    end
    
    # retrieves from the cache or the Bundles dir
    def self.load_bundle_infos
      if File.exists? BUNDLE_CACHE_FILE
        YAML.load(File.read(BUNDLE_CACHE_FILE))
      else
        bundles = {}
        Dir["textmate/Bundles/*"].each do |dir|
          info_plist = IO.read(dir + '/info.plist')
          info = Redcar::Plist.plist_from_xml(info_plist)[0]
          bundles[info["name"]] = info
        end
        File.open(BUNDLE_CACHE_FILE, "w") {|f| f.puts bundles.to_yaml }
        bundles
      end
    end
    
    def self.add_bundle_infos_to_databus(bundles)
      bundles.each do |name, hash|
        $BUS["/redcar/textmate-bundles/"+name].data = hash
      end
    end

    def self.add_commands_to_databus(commands)
      commands.each do |uuid, bc|
        command("Bundles/"+bc[:bundle_name]+
                "/"+bc["name"]) do |c|
          c.name = bc["name"].gsub("/", " or ")
          c.type = :shell
          c.command bc["command"]
          c.scope_selector = bc["scope"]
          c.input = bc["input"].intern
          c.fallback_input = (fi = bc["fallbackInput"]) ? fi.intern : "none"
          c.output = bc["output"].intern
          c.keybinding = decode_textmate_keyequivalent(bc["keyEquivalent"])
          c.tm_uuid = bc["uuid"]
        end
      end
    end
    
    # turns the textmate bundle keyequivalent into
    # a redcar keybinding
    # e.g. "^@O" -> "control-super O"
    def self.decode_textmate_keyequivalent(keyeq)
      if keyeq
        key_str      = keyeq.strip[-1..-1]
        modifier_str = keyeq.strip[0..-2]
        modifiers = modifier_str.split("").map do |modchar|
          case modchar
          when "^" # TM: Control
            "super"
          when "~" # TM: Option
            "alt"
          when "@" # TM: Command
            "control"
          end
        end
        modifiers.join("-") + " " + key_str.gsub("\e", "Escape")
      end
    end
    
    
    def self.load_bundle_commands(bundle_names)
      p :loading_bundle_commands
      if File.exists? BUNDLE_COMMAND_CACHE_FILE
        YAML.load(File.read(BUNDLE_COMMAND_CACHE_FILE))
      else
        commands = {}
        bundle_names.each do |bname|
          Dir.glob("textmate/Bundles/"+bname+".tmbundle/Commands/*").each do |file|
            command = {}
            key = nil
            content = nil
            contents = IO.read(file)
            command_xml = REXML::Document.new(contents)
            command_xml.root.each_element do |dict|
              dict.each_element do |node|
                if node.name == "key"
                  key = node.text
                else
                  command[key] = node.text
                end
              end
            end
            command["name"] = command["name"].gsub("/", " or ")
            command[:bundle_name] = bname
            commands[command["uuid"]] = command
          end
        end
        File.open(BUNDLE_COMMAND_CACHE_FILE, "w") {|f| f.puts commands.to_yaml }
        commands
      end
    end
    
    def self.load_bundle_snippets(bundle_names)
      p :skipping_bundle_snippets
    end
    
    def self.load_menu
      p :loading_menu
    end
  end
end
