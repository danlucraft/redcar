
require 'gtk2'

module Gtk
	GTK_PENDING_BLOCKS = []
  GTK_PENDING_BLOCKS_LOCK = Monitor.new

  class << self
    attr_reader :thread
  end

  def Gtk.queue(&block)
    if Thread.current == Gtk.thread
      block.call
    else
      GTK_PENDING_BLOCKS_LOCK.synchronize do
       GTK_PENDING_BLOCKS << block
      end
    end
  end

  def self.execute_pending_blocks
    GTK_PENDING_BLOCKS_LOCK.synchronize do
      GTK_PENDING_BLOCKS.each do |block|
        block.call
      end
      GTK_PENDING_BLOCKS.clear
    end
  end

	def Gtk.main_with_queue(timeout)
		@thread = Thread.current
    Gtk.timeout_add timeout do
      execute_pending_blocks
      true
    end
    Gtk.main
	end

  class Widget
    alias old_initialize initialize
    def initialize
      old_initialize
      signal_connect('move_focus') do |_, _, _|
        p :grab_notify
        false
      end
    end
    
    def hierarchy
      if parent
        [self] + parent.hierarchy
      else
        [self]
      end
    end
  end

  class Dialog
    alias :old_run :run
    
    class << self
      def _cucumber_running_dialogs
        @_cucumber_running_dialogs ||= []
      end
    end
    
    def run(*args, &block)
      if defined?(Redcar::Testing) and Redcar::Testing::InternalCucumberRunner.in_cucumber_process
        show_all
        Dialog._cucumber_running_dialogs << self
        signal_connect('response') do |_, response|
          block.call(response)
          Dialog._cucumber_running_dialogs.delete(self)
        end
      else
        old_run(*args, &block)
      end
    end
  end
  
  class Icon
    def self.get(name)
      icon = eval("Gtk::Stock::"+name.to_s.upcase)
    end
    def self.get_image(name, size=Gtk::IconSize::DND)
      Gtk::Image.new(self.get(name), size)
    end
  end
  
  class ImageMenuItem
    # Helper to create a Gtk::ImageMenuItem from a string
    # corresponding to a Gtk::Stock constant, and a string
    # of text for the item label.
    # e.g. stock_name = "FILE" -> Gtk::Stock::FILE.
    def self.create(stock_name, text)
      gtk_menuitem = Gtk::ImageMenuItem.new(text)
      stock = Gtk::Stock.const_get(stock_name)
      iconimg = Gtk::Image.new(stock, 
                               Gtk::IconSize::MENU)
      gtk_menuitem.image = iconimg
      gtk_menuitem
    end
  end
  
  class MenuItem
    attr_accessor :redcar_position
  end

  class Notebook
    # Returns the child widget of the current page.
    def page_child
      get_nth_page page
    end
  end
  
  class TextTag
    attr_accessor :edit_view_depth
  end
  
  # A simple notebook "label" (HBox container) with a text label and 
  # a close button.
  class NotebookLabel < HBox
    type_register
    
    # Creates a new notebook label labeled with the text *str*.
    def initialize(tab, str='', icon=nil, &on_close)
      super()
      self.homogeneous = false
      self.spacing = 4
      
      @box = Gtk::HBox.new
      
      if icon
        @icon = Icon.get_image(icon, Gtk::IconSize::MENU)
      end
      
      @label = Gtk::Label.new(str)
      
      @button = Gtk::Button.new
      @button.set_border_width(0)
      @button.set_size_request(22, 22)
      @button.set_relief(Gtk::RELIEF_NONE)
      
      image = Gtk::Image.new
      image.set(:'gtk-close', Gtk::IconSize::MENU)
      @button.add(image)
      
      pack_start(@box)
      
      @box.pack_start(@icon, false, false, 5) if @icon
      @box.pack_start(@label, true, false, 0)
      @box.pack_start(@button, false, false, 0)
      @button.signal_connect('clicked') do |widget, event|
        on_close.call if on_close
      end
      show_all
    end
    
    attr_reader :label, :button
    
    def make_horizontal
      unless @box.is_a? Gtk::HBox
        self.remove @box
        @box.remove @label
        @box.remove @button
        @box = Gtk::HBox.new
        @box.pack_start(@label, true, false, 0)
        @box.pack_start(@button, false, false, 0)
        pack_start @box
        @box.show
      end
    end
      
    def make_vertical
      unless @box.is_a? Gtk::VBox
        self.remove @box
        @box.remove @label
        @box.remove @button
        @box = Gtk::VBox.new
        @box.pack_start(@label, true, false, 0)
          @box.pack_start(@button, false, false, 0)
        pack_start @box
        @box.show
      end
    end
    
    def text
      @label.text
    end
    
    def text=(t)
      @label.text = t
    end
  end
end
