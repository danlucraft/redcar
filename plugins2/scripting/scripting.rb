
module Com::RedcarIDE
  class Scripting < Redcar::Plugin
    on_load do
      bus["/system/state/all_plugins_loaded"].subscribe do |event, slot|
        if bus["/system/state/all_plugins_loaded"].data.to_bool
          run_startup_script
        end
      end
    end
    
    user_commands do
      def self.run_startup_script
        if Redcar::Preference.get(self, "Run startup script").to_bool
          require startup_script_file
        end
      end
    end
    
    main_menu "Tools" do
      item "Run Startup Script", :run_startup_script, :icon => :PREFERENCES
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
