# redcar/lib/dialog
# Includes the Dialog and Speedbar wrappers for easy dialog creation.
# D.B. Lucraft

module Redcar
  class Dialog
    class DialogWrapper
      attr_reader :dialog
      def initialize(options)
        options = process_params(options, 
                                 { :buttons => [:ok],
                                   :title => "Dialog",
                                   :message => nil,
                                   :entry => [] })
        response_id = 1
        # response id -> name
        @id_to_button = {}
        gtkbuttons = options[:buttons].collect do |buttoninfo|
          what = Dialog.button_convert(buttoninfo)
          response_id += 1
          @id_to_button[response_id] = buttoninfo
          [what, response_id]
        end
        @dialog = Gtk::Dialog.new(options[:title],
                                  win,
                                  Gtk::Dialog::DESTROY_WITH_PARENT,
                                  *gtkbuttons)
        if options[:message]
          widget = Gtk::Label.new(options[:message])
          dialog.vbox.add(widget)
        end
        @entries = {}
        options[:entry].each do |entry|
          add_entry_widget(entry)
        end
        
        # Each button has its own block, that is called when the
        # appropriate response is intercepted.
        @button_blocks = {}
        @dialog.signal_connect('response') do |d, id|
          if id == Gtk::Dialog::RESPONSE_DELETE_EVENT
            @destroy_block.call if @destroy_block
            @dialog.destroy
          else
            @button_blocks[@id_to_button[id]].call
          end
        end
        
        # By default, clicking ok closes the dialog.
        if options[:buttons].include? :ok
          self.on_button :ok do 
            self.close
          end
        end
      end
      
      def on_destroy(&block)
        @destroy_block = block
      end
      
      def on_button(name, &block)
        @button_blocks[name] = block
      end
      
      def press_button(name)
        @button_blocks[name].call
      end
      
      def show(args={})
        args = process_params(args, 
                              { :modal => false,
                                :block => false })
        if args[:modal]
          @dialog.modal = true
        end
        if args[:block]
          @dialog.run
        else
          @dialog.show_all
        end
        yield if block_given?
      end
      
      def close
        @dialog.destroy
      end
      
      def add_entry_widget(entry)
        ewidget, model = Dialog.type_to_widget(entry)
        if entry[:legend]
          widget = Gtk::HBox.new
          widget.pack_start(Gtk::Label.new(entry[:legend]))
          widget.pack_start(ewidget)
        else
          widget = ewidget
        end
        case entry[:type]
        when :text, :label
          self.class.send(:define_method, entry[:name]) do
            ewidget.text
          end
          self.class.send(:define_method, (entry[:name].to_s+"=").intern) do |val|
            ewidget.text = val.to_s
          end
        when :list
          self.class.send(:define_method, (entry[:name].to_s).intern) do
            entry[:abs]
          end
        else
          p :unknown_widget_type
          abort
        end
        @dialog.vbox.add(widget)
      end
      
    end
    
    def self.button_convert(buttoninfo)
      case buttoninfo.to_s.downcase
      when "find"
        Gtk::Stock::FIND
      when "replace"
        Gtk::Stock::FIND_AND_REPLACE
      when "ok"
        Gtk::Stock::OK
      when "save"
        Gtk::Stock::SAVE
      else
        buttoninfo
      end
    end
    
    
    def self.type_to_widget(entry)
      case entry[:type]
      when :text
        e = Redcar::TextEntry.new
        e.widget.modify_font(Pango::FontDescription.new("Monospace 10"))
        [e.widget, nil]
      when :label
        [Gtk::Label.new, nil]
      when :list
        sw = Gtk::ScrolledWindow.new(nil, nil)
        sw.shadow_type = Gtk::SHADOW_ETCHED_IN
        sw.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC)
        
        sw.add(entry[:abs].treeview)
        sw
      else
        p :unknown_widget_type
        abort
      end
    end
    
    def self.build(options)
      DialogWrapper.new(options)
    end
    
    def self.open_folder
      dialog = Gtk::FileChooserDialog.new("Open Folder",
                                          win,
                                          Gtk::FileChooser::ACTION_SELECT_FOLDER,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        puts "dirname = #{dialog.filename}"
        dirname = dialog.filename
      else
        dirname = nil
      end
      dialog.destroy
      dirname
    end
    
    def self.open
      dialog = Gtk::FileChooserDialog.new("Open",
                                          win,
                                          Gtk::FileChooser::ACTION_OPEN,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
      if $last_opened_dir
        dialog.current_folder = $last_opened_dir
      end
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        puts "filename = #{dialog.filename}"
      end
      filename = dialog.filename
      $last_opened_dir = "/" + filename.split("/")[0..-2].join("/")
      dialog.destroy
      filename
    end
    
    def self.save
      dialog = Gtk::FileChooserDialog.new("Save",
                                          win,
                                          Gtk::FileChooser::ACTION_SAVE,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        puts "filename = #{dialog.filename}"
      end
      filename = dialog.filename
      dialog.destroy
      filename
    end
  end
end

