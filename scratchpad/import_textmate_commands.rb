
InDir   = "textmate/Bundles/*"
OutFile = "scripts/textmate_support/image.yaml"

require 'lib/redcar'
require 'pp'
require 'vendor/keyword_processor'
require 'vendor/ruby_extensions'
require 'md5'

BundleMenuUUID = "9ccd2a50-2d98-012a-20c0-000ae4ee635c"

def rubyize(camelcase)
  return nil unless camelcase
  words = camelcase.split(/(?=[A-Z])/).map {|w| w.downcase }
  r = words.join("_").intern
  r = :show_as_html if r == :show_as_h_t_m_l
  r
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
    :name => name,
    :directory => "textmate/Bundles/"+name+".tmbundle/",
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
      :input => rubyize(chash["input"]),
      :fallback_input => rubyize(chash["fallbackInput"]),
      :activated_by_value => parse_keycombination(chash["keyEquivalent"]),
      :auto_scroll_output => auto_scroll_output,
      :bundle_uuid => bundle_uuid,
      :file_capture_register => chash["fileCaptureRegister"],
      :capture_pattern => chash["capturePattern"],
      :capture_format_string => chash["captureFormatString"],
      :line_capture_register => chash["lineCaptureRegister"],
      :disable_output_auto_indent => disable_output_auto_indent,
      :tags => [:command],
      :created => Time.now,
      :visible => true,
      :enabled => true
    }
    items[redcar_chash[:uuid]] = redcar_chash
  end
end

def get_snippets(name, bundle_uuid, items)
  Dir["textmate/Bundles/"+name+".tmbundle/Snippets/*"].each do |filename|
    chash = Redcar.Plist.xml_to_plist(File.read(filename))[0]
    items[chash["uuid"]] = {
      :tags => [:snippet],
      :bundle_uuid => bundle_uuid,
      :created => Time.now,
      :name => chash["name"],
      :scope => chash["scope"],
      :tab_trigger => chash["tabTrigger"],
      :content => chash["content"],
      :input_pattern => chash["inputPattern"],
      :icon => "none",
      :visible => true,
      :enabled => true
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
      :tags => [:macro],
      :created => Time.now,
      :bundle_uuid => bundle_uuid,
      :name => chash["name"],
      :scope => chash["scope"],
      :scope_type => chash["scopeType"],
      :key_equivalent => chash["keyEquivalent"],
      :commands => commands,
      :icon => "none",
      :visible => true,
      :enabled => true
    }
  end
end

def get_menus(name, bundle_uuid, items)
  chash = Redcar.Plist.xml_to_plist(
            File.read("textmate/Bundles/"+name+".tmbundle/info.plist")
          )[0]
  if chash["mainMenu"]
    tm_submenus = (chash["mainMenu"]||{})["submenus"]||{}
    submenus = {}
    tm_submenus.each do |uuid, smh|
      items[uuid] = {
        :tags => [:menudef],
        :created => Time.now,
        :name    => smh["name"],
        :visible => true,
        :enabled => true,
        :icon    => "none"
      }
      submenus[uuid] = smh["items"]
    end
    
    menudef_id = MD5.new("daniellucraft70818bundle"+name).to_s
    items[menudef_id] = {
      :tags => [:menudef],
      :created => Time.now,
      :name    => name,
      :visible => true,
      :enabled => true,
      :icon    => "none",
      :position => name.downcase[0]
    }
    
    items[chash["uuid"]] = items[chash["uuid"]].merge({
      :tags => [:menu, :bundle],
      :created => Time.now,
      :bundle_uuid => bundle_uuid,
      :description => chash["description"],
      :toplevel => [BundleMenuUUID],
      :excluded_items => (chash["mainMenu"]||{})["excludedItems"],
      :submenus => {
        BundleMenuUUID => [menudef_id], 
        menudef_id => (chash["mainMenu"]||{})["items"]
      }.merge(submenus),
      :deleted => chash["deleted"],
      :ordering => chash["ordering"]
    })
  end
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

def get_bundle(name, items)
  name1 = name[0..25]
  name1 = name1+" "*(26-name1.length)
  print name1+" ["; $stdout.flush
  bundle_uuid = nil
  with_feedback { bundle_uuid = get_info(name, items)    }
  with_feedback { get_commands(name, bundle_uuid, items) }
  with_feedback { get_snippets(name, bundle_uuid, items) }
  with_feedback { get_macros(name, bundle_uuid, items)   }
#  with_feedback { get_grammars(name, bundle_uuid, items) }
  with_feedback { get_menus(name, bundle_uuid, items)    }
  
  puts "]"
end

bundle_names = Dir[InDir].
  select  {|d| d.include? ".tmbundle" }.
  map     {|d| d =~ /textmate\/Bundles\/(.+)\.tmbundle/; $1 }.
  sort_by {|d| d.downcase }

items = {}

items[BundleMenuUUID] = {
  :tags => [:menudef],
  :created => Time.now,
  :icon    => "none",
  :visible => true,
  :name    => "Bundles",
  :enabled => true
}

puts
puts "Importing (#{bundle_names.length}) TextMate bundles to Redcar image file"
puts "  input directory glob : #{InDir}"
puts "  output file          : #{OutFile}"
puts 

doit = true
if File.exist? "scripts/textmate_support/image.yaml" and
    !ARGV.include? "-f"
  puts "file exists, aborting. (use -f to force)"
  exit
end

if doit
  bundle_names.each do |name|
    get_bundle(name, items)
  end
else
  puts "aborted."
end
  
print "exporting to YAML..."; $stdout.flush
File.open("scripts/textmate_support/image.yaml", "w") do |f|
  f.puts items.to_yaml
end
puts " done."
puts "(done)."
