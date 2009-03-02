
module Redcar::Testing
  class InternalCucumberRunner
    def self.run_all_features
      puts "run_all_features"
    end
    
    def self.run_feature_for_plugin(plugin_name)
      puts "run_feature_for_plugin(#{plugin_name.inspect})"
      load_plugin_features(plugin_name)
    end
    
    private
    
    def self.load_plugin_features(plugin_name)
      puts "loading features for #{plugin_name}"
      files = feature_files(plugin_name)
      if files.empty?
        puts "   no features"
        return
      end
      p files
    end
    
    def self.feature_files(plugin_name)
      feature_dir = Redcar.PLUGINS_PATH + "/#{plugin_name}/features"
      if File.exists?(feature_dir)
        Dir["#{feature_dir}/**/*.feature"]
      else
        []
      end
    end
  end
end
