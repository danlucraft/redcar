
InDir   = "textmate/Bundles/*"
OutFile = "scripts/textmate_support/image.yaml"

require 'lib/redcar'
require 'pp'
require 'vendor/keyword_processor'
require 'vendor/ruby_extensions'

def rubyize(camelcase)
  words = camelcase.split(/(?=[A-Z])/).map {|w| w.downcase }
  r = words.join("_")
  r = :show_as_html if r == :show_as_h_t_m_l
end

def parse_keycombination(comb)
  return nil unless comb
  mods = []
  if comb.include? "^"
    mods << :control
  end
  if comb.include? "@"
    mods << :super
  end
  if comb.include? "~"
    mods << :alt
  end
  letter = comb[-1..-1]
  ks = Redcar.KeyStroke.new(mods, letter)
end

def get_info(name, items)
  chash = Redcar.Plist.xml_to_plist(File.read("textmate/Bundles/"+name+".tmbundle/info.plist"))[0]
  items[chash["uuid"]] = {
    :tags => [:bundle, :textmate],
    :created => Time.now,
    :description => chash["description"],
    :contact_name => chash["contactName"],
    :contact_email_rot13 => chash["contactEmailRot13"]
  }
  chash["uuid"]
end

def get_commands(name, bundle_uuid, items)
  Dir["textmate/Bundles/"+name+".tmbundle/Commands/*"].each do |filename|
    chash = Redcar.Plist.xml_to_plist(File.read(filename))[0]
    
    auto_scroll_output = chash["autoScrollOutput"]
    if chash.keys.include? "autoScrollOutput" and !auto_scroll_output
      auto_scroll_output = false
    end
    
    disable_output_auto_indent = chash["disableOutputAutoIndent"]
    if chash.keys.include? "disableOutputAutoIndent" and !disable_output_auto_indent
      disable_output_auto_indent = false
    end
    
    redcar_chash = {
      :type => :shell,
      :name => chash["name"],
      :command => chash["command"],
      :scope => chash["scope"],
      :before_running_command => chash["beforeRunningCommand"],
      :uuid => chash["uuid"],
      :output => rubyize(chash["output"]),
      :tab_trigger => chash["tabTrigger"],
      :input => chash["input"],
      :fallback_input => chash["fallbackInput"],
      :activated_by_value => parse_keycombination(chash["keyEquivalent"]),
      :auto_scroll_output => auto_scroll_output,
      :bundle_uuid => bundle_uuid,
      :file_capture_register => chash["fileCaptureRegister"],
      :capture_pattern => chash["capturePattern"],
      :capture_format_string => chash["captureFormatString"],
      :line_capture_register => chash["lineCaptureRegister"],
      :disable_output_auto_indent => disable_output_auto_indent,
      :tags => [:textmate, :command],
      :created => Time.now
    }
    items[redcar_chash[:uuid]] = redcar_chash
  end
end

def get_snippets(name, bundle_uuid, items)
  Dir["textmate/Bundles/"+name+".tmbundle/Snippets/*"].each do |filename|
    chash = Redcar.Plist.xml_to_plist(File.read(filename))[0]
    items[chash["uuid"]] = {
      :tags => [:textmate, :snippet],
      :bundle_uuid => bundle_uuid,
      :created => Time.now,
      :name => chash["name"],
      :scope => chash["scope"],
      :tab_trigger => chash["tabTrigger"],
      :content => chash["content"],
      :input_pattern => chash["inputPattern"]
    }
  end
end

def get_macros(name, bundle_uuid, items)
  Dir["textmate/Bundles/"+name+".tmbundle/Macros/*"].each do |filename|
    chash = Redcar.Plist.xml_to_plist(File.read(filename))[0]
    commands = chash["commands"].map do |command_hash|
      {
        :command => command_hash["command"],
        :argument => command_hash["argument"]
      }
    end
    items[chash["uuid"]] = {
      :tags => [:textmate, :macro],
      :created => Time.now,
      :bundle_uuid => bundle_uuid,
      :name => chash["name"],
      :scope => chash["scope"],
      :scope_type => chash["scopeType"],
      :key_equivalent => chash["keyEquivalent"],
      :commands => commands
    }
  end
end

def get_menus(name, bundle_uuid, items)
  chash = Redcar.Plist.xml_to_plist(File.read("textmate/Bundles/"+name+".tmbundle/info.plist"))[0]
  
  tm_submenus = (chash["mainMenu"]||{})["submenus"]||{}
  submenus = {}
  tm_submenus.each do |uuid, smh|
    submenus[uuid] = {
      :name => smh["name"],
      :items => smh["items"]
    }
  end
  
  items[chash["uuid"]] = {
    :tags => [:textmate, :menus],
    :created => Time.now,
    :bundle_uuid => bundle_uuid,
    :description => chash["description"],
    :items => (chash["mainMenu"]||{})["items"],
    :excluded_items => (chash["mainMenu"]||{})["excludedItems"],
    :submenus => submenus,
    :deleted => chash["deleted"],
    :ordering => chash["ordering"]
  }
end

def with_feedback
  begin
    yield
    print "."
    $stdout.flush
  rescue
    print "x"
    $stdout.flush
  end
end

def get_bundle(name, hash)
  name1 = name[0..25]
  name1 = name1+" "*(26-name1.length)
  print name1+" ["; $stdout.flush
  bundle_uuid = nil
  with_feedback { bundle_uuid = get_info(name, hash)    }
  with_feedback { get_commands(name, bundle_uuid, hash) }
  with_feedback { get_snippets(name, bundle_uuid, hash) }
  with_feedback { get_macros(name, bundle_uuid, hash)   }
#  with_feedback { get_grammars(name, bundle_uuid, hash) }
  with_feedback { get_menus(name, bundle_uuid, hash)    }
  puts "]"
end

bundle_names = Dir[InDir].
  select  {|d| d.include? ".tmbundle" }.
  map     {|d| d =~ /textmate\/Bundles\/(.+)\.tmbundle/; $1 }.
  sort_by {|d| d.downcase }

items = {}

puts
puts "Importing (#{bundle_names.length}) TextMate bundles to Redcar image file"
puts "  input directory glob : #{InDir}"
puts "  output file          : #{OutFile}"
puts 

doit = true
if File.exist? "scripts/textmate_support/image.yaml"
  puts "output file exists, overwrite y/n? [y]"
  f = gets.chomp
  unless f == "" or f.downcase == "y"
    doit = false
  end
end

if doit
  bundle_names.each do |name|
    get_bundle(name, items)
  end
  puts "(done)."
else
  puts "aborted."
end
  
File.open("scripts/textmate_support/image.yaml", "w") do |f|
  f.puts items.to_yaml
end
