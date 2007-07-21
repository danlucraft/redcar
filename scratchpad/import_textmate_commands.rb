

require 'lib/redcar'
require 'pp'
require 'vendor/keyword_processor'

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

def get_commands(items)
  Dir["textmate/Bundles/*.tmbundle/Commands/*"].each do |filename|
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
      :bundle_uuid => chash["bundleUUID"],
      :file_capture_register => chash["fileCaptureRegister"],
      :capture_pattern => chash["capturePattern"],
      :capture_format_string => chash["captureFormatString"],
      :line_capture_register => chash["lineCaptureRegister"],
      :disable_output_auto_indent => disable_output_auto_indent
    }
    items[redcar_chash[:uuid]] = {
      :tags => [:textmate, :command],
      :definitions => [{
                         :type => :master,
                         :version => 1,
                         :data => redcar_chash
                       }]}
  end
  
  File.open("scripts/textmate_support/image.yaml", "w") do |f|
    f.puts items.to_yaml
  end
end

def get_menu_layouts_and_infos(items)
  Dir["textmate/Bundles/*.tmbundle/info.plist"].each do |filename|
    chash = Redcar.Plist.xml_to_plist(File.read(filename))[0]
    pp chash
    gets
    
    bundle = {
      :name => chash["name"],
      :contact_name => chash["contactName"],
      :contact_email_rot13 => chash["contactEmailRot13"],
      :uuid => chash["uuid"],
      :description => chash["description"]
      
    }
    
    tm_submenus = (chash["mainMenu"]||{})["submenus"]||{}
    submenus = {}
    tm_submenus.each do |uuid, smh|
      submenus[uuid] = {
        :name => smh["name"],
        :items => smh["items"]
      }
    end
    
    menu_layout = {
      :items => (chash["mainMenu"]||{})["items"],
      :excluded_items => (chash["mainMenu"]||{})["excludedItems"],
      :submenus => submenus
    }
    
    pp menu_layout
    gets
  end
end

items = {}

#get_commands(items)
get_menu_layouts_and_infos(items)
