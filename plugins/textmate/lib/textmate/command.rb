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
        name.gsub(/[ ()]/, "_")
      end

      def uuid
        @plist["uuid"]
      end

      def output?
        !(@plist["output"] && @plist["output"] == "discard")
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
          f << command
        end
        File.chmod(511, command_script) # For some reason, 511 gives rwxrwxrwx
      end

      def run
        if @project = Project.window_projects[Redcar.app.focussed_window]
          write_command_script
          out = ("tab" if output?) || "none"
          environment = { "TM_PROJECT_DIRECTORY" => project.home_dir,
              "PRJNAME" => File.basename(project.home_dir),
              "TM_BUNDLE_SUPPORT" => File.join(@bundle.path, "Support").gsub(" ", '\ ') }
          Runnables.run_process(project.home_dir, command_script, name, out, environment)
        end
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