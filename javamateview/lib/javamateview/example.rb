
Dir[File.dirname(__FILE__) + "/*.jar"].each {|fn| require fn }
require File.join(File.dirname(__FILE__), *%w(.. src ruby java-mateview))

class MateExample < Jface::ApplicationWindow
  attr_reader :mate_text, :contents
  
  def initialize
    super(nil)
  end

  # this is another way of making a listener
  class MyListener
    include com.redcareditor.mate.IGrammarListener
    
    def grammarChanged(new_name)
      puts "listened for #{new_name} in #{self}"
    end
  end

  def createContents(parent)
    @contents = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
    @contents.layout = Swt::Layout::FillLayout.new
    @mate_text = JavaMateView::MateText.new(@contents, false)
    
    @mate_text.add_grammar_listener do |new_name|
      puts "listened for #{new_name} in #{self}"
    end
    @mate_text.set_grammar_by_name "Ruby"
    @mate_text.set_theme_by_name "Mac Classic"
    @mate_text.set_font "Monaco", 15
    return @contents
  end
  
  def initializeBounds
    shell.set_size(500,400)
  end
  
  def createMenuManager
    main_menu = Jface::MenuManager.new
    
    file_menu = Jface::MenuManager.new("Tests")
    main_menu.add file_menu
    
    replace1_action = ReplaceContents1.new
    replace1_action.window = self
    replace1_action.text = "Contents RUBY"
    file_menu.add replace1_action
    
    replace2_action = ReplaceContents2.new
    replace2_action.window = self
    replace2_action.text = "Contents HTML"
    file_menu.add replace2_action
    
    replace3_action = ReplaceContents3.new
    replace3_action.window = self
    replace3_action.text = "Contents long-lined JavaScript (slow)"
    file_menu.add replace3_action
    
    set_ruby_action = SetRuby.new
    set_ruby_action.window = self
    set_ruby_action.text = "Set Ruby Grammar"
    file_menu.add set_ruby_action
    
    set_html_action = SetHTML.new
    set_html_action.window = self
    set_html_action.text = "Set HTML Grammar"
    file_menu.add set_html_action
    
    set_java_script_action = SetJavaScript.new
    set_java_script_action.window = self
    set_java_script_action.text = "Set JavaScript Grammar"
    file_menu.add set_java_script_action
    
    set_mc_action = SetMacClassic.new
    set_mc_action.window = self
    set_mc_action.text = "Set Mac Classic"
    file_menu.add set_mc_action
    
    set_twilight_action = SetTwilight.new
    set_twilight_action.window = self
    set_twilight_action.text = "Set Twilight"
    file_menu.add set_twilight_action
    
    set_scopes_action = PrintScopeTree.new
    set_scopes_action.window = self
    set_scopes_action.text = "Print Scope Tree"
    file_menu.add set_scopes_action
    
    set_block_selection = SetBlockSelection.new
    set_block_selection.window = self
    set_block_selection.text = "Set Block Selection"
    file_menu.add set_block_selection

    set_block_selection = SetNotBlockSelection.new
    set_block_selection.window = self
    set_block_selection.text = "Set Not Block Selection"
    file_menu.add set_block_selection
    
    always_parse_all = AlwaysParseAll.new
    always_parse_all.window = self
    always_parse_all.text = "Always Parse All"
    file_menu.add always_parse_all
    
    toggle_invisibles = ToggleInvisibles.new
    toggle_invisibles.window = self
    toggle_invisibles.text = "Show/Hide Invisibles"
    file_menu.add toggle_invisibles
    
    toggle_word_wrap = ToggleWordWrap.new
    toggle_word_wrap.window = self
    toggle_word_wrap.text = "Toggle Word Wrap"
    file_menu.add toggle_word_wrap
    
    remove_annotations = RemoveAnnotations.new
    remove_annotations.window = self
    remove_annotations.text = "Remove Annotations"
    file_menu.add remove_annotations
    
    add_annotations = AddAnnotations.new
    add_annotations.window = self
    add_annotations.text = "Add Annotations"
    file_menu.add add_annotations

    return main_menu
  end
  
  class AddAnnotations < Jface::Action
    attr_accessor :window
    
    class AnnotationListener
      def initialize(mt)
        @mt = mt
      end
      
      def method_missing(event, *args)
        p [event, args]
      end
    end
    
    def run
      mt = @window.mate_text
      mt.add_annotation_type(
          "error.type", 
          File.dirname(__FILE__) + "/example/little-star.png",
          Swt::Graphics::RGB.new(200, 0, 0));
      mt.add_annotation_type(
          "happy.type", 
          File.dirname(__FILE__) + "/example/little-smiley.png",
          Swt::Graphics::RGB.new(0, 0, 200));
      mt.add_annotation("error.type", 1, "Learn how to spell \"text!\"", 5, 5);
      mt.add_annotation("happy.type", 1, "Learn how to spell \"text!\"", 50, 5);
      mt.add_annotation_listener(AnnotationListener.new(@window.mate_text))
      p [:online, 0, mt.annotations_on_line(0).to_a]
      p [:online, 1, mt.annotations_on_line(1).to_a]
      p [:online, 2, mt.annotations_on_line(2).to_a]
      p [:online, 3, mt.annotations_on_line(3).to_a]
      p [:online, 4, mt.annotations_on_line(4).to_a]
    end
  end

  class RemoveAnnotations < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.annotations.each {|a| @window.mate_text.removeAnnotation(a) }
    end
  end

  class ToggleWordWrap < Jface::Action
    attr_accessor :window
    
    def run
      mt = @window.mate_text
      mt.set_word_wrap(!mt.get_word_wrap)
    end
  end

  class ToggleInvisibles < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.showInvisibles(!@window.mate_text.showing_invisibles)
    end
  end

  class AlwaysParseAll < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.parser.parserScheduler.alwaysParseAll = true;
    end
  end
  
  class SetBlockSelection < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.get_text_widget.set_block_selection(true)
    end
  end
  
  class SetNotBlockSelection < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.get_text_widget.set_block_selection(false)
    end
  end
  
  class SetMacClassic < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.set_theme_by_name("Mac Classic")
    end
  end
  
  class PrintScopeTree < Jface::Action
    attr_accessor :window
    
    def run
      puts @window.mate_text.parser.root.pretty(0)
    end
  end
  
  class SetTwilight < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.set_theme_by_name("Twilight")
    end
  end
  
  class SetRuby < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.set_grammar_by_name("Ruby")
    end
  end
  
  class SetHTML < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.set_grammar_by_name("HTML")
    end
  end
  
  class SetJavaScript < Jface::Action
    attr_accessor :window
    
    def run
      @window.mate_text.set_grammar_by_name("JavaScript")
    end
  end
  
  class ReplaceContents1 < Jface::Action
    attr_accessor :window

    def run
      s = Time.now
      ##until Time.now - s > 120
      @window.mate_text.getMateDocument.set(File.read(File.dirname(__FILE__) + "/test_big_ruby_file.rb")*3)
      #@window.mate_text.getMateDocument.set("def foo")
      #end
      puts "parse took #{Time.now - s}s"
      puts "num scopes: #{@window.mate_text.parser.root.count_descendants}"
    end
    
    def source
      foo=<<-RUBY
class ExitAction < Jface::Action
  attr_accessor :window

  def run
    window.close
  end
end
      
RUBY
    end
  end
  
  class ReplaceContents2 < Jface::Action
    attr_accessor :window

    def run
      @window.mate_text.getMateDocument.set(source*50)
    end
    
    def source
      foo=<<-HTML
<div class="nav">
  <ul>
    <li>Foo</li>
    <li>Bar</li>
    <li>Baz</li>
  </ul>
</div>
      
HTML
    end
  end
  
  class ReplaceContents3 < Jface::Action
    attr_accessor :window

    def run
      src = File.read("lib/example/jquery-142min.js")
      s = Time.now
      @window.mate_text.getMateDocument.set(src)
      puts "parse took #{Time.now - s}s"
      puts "num scopes: #{@window.mate_text.parser.root.count_descendants}"
    end
  end
    
  def self.run
    JavaMateView::Bundle.load_bundles("input/")
    p JavaMateView::Bundle.bundles.to_a.map {|b| b.name }
    JavaMateView::ThemeManager.load_themes("input/")
    p JavaMateView::ThemeManager.themes.to_a.map {|t| t.name }
    
    window = MateExample.new
    window.block_on_open = true
    window.addMenuBar
    window.open
    Swt::Widgets::Display.getCurrent.dispose
  end
end

MateExample.run

