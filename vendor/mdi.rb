# Gtk::MDI
# A tabbed window library for Ruby/GTK2
# version 0.1.2
#
# http://ruby-gnome2.sourceforge.jp/hiki.cgi?MDI
#
# Author:       Sam Stephenson <sstephenson@gmail.com>
# Contributors: Paul van Tilburg <paul@luon.net>
#
# License:
# Distributed under the same terms as Ruby/GTK2. For details,
# please see http://ruby-gnome2.sourceforge.jp/
#
# Changes:
# 2004-09-11  * 0.1.2 - document labels can now be custom 
#               Gtk::Widget widgets (Paul van Tilburg)
#             * added documentation for public methods (Paul
#               van Tilburg)
# 2004-07-10  * 0.1.1 - fixed a crash due to not ungrabbing the
#               pointer after migrating to a new window
#             * added Notebook#focus_document
#             * fixed crash in Notebook#button_press_cb when
#               index.nil?
# 2004-07-09  * initial release 0.1

require 'gtk2'

module Gtk
  module MDI

    # A simple notebook "label" (HBox container) with a text label and 
    # a close button.
    class NotebookLabel < HBox
      type_register

      # Creates a new notebook label labeled with the text *str*.
      def initialize(str='')
        super()
        self.homogeneous = false
        self.spacing = 4
        
        @label = Label.new(str)
        
        @button = Button.new
        @button.set_border_width(0)
        @button.set_size_request(20, 20)
        @button.set_relief(RELIEF_NONE)
        
        image = Image.new
        image.set(Gtk::Stock::CLOSE, IconSize::MENU)
        @button.add(image)
#         image1 = Image.new
#         image1.set(Gtk::Stock::FILE, IconSize::MENU)
        
#         pack_start(image1, true, false, 0)
        pack_start(@label, true, false, 0)
        pack_start(@button, false, false, 0)
        
        show_all
      end
      
      attr_reader :label, :button

      # Retrieves the text of the label.
      def text
        @label.text
      end

      # Sets the text of the label to *str*.
      def text=(str)
        @label.text = str
      end

    end # class Gtk::MDI::NotebookLabel


    # An MDI document container class.
    class Document < GLib::Object
      type_register
      signal_new('close',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'])

      # Creates a new document container holding the main *widget* and
      # label(-text) *label*.
      # Note that *label* can be a custom widget (Gtk::Widget).  If this
      # is not the case, *label* is assumed to be a string, and a generic
      # label with this text and a close button will be used.
      #
      # N.B. The custom widget must have the attributes _text_ (RW) and
      # _button_ (R) for the label text and close button, respectively.
      def initialize(widget, label)
        super()
        @widget = widget

        # Check if supplied label is a custom Gtk::Widget; consider
        # it to be a string otherwise.
        @label = if label.is_a? Widget
                   label
                 else 
                   NotebookLabel.new(label.to_s)
                 end

        @label.button.signal_connect('clicked') do |widget, event|
          signal_emit('close')
        end
      end
      
      attr_reader :widget, :label

      # Retrieves the title of the document container.
      def title
        @label.text
      end

      # Sets the title of the document container to *str*.
      def title=(str)
        @label.text = str
      end

    private

      def signal_do_close; end

    end # class Gtk::MDI::Document

    DragInfo = Struct.new('DragInfo', :in_progress, :x_start, :y_start,
                          :document, :motion_handler)

    # An MDI notebook widget that uses Gtk::MDI::Document objects and supports
    # drag-and-drop positioning.
    class Notebook < Gtk::Notebook
      type_register
      signal_new('document_added',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkMDIDocument'])  # the document that was added
      signal_new('document_removed',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkMDIDocument'],  # the document that was removed
                 GLib::Type['gboolean'])        # @documents.empty?
      signal_new('document_close',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkMDIDocument'])  # the document requesting close
      signal_new('document_drag',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkMDIDocument'],  # the document being dragged
                 GLib::Type['gint'],            # the pointer's x-coordinate
                 GLib::Type['gint'])            # the pointer's y-coordinate
      signal_new('document_dropped',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkMDIDocument'],  # the document that was dropped
                 GLib::Type['gint'],            # the drop x-coordinate
                 GLib::Type['gint'])            # the drop y-coordinate

      # Creates a new MDI notebook, holding Gtk::MDI::Document objects.
      def initialize
        super

        @documents = Array.new
        @handlers = Hash.new
        @drag_info = DragInfo.new(false)

        add_events(Gdk::Event::BUTTON1_MOTION_MASK)
        signal_connect('button-press-event') do |widget, event|
          button_press_cb(event)
        end
        signal_connect('button-release-event') do |widget, event|
          button_release_cb(event)
        end

        self.scrollable = true
      end

      attr_reader :drag_info

      # Adds the document *doc* (Gtk::MDI::Document) to the notebook.
      # Emits the 'document_added' signal.
      def add_document(doc)
        return if doc.nil?
        append_page(doc.widget, doc.label)

        h = Array.new
        h << doc.signal_connect('close') do
          signal_emit('document_close', doc)
        end
        @handlers[doc] = h

        @documents << doc
        signal_emit('document_added', doc)
      end

      # Removes the document *doc* (Gtk::MDI::Document) from the notebook.
      # Emits the 'document_removed' signal.
      def remove_document(doc)
        Redcar.tabs.tab_from_doc(doc).close
      end

      def do_remove_document(doc)
        return unless @documents.include? doc
        
        @handlers[doc].each do |handler|
          doc.signal_handler_disconnect(handler)
        end
        @handlers.delete(doc)
        
        @documents.delete(doc)
        remove_page(index_of_document(doc))
        signal_emit('document_removed', doc, @documents.empty?)
      end
      
      # Focuses (selects) the document *doc* in the notebook (i.e., 
      # makes it become the active document).
      def focus_document(doc)
        return unless @documents.include? doc
        index = index_of_document(doc)
        self.page = index
      end

      # Moves the document *doc* to the new index *new_index* and 
      # focuses it.
      def shift_document(doc, new_index)
        index = index_of_document(doc)
        return if index == new_index or index.nil? or new_index.nil?
        reorder_child(doc.widget, new_index)
        self.page = new_index
      end

      # Migrates the document *doc* to another notebook, namely *dest*
      # (Gtk::MDI::Notebook). If *dest* is not a notebook, this function
      # simply does nothing.
      # Emits a 'document_removed' signal for the source notebook and a
      # 'document_added' signal for the destination notebook. This
      # behavior may change in the future.
      def migrate_document(doc, dest)
        index = index_of_document(doc)
        return if index.nil? or not dest.is_a? Notebook

        drag_stop
        Gtk::grab_remove(self)
        remove_document(doc)

        dest.instance_eval do
          add_document(doc)
          drag_start
          @drag_info.document = doc
          @drag_info.motion_handler = signal_connect('motion-notify-event') do
            |widget, event|
            motion_notify_cb(event)
          end
        end
      end

      # Returns a list of documents contained in this notebook.
      def documents
        @documents.dup
      end

      # Returns the index of document *doc* in this notebook.
      def index_of_document(doc)
        children.index(doc.widget)
      end

      # Returns the document placed on the given *index*, or _nil_ if
      # the widget on the given index could not be traced back to a
      # document. 
      def document_at_index(index)
        page = children[index]
        @documents.each do |document|
          return document if document.widget == page
        end
        return nil
      end

      # Determines whether the coordinate (*x*, *y*) is within the 
      # boundaries of the notebook.
      def spans_xy?(x, y)
        win_x, win_y = toplevel.window.origin
        rel_x, rel_y = x - win_x, y - win_y

        nb_x, nb_y = allocation.x, allocation.y
        width, height = allocation.width, allocation.height

        rel_x >= nb_x and rel_y >= nb_y and 
          rel_x <= nb_x + width and rel_y <= nb_y + height
      end

      # Finds the document under/on the coordinates (*x*, *y*).
      def document_at_xy(x, y)
        p i=index_at_xy(x, y)
        document_at_index(i)
      end

      # Finds the index of the document label on the coordinate (*x*, *y*).
      # Returns _nil_ if there is no index and -1 if is out of range.
      # (-1 isn't just a "magic number": when migrating a document, for
      # instance, the tab array index -1 means, as in Ruby, the end of
      # the array, and has the effect of placing the tab at the end 
      # position.)
      # NB, this isn't true so we just return the index.
      #                 - Dan
      def index_at_xy(x, y)
        nb_x, nb_y = window.origin
        x_rel, y_rel = x - nb_x, y - nb_y

        nb_bx, nb_by = nb_x + allocation.width, nb_y + allocation.height
        return nil if x < nb_x or x > nb_bx or y < nb_y or y > nb_by

        index = nil
        first_visible = true

        children.each_with_index do |page, i|
          label = get_tab_label(page)
          next unless label.mapped?

          la_x, la_y  = label.allocation.x, label.allocation.y

          if first_visible
            first_visible = false
            x_rel = la_x if x_rel < la_x
            y_rel = la_y if y_rel < la_y
          end

          if self.tab_pos == Gtk::POS_TOP or
              self.tab_pos == Gtk::POS_BOTTOM
            break unless la_x <= x_rel
            if la_x + label.allocation.width <= x_rel
              index = i + 1
            else
              index = i
            end
          else
            break unless la_y <= y_rel
            if la_y + label.allocation.height <= y_rel
              index = i + 1
            else
              index = i
            end
          end
        end
#         return -1 if index == children.length
        return index
      end # def index_ax_xy

    private

      def signal_do_document_added(doc); end
      def signal_do_document_removed(doc, last); end
      def signal_do_document_close(doc); end
      def signal_do_document_drag(doc, x, y); end
      def signal_do_document_dropped(doc, x, y); end

      def button_press_cb(event)
        return true if @drag_info.in_progress
        
        index = index_at_xy(event.x_root, event.y_root)
        return false if index.nil?
        document = document_at_index(index)

        if event.button == 1 and 
            event.event_type == Gdk::Event::BUTTON_PRESS and
            index >= 0
          @drag_info.document = document
          @drag_info.x_start, @drag_info.y_start = event.x_root, event.y_root
          @drag_info.motion_handler = signal_connect('motion-notify-event') do
            |widget, event|
            motion_notify_cb(event)
          end
        end

        return false
      end

      def button_release_cb(event)
        if @drag_info.in_progress
          signal_emit('document_dropped',
                      @drag_info.document, event.x_root, event.y_root)
          if Gdk::pointer_is_grabbed?
            Gdk::pointer_ungrab(Gdk::Event::CURRENT_TIME)
            Gtk::grab_remove(self)
          end
        end
        
        drag_stop
        return false
      end

      def motion_notify_cb(event)
        unless @drag_info.in_progress
          return false unless Gtk::Drag::threshold?(self, @drag_info.x_start, 
                                                    @drag_info.y_start,
                                                    event.x_root, event.y_root)
          drag_start
        end
        signal_emit('document_drag',
                    @drag_info.document, event.x_root, event.y_root)
      end

      def drag_start
        @drag_info.in_progress = true
        Gtk::grab_add(self)
        unless Gdk::pointer_is_grabbed?
          Gdk::pointer_grab(self.window, false,
                            Gdk::Event::BUTTON1_MOTION_MASK |
                            Gdk::Event::BUTTON_RELEASE_MASK, nil,
                            Gdk::Cursor.new(Gdk::Cursor::FLEUR),
                            Gdk::Event::CURRENT_TIME)
        end
      end

      def drag_stop
        signal_handler_disconnect(@drag_info.motion_handler) unless 
          @drag_info.motion_handler.nil?
        @drag_info = DragInfo.new(false)
      end

    end # class Gtk::MDI::Notebook


    # A controller for managing MDI windows. Handles creation and destruction
    # of the windows with their notebooks.
    class Controller < GLib::Object
      type_register
      signal_new('window_added',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkWindow'])       # the window that was added
      signal_new('window_removed',
                 GLib::Signal::RUN_FIRST,
                 nil,
                 GLib::Type['void'],
                 GLib::Type['GtkWindow'],       # the window that was removed
                 GLib::Type['gboolean'])        # @windows.empty?

      # Creates a new controller. The controller will create instances of
      # *window_class* (Gtk::Window) and access the notebook using the 
      # attribute *notebook_attr* (symbol version of attribute name).
      # Optionally *args* are passed to window_class#new when a new window
      # is created.
      def initialize(window_class, notebook_attr, *args)
        super()
        @windows = Array.new
        @handlers = Hash.new
        @window_class = window_class
        @notebook_attr = notebook_attr
        @args = args
      end
      
      # Opens a new window, passing *args* to the new method of the defined
      # window class, and adds the window to the controller's list of 
      # managed windows.
      def open_window(*args)
        window = @window_class.new(*args)
        window.show_all
        add_window(window)
      end

      # Adds a *window* to the list and connects handlers for all 
      # 'document_*' signals.
      # Emits the 'window_added' signal.
      def add_window(window)
        @windows << window
        window.signal_connect('destroy') {remove_window(window)}
        n = nb(window)

        h = Array.new
        h << n.signal_connect('document_close') do |nb, doc|
          nb.remove_document(doc)
        end
        h << n.signal_connect('document_removed') do |nb, doc, last|
          # FIXME: we don't always want this:
      #    close_window(window) if last
        end
        h << n.signal_connect('document_drag') do |nb, doc, x, y|
          document_drag_cb(window, nb, doc, x, y)
        end
        h << n.signal_connect('document_dropped') do |nb, doc, x, y|
          document_dropped_cb(window, nb, doc, x, y)
        end
        @handlers[window] = h

        signal_emit('window_added', window)
        return window
      end

      # Closes a window *window* (only when it has been added earlier)
      # and removes it from the controller's list of managed windows.
      def close_window(window)
        return unless @windows.include? window
        window.destroy
        remove_window(window)
      end

      # Removes a window from the windows list and disconnects all 
      # signal handlers.
      # Emits the 'window_removed' signal.
      def remove_window(window)
        return unless @windows.include? window

        n = nb(window)
        @handlers[window].each do |handler|
          n.signal_handler_disconnect(handler)
        end
        @handlers.delete(window)

        @windows.delete(window)
        signal_emit('window_removed', window, @windows.empty?)
        return window
      end

      # Returns a list of windows known to the controller.
      def windows
        @windows.dup
      end

      # Returns a list of all known documents (i.e. all documents in all 
      # windows).
      def documents
        documents = Array.new
        @windows.each do |window|
          notebook = nb(window)
          documents += notebook.documents
        end
        return documents
      end

    private

      def signal_do_window_added(window); end
      def signal_do_window_removed(window, last); end

      def nb(window)
        window.method(@notebook_attr).call
      end

      def document_drag_cb(window, notebook, document, x, y)
        dest = notebook_at_pointer
        return if dest.nil?

        index = dest.index_at_xy(x, y)
        notebook.migrate_document(document, dest) if dest != notebook
        dest.shift_document(document, index)
      end

      def document_dropped_cb(window, notebook, document, x, y)
        dest = notebook_at_pointer
        if dest.nil? and not notebook.children.length == 1
          window = open_window(*@args)
          width, height = window.size
          window.move(x - width / 2, y - height / 2)
          dest = nb(window)
          notebook.migrate_document(document, dest)
          dest.instance_eval do
            drag_stop
            Gtk::grab_remove(self)
          end
        else
          # FIXME: Emit a signal saying the document has been moved
          # to an existing notebook.
        end
      end

      def window_and_xy_at_pointer
        window, x_rel, y_rel = Gdk::Window::at_pointer
        unless window.nil? or window.toplevel.nil? or 
            window.toplevel.user_data.nil?
          win = window.toplevel.user_data
          x, y = window.origin
          return win, x + x_rel, y + y_rel if @windows.include? win
        end
        return nil, 0, 0
      end

      def notebook_at_pointer
        window, x, y = window_and_xy_at_pointer
        return nil if window.nil?
        notebook = nb(window)
        return nil unless notebook.spans_xy?(x, y)
        return nb(window)
      end

    end # class Gtk::MDI::Controller

  end # end Gtk::MDI
end # end Gtk



#--- SAMPLE IMPLEMENTATION ---#

if __FILE__ == $0

# A sample MDI window.
class SampleMDIWindow < Gtk::Window
  @@count = 0

  def initialize
    super
    @@count += 1
    @notebook = Gtk::MDI::Notebook.new
    add(@notebook)
    set_title("#{self.class} #{@@count}")
    set_size_request(320, 240)
  end

  def populate
    widgets = %w(foo bar baz quux).each do |s|
      s << " #{@@count}"
      label = Gtk::Label.new(s)
      @notebook.add_document(Gtk::MDI::Document.new(label, s))
    end
    @notebook.show_all
  end

  attr_reader :notebook
end

# Initialize GTK
Gtk::init

# Initialize the MDI controller with our window class and the 
# symbol of the attribute used to access the notebook
controller = Gtk::MDI::Controller.new(SampleMDIWindow, :notebook)

# Quit once all windows have been closed
controller.signal_connect('window_removed') do |controller, window, last|
  Gtk::main_quit if last
end

# Open some windows and populate them
[Gtk::POS_TOP, Gtk::POS_BOTTOM, 
 Gtk::POS_LEFT, Gtk::POS_RIGHT].each do |pos|
  window = controller.open_window
  window.notebook.set_tab_pos(pos)
  window.populate
end

# Start it all up
Gtk::main

end
