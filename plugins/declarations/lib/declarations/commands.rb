module Redcar
  class Declarations
    
    class RebuildTagsCommand < Command
      def execute
        project = Project::Manager.focussed_project
        tags_path = Declarations.file_path(project)
        FileUtils.rm tags_path if ::File.exists? tags_path
        ProjectRefresh.new(project).execute
      end
    end
    
    class GoToTagCommand < EditTabCommand
      sensitize :open_project

      def execute
        if Project::Manager.focussed_project.remote?
          Application::Dialog.message_box("Go to declaration doesn't work in remote projects yet :(")
          return
        end

        if doc.selection?
          handle_tag(doc.selected_text)
        else
          range = doc.current_word_range
          handle_tag(doc.get_slice(range.first, range.last))
        end
      end

      def handle_tag(token = '')
        tags_path = Declarations.file_path(Project::Manager.focussed_project)
        unless ::File.exist?(tags_path)
          Application::Dialog.message_box("The declarations file 'tags' has not been generated yet.")
          return
        end
        matches = find_tag(tags_path, token).uniq
        
        # save current cursor position before jump to another location.
        Redcar.app.navigation_history.save(doc) if matches.size > 0
        
        case matches.size
        when 0
          Application::Dialog.message_box("There is no declaration for '#{token}' in the 'tags' file.")
        when 1
          Redcar::Declarations.go_to_definition(matches.first)
        else
          open_select_tag_dialog(matches)
        end
        
        Redcar.app.navigation_history.save(doc) if matches.size > 0
      end

      def find_tag(tags_path, tag)
        Declarations.tags_for_path(tags_path)[tag] || []
      end

      def open_select_tag_dialog(matches)
        Declarations::SelectTagDialog.new(matches).open
      end

      def log(message)
        puts("==> Ctags: #{message}")
      end
    end
    
    class OpenOutlineViewCommand < Redcar::EditTabCommand
      
      def execute
        cur_doc = Redcar.app.focussed_window.focussed_notebook_tab.document
        if cur_doc
          Declarations::OutlineViewDialog.new(cur_doc).open
        end
      end
    end

    class OpenProjectOutlineViewCommand < Redcar::ProjectCommand
      def execute
        Declarations::ProjectOutlineViewDialog.new(project).open if project
      end
    end
    
    class OutlineViewDialog < FilterListDialog
      include Redcar::Model
      include Redcar::Observable
      
      attr_accessor :document
      attr_accessor :last_list
      
      def initialize(document)
        @document = document
        file = Declarations::File.new(@document.path)
        file.add_tags_for_paths(@document.path)
        @tags = file.tags
        @all = []
        @tags.each do |name, path, match|
          kind = Declarations.match_kind(path, match)
          @all << {:name => name, :icon => Declarations.icon_for_kind(kind), :path => path, :match => match}
        end
        super()
      end
      
      def update_list(filter)
        filter_and_rank_by(@all, filter) {|h| h[:name]}
      end

      def selected(item, ix)
        close
        Redcar.app.navigation_history.save(@document) if @document
        DocumentSearch::FindNextRegex.new(Regexp.new(Regexp.quote(item[:match])), true).run_in_focussed_tab_edit_view
        Redcar.app.navigation_history.save(@document) if @document
      end
    end

    class ProjectOutlineViewDialog < FilterListDialog
      def initialize(project)
        @project = project
        file = Declarations::File.new(Declarations.file_path(@project))
        @all = []
        file.tags.each do |name, path, match|
          @all << {:name => name + " (" + ::File.basename(path) + ")", :base_name => name, :path => path, :match => match}
        end
        super()
      end
      
      def update_list(filter)
        results = filter_and_rank_by(@all, filter) { |h| h[:base_name] }
        results.each do |result|
          kind = Declarations.match_kind(result[:path], result[:match])
          result[:icon] = Declarations.icon_for_kind(kind)
        end
        results
      end
      
      def selected(item, ix)
        if path = item[:path] and ::File.exists?(path)
          close
          if tab = Redcar::Project::Manager.open_file(path)
            doc = Redcar::EditView.focussed_tab_edit_view.document
            Redcar.app.navigation_history.save(doc)
            DocumentSearch::FindNextRegex.new(Regexp.new(Regexp.quote(item[:match])), true).run_in_focussed_tab_edit_view
            Redcar.app.navigation_history.save(doc)
          end
        end
      end
    end
  end
end
