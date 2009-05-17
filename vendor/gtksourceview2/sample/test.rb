#!/usr/bin/env ruby
=begin
  test.rb - Ruby/GtkSourceView2 sample script.

  Copyright (c) 2006 Ruby-GNOME2 Project Team
  This program is licenced under the same licence as Ruby-GNOME2.

  $Id: test.rb,v 1.4 2007/06/03 02:11:07 mutoh Exp $
=end

require 'gtksourceview2'

w = Gtk::Window.new
w.signal_connect("delete-event"){Gtk::main_quit}

view = Gtk::SourceView.new
w.add(Gtk::ScrolledWindow.new.add(view))
view.show_line_numbers = true

lang = Gtk::SourceLanguageManager.new.get_language('ruby')
view.buffer.language = lang

w.set_default_size(400,300)
w.show_all

Gtk.main
