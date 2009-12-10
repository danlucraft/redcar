require 'java'
require "plugins/application_swt/lib/application_swt/swt_wrapper"

class SwtExample
  def initialize
    Swt::Widgets::Display.set_app_name "Ruby SWT Test"

    @display = Swt::Widgets::Display.new
    @shell = Swt::Widgets::Shell.new(@display)
    @shell.setSize(450, 200)
    layout = Swt::Layout::FillLayout.new
    @shell.setLayout layout
    create_tree_view
    
    @shell.pack
    @shell.open
  end
  
  class TestContentProvider
    include JFace::Viewers::ITreeContentProvider
    
    def input_changed(viewer, _, tree)
      @viewer, @tree = viewer, tree
    end
    
    def get_elements(tree)
      tree.keys.to_java
    end
    
    def has_children(key)
      @tree[key].is_a?(Hash)
    end
    
    def get_children(key)
      @tree[key].keys.to_java
    end
    
    def dispose
    end
  end
  
  class TestLabelProvider
    include JFace::Viewers::ILabelProvider
    
    def add_listener(*_)
    end
    
    def remove_listener(*_)
    end
    
    def get_text(key)
      key
    end
    
    def get_image(_)
      nil
    end
    
    def dispose
    end
  end
  
  def create_tree_view
    tree = {
      "foo" => "bar",
      "baz" => "qux",
      "quux" => {
        "corge" => "foo"
      }
    }
    @viewer = JFace::Viewers::TreeViewer.new(@shell)
    @viewer.set_content_provider(TestContentProvider.new)
    @viewer.set_input(tree)
    @viewer.set_label_provider(TestLabelProvider.new)
  end
  
  def start
    while (!@shell.isDisposed) do
      @display.sleep unless @display.readAndDispatch
    end

    @display.dispose
  end
end

app = SwtExample.new
app.start

