
module Com::RedcarIDE
  class Scripting < Redcar::Plugin
    on_load do
      bus["/system/state/all_plugins_loaded"].subscribe do |event, slot|
        if bus["/system/state/all_plugins_loaded"].data.to_bool
          p RunStartupScript.new
          RunStartupScript.new.execute
        end
      end
    end
    
    class RunStartupScript < Redcar::Command
      menu "Tools/Run Startup Script"
      icon :PREFERENCES
      
      def execute
        if Redcar::Preference.get(Com::RedcarIDE::Scripting, "Run startup script").to_bool
          require Com::RedcarIDE::Scripting.startup_script_file
        end
      end
    end
    
    preference "Run startup script" do
      type    :toggle 
      default true
    end
      
    def self.startup_script_file
      if File.exists?(file = File.expand_path("~/.Redcar/startup.rb"))
        file
      else
        File.dirname(__FILE__) + "/startup.rb"
      end
    end
  end
end
