#!/usr/bin/env ruby
=begin
  sourcelanguagesmanager.rb - Ruby/GtkSourceView sample script.

  Copyright (c) 2006 Ruby-GNOME2 Project Team
  This program is licenced under the same licence as Ruby-GNOME2.

  $Id: sourcelanguagesmanager.rb,v 1.3 2007/06/03 02:11:07 mutoh Exp $
=end

require 'gtksourceview2'

s = Gtk::SourceLanguageManager.new
puts s.language_ids
s.language_ids.each do |v|
  puts v
end
s.get_search_path.each do |v|
  puts v
end
puts s.get_language("html").name

