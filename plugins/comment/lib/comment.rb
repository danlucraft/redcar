
module Redcar
  class Comment
    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          sub_menu "Formatting" do
            item "Toggle Line Comment"     , ToggleLineCommentCommand
            item "Toggle Selection Comment", ToggleSelectionCommentCommand
          end
        end
      end
    end

    def self.storage
      @storage ||=begin
        storage = Plugin::Storage.new('comment_plugin')
        storage.set_default('default_line_comment'       , "#")
        storage.set_default('default_start_block'        , "/*")
        storage.set_default('default_end_block'          , "*/")
        storage.set_default('warning_for_using_defaults' , true)
        storage
      end
    end

    def self.comment_map
      @map ||=begin
        c = File.read(Comment.comment_lib_path)
        map = JSON.parse(c)
        begin
          path = Comment.comment_extension_path
          if File.exist?(path)
            json = File.read(path)
            JSON.parse(json).each do |item,content|
              map[item] = content
            end
          end
        rescue Object => e
          Redcar::Application::Dialog.message_box("There was an error parsing Comment extensions file: #{e.message}")
          map = JSON.parse(c)
        end
        map
      end
    end
    
    def self.extensions_file;"comment_extensions.json";end
    
    def self.comment_lib_path
      File.join(File.dirname(__FILE__),"..","vendor","comment_lib.json")
    end
    
    def self.comment_extension_path
      File.join(Redcar.user_dir,Comment.extensions_file)
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+/", ToggleLineCommentCommand
        link "Cmd+.", ToggleSelectionCommentCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+/", ToggleLineCommentCommand
        link "Ctrl+.", ToggleSelectionCommentCommand
      end
      [osx, linwin]
    end

    def self.grammar_missing(grammar)
      if Comment.storage['warning_for_using_defaults']
        Application::Dialog.message_box("Comment type not found for #{grammar}. Using defaults instead.") unless @messaged
        @messaged = true
      end
    end

    class ToggleSelectionCommentCommand < Redcar::EditTabCommand
      def execute
        type = Comment.comment_map["#{tab.edit_view.grammar.gsub("\"","")}"]
        if type
          start  = type["start_block"]
          ending = type["end_block"  ]
          return unless start and ending
        else
          Comment.grammar_missing(tab.edit_view.grammar)
          start  = Comment.storage['default_start_block']
          ending = Comment.storage['default_end_block']
        end
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.compound do
            if doc.selection?
              text = doc.selected_text
              if text[0,start.split(//).length] == start and
                text[text.split(//).length-ending.split(//).length,text.split(//).length] == ending
                text = text[start.split(//).length,text.split(//).length]
                text = text[0,text.split(//).length-ending.split(//).length]
                doc.replace_selection(text)
              else
                doc.replace_selection("#{start}#{text}#{ending}")
              end
            else
              line                = doc.cursor_line
              text                = doc.get_line_without_end_of_line(line)
              start_idx           = text.index(start)
              end_idx             = text.rindex(ending)
              start_length        = start.split(//).length
              ending_start_offset = text.split(//).length-ending.split(//).length
              if text[0,start_length] == start and text[ending_start_offset,text.split(//).length] == ending
                text = text[start.length,text.split(//).length]
                text = text[0,ending_start_offset]
                doc.replace_line(line,text)
              else
                replacement  = "#{start}#{text}#{ending}"
                replacement << "\n" if doc.get_line(line) =~ /\n$/
                doc.replace_line(line,replacement)
              end
            end
          end
        end
      end
    end

    class ToggleLineCommentCommand < Redcar::EditTabCommand
      
      attr_reader :comment
      
      def line_start_regex
        /^(\s*)#{comment}\s?/
      end
      
      def starts_with_comment?(line)
        line =~ line_start_regex
      end
      
      def strip_comment(line, offset=nil)
        new_line = line.clone
        if offset and offset != 0 and 
            new_line[0..offset] !~ /^\s*$/
          new_line[offset..(offset + comment.length)] = ""
          @point_comment_removed = offset
          new_line
        else
          md = line.match(line_start_regex)
          @point_comment_removed = md[1].length
          md[1] + md.post_match
        end
      end
      
      def add_comment(line, offset)
        if line.length < offset
          line + " "*(offset - line.length) + comment + " "
        else
          line.clone.insert(offset, comment + " ")
        end
      end

      def comment_insertion_point_for(line)
        md = line.match(/^(\s*)([^\s])/)
        md[1].length
      end
      
      def execute
        type = Comment.comment_map["#{tab.edit_view.grammar.gsub("\"","")}"]
        if type
          @comment = type["line_comment"]
          return unless comment
        else
          Comment.grammar_missing(tab.edit_view.grammar)
          @comment = Comment.storage['default_line_comment']
        end
        selected              = doc.selection?
        cursor_offset         = doc.cursor_offset
        selection_offset      = doc.selection_offset
        cursor_line           = doc.cursor_line
        selection_line        = doc.selection_line
        cursor_line_offset    = doc.cursor_line_offset
        selection_line_offset = doc.selection_line_offset
        if cursor_offset < selection_offset
          start_point_offset      = cursor_offset
          end_point_offset        = selection_offset
          start_point_line        = cursor_line
          start_point_line_offset = cursor_line_offset
        else
          start_point_offset      = selection_offset
          end_point_offset        = cursor_offset
          start_point_line        = selection_line
          start_point_line_offset = selection_line_offset
        end
        start_line            = doc.line_at_offset(start_point_offset)
        end_line              = doc.line_at_offset(end_point_offset)
        
        if doc.offset_at_line(end_line) == end_point_offset and start_line != end_line
          end_line -= 1
        end
        
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.compound do
            all_lines_are_already_commented = true
            start_line_comment_offset       = nil
            insertion_column                = 1000
            
            (start_line..end_line).each do |line|
              text = doc.get_line(line)
              
              if text =~ /^\s*$/
              else
                insertion_column = [insertion_column, comment_insertion_point_for(text)].min
              end
              
              if line == start_point_line and selected
                text = text[start_point_line_offset..-1]
              end
              
              unless starts_with_comment?(text)
                all_lines_are_already_commented = false
              end
            end
            
            if all_lines_are_already_commented
              (start_line..end_line).each do |line|
                doc.replace_line(line) do |text|
                  new_text = 
                    if line == start_point_line and selected
                      strip_comment(text, start_point_line_offset)
                    else
                      strip_comment(text)
                    end
                  diff = text.length - new_text.length
                  if cursor_offset < selection_offset
                    selection_offset -= diff
                  else
                    if cursor_line > line or (cursor_line == line and cursor_line_offset > @point_comment_removed)
                      cursor_offset -= diff
                    end
                  end
                  new_text
                end
              end
            else
              (start_line..end_line).each do |line|
                doc.replace_line(line) do |text|
                  new_text = if line == start_point_line and selected
                               add_comment(text, [start_point_line_offset, insertion_column].max)
                             else
                               add_comment(text, insertion_column)
                             end
                  diff = new_text.length - text.length
                  if cursor_offset < selection_offset
                    selection_offset += diff
                  else
                    if cursor_line > line or (cursor_line == line and cursor_line_offset > insertion_column)
                      cursor_offset += diff
                    end
                  end
                  new_text
                end
              end
            end
          end
        end

        if selected
          doc.set_selection_range(cursor_offset, selection_offset)
        else
          doc.set_selection_range(cursor_offset, cursor_offset)
        end
      end
    end
  end
end