
module Redcar
  class Comment
    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Toggle Line Comment", ToggleLineCommentCommand
        end
      end
    end

    def self.comment_map
      @map ||=begin
        c = File.read(Comment.comment_lib_path)
        map = JSON.parse(c)
        Comment.comment_extension_paths.each do |path|
          json = File.read(path)
          JSON.parse(json).each do |item,content|
            map[item] = content
          end
        end
        map
      end
    end

    def self.extensions_file;"comment_extensions.json";end

    def self.comment_lib_path
      File.dirname(__FILE__) + "/../vendor/comment_lib.json"
    end

    def self.comment_extension_paths
      p = Redcar::Project::Manager.focussed_project
      if p
        p.config_files(Comment.extensions_file)
      else
        Dir[File.join(Redcar.user_dir,Comment.extensions_file)]
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+/", ToggleLineCommentCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+/", ToggleLineCommentCommand
      end
      [osx, linwin]
    end

    def self.grammar_missing
      Application::Dialog.message_box("Comment type not found for your grammar. Using defaults.")
    end

    class ToggleSelectionCommentCommand < Redcar::EditTabCommand
      def execute
        adoc = Redcar::app.focussed_notebook_tab.document
        grammar = Redcar::app.focussed_notebook_tab.edit_view.grammar
        type = Comment.comment_map["#{grammar.gsub("\"","")}"]
        if type
          start  = type["start_selection"]
          ending = type["end_selection"  ]
        else
          Comment.grammar_missing
          start  = "/*"
          ending = "*/"
        end
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.compound do
            if doc.selection?
              text = doc.selected_text
              if text[0,start.length] == start and text[text.length-ending.length,text.length] == ending
                text = text[start.length,text.length]
                text = text[0,text.length-ending.length]
                doc.replace_selection(text)
              else
                doc.replace_selection("#{start}#{text}#{ending}")
              end
            else
              line = doc.cursor_line
              text = doc.get_line_without_end_of_line(line)
              if text[0,start.length] == start and text[text.length-ending.length,text.length] == ending
                doc.replace_line(line,text[start.length,text.length-ending.length])
              else
                doc.replace_line(line,"#{start}#{text}#{ending}\n")
              end
            end
          end
        end
      end
    end

    class ToggleLineCommentCommand < Redcar::EditTabCommand
	    def execute
        adoc = Redcar::app.focussed_notebook_tab.document
        grammar = Redcar::app.focussed_notebook_tab.edit_view.grammar
        type = Comment.comment_map["#{grammar.gsub("\"","")}"]
        if type
          comment = type["line_comment"]
        else
          Comment.grammar_missing
          comment = "//"
        end
        end_pos = comment.length() -1
        range = adoc.selection_range
        start_line = adoc.line_at_offset(range.first)
        end_line = adoc.line_at_offset(range.last)
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.compound do
            (start_line..end_line).each do |line|
              text = adoc.get_line(line).chomp
              if text[0..end_pos] == comment then text = text[end_pos+1..-1] else text = comment + text end
              adoc.replace_line(line, text) #TODO: and fix this too!
            end
          end
        end
      end
    end
  end
end