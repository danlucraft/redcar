
require 'gtk2'
Here = File.dirname(__FILE__)+"/"
require Here+'sourceview'

class SsvExampleWindow < Gtk::Window
  include Redcar

  def initialize
    super("Redcar::SyntaxSourceView")
    set_size_request(800, 600)
    
    sw = Gtk::ScrolledWindow.new
    sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    @sv = SyntaxSourceView.new(:bundles_dir => Here+"../../textmate/Bundles/",
                              :themes_dir  => Here+"../../textmate/Themes/",
                              :cache_dir   => Here+"../../cache/")
    
    @sv.buffer.text = File.read($0)
    sw.add(@sv)
    
    toolbar = Gtk::Toolbar.new
    
    toolbar.append(make_language_combo)
    toolbar.append(make_theme_combo)
    
    vbox = Gtk::VBox.new
    vbox.pack_start(toolbar, false, true)
    vbox.pack_start(sw)
    
    add(vbox)
    signal_connect("destroy") { Gtk.main_quit }
    show_all
  end
  
  def make_language_combo
    language_combo = Gtk::ComboBox.new(true)
    SyntaxSourceView.grammar_names.sort.each do |n| 
      language_combo.append_text(n)
    end
    language_combo.active = SyntaxSourceView.grammar_names.sort.index("Ruby")
    language_combo.signal_connect("changed") do |combo|
      @sv.set_syntax(combo.active_text)
    end
    language_combo
  end
  
  def make_theme_combo
    theme_combo = Gtk::ComboBox.new(true)
    Theme.theme_names.sort.each do |n| 
      theme_combo.append_text(n)
    end
    theme_combo.active = Theme.theme_names.sort.index("Twilight")
    theme_combo.signal_connect("changed") do |combo|
      @sv.set_theme(Theme.theme(combo.active_text))
    end
    theme_combo
  end
end

SsvExampleWindow.new
Gtk.main

