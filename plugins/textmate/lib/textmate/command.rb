module Redcar
  module Textmate
    ##
    # This class is responsible for running textmate bundle commands from their XML specification
    # TODO: Complete environment variables (see: http://manual.macromates.com/en/environment_variables.html)
    # TODO: Implement before commands
    # TODO: Implement scope
    # TODO: Honour output options (discard, showAsHTML, openAsNewDocument)
    # TODO: Implement variable input
    class Command
      attr_reader :key_equivalent, :project

      def initialize(path, bundle)
        @path = path
        @plist = Plist.xml_to_plist(File.read(path))
        @bundle = bundle
        if key = @plist["keyEquivalent"]
          @key_equivalent = Textmate.translate_key_equivalent(key)
        end
      end

      def bundle_name
        @bundle.name
      end

      def name
        @plist["name"]
      end

      def file_name
        name.gsub(/[ ()&]/, "_")
      end

      def uuid
        @plist["uuid"]
      end

      def output?
        # FIXME: Do we want to see all output, always?
        # !(@plist["output"] && @plist["output"] == "discard")
        true
      end

      # Command to run previously to the actual command
      def before
        unless (@plist["beforeRunningCommand"].nil? || @plist["beforeRunningCommand"] == "nop")
          @plist["beforeRunningCommand"]
        end
      end

      def command
        @plist["command"]
      end

      def command_dir
        File.join(project.home_dir, ".redcar", "Commands")
      end

      def command_script
        File.join(command_dir, file_name)
      end

      def write_command_script
        Dir.mkdir(command_dir) unless File.exist? command_dir
        File.open(command_script, "w") do |f|
          f << aliases << "\n"
          f << environment << "\n"
          f << command << "\n"
        end
        File.chmod(511, command_script) # For some reason, 511 gives rwxrwxrwx
      end

      def run
        if @project = Project.window_projects[Redcar.app.focussed_window]
          write_command_script
          out = ("tab" if output?) || "none"
          Runnables.run_process(project.home_dir, command_script, name, out)
        end
      end

      def environment
        tab = Redcar.app.focussed_notebook_tab
        edit_tab = tab if tab and tab.edit_tab?

        document = tab.edit_view.document if edit_tab
        filepath = document.path if document

        selected_files = project.tree.selection.map(&:path) if project and project.tree

        environment = {
          "TM_BUNDLE_SUPPORT" => File.join(@bundle.path, "Support").gsub(" ", '\ '),
          "TM_CURRENT_LINE" => (document.get_line(document.cursor_line)[0...-1] if document),
          "TM_CURRENT_WORD" => (document.current_word if document),
          "TM_DIRECTORY" => (File.dirname(filepath) if filepath),
          "TM_FILEPATH" => filepath,
          "TM_LINE_INDEX" => (document.cursor_line_offset if document),
          "TM_LINE_NUMBER" => (document.cursor_line + 1 if document),
          "TM_PROJECT_DIRECTORY" => project.home_dir,
          "TM_SCOPE" => (document.cursor_scope if document),
          "TM_SELECTED_FILES" => selected_files,
          "TM_SELECTED_FILE" => (selected_files.first if selected_files),
          "TM_SOFT_TABS" => (tab.edit_view.soft_tabs? if edit_tab),
          "TM_TAB_SIZE" => (tab.edit_view.tab_width if edit_tab),
          "TM_SUPPORT_PATH" => File.expand_path("../../../Support/#{Redcar.platform.to_s}/", __FILE__),
          "TM_ORGANIZATION_NAME" => "redcareditor",
          "PRJNAME" => File.basename(project.home_dir),
        }

        path = %{export PATH=$PATH:"#{environment['TM_BUNDLE_SUPPORT']}/bin":"#{environment['TM_SUPPORT_PATH']}/bin"\n}
        path + environment.map {|k, v| %{export #{k}="#{v}"} }.join("\n")
      end

      def aliases
        aliases = {"mate" => "redcar"}
        aliases.map {|k,v| "alias #{k}=#{v}"}.join("\n")
      end

      def input
        case @plist["input"]
        when "selection"
          EditView.focussed_edit_view_document && EditView.focussed_edit_view_document.selected_text
        else # nil, "none"
          ""
        end
      end

      def to_menu_string
        r = name.clone
        r << " (#{key_equivalent})" if key_equivalent
        r
      end
    end
  end
end