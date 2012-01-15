class Sessions
  class Loader
    def self.loaders
      @loaders ||= {}
    end
    
    def self.project_loaded(project)
      loaders[project.path] = loader = self.new(project)
      loader.restore if restore_files?
    end
    
    def self.project_closed(project, window)
      loader = loaders.delete(project.path)
      loader.save if save_files?
    end
    
    def self.storage
      @storage ||= begin
        storage = Redcar::Plugin::Storage.new('project_loader')
        storage.set_default('restore_open_files_on_load', true)
        storage.set_default('save_open_files_on_close',   true)
        storage
      end
    end
    
    def self.restore_files?
      storage['restore_open_files_on_load']
    end
    
    def self.restore_files=(toggle)
      storage['restore_open_files_on_load'] = toggle
    end
    
    def self.restore_project_files(project)
      loaders[project.path].restore
    end
    
    def self.save_files?
      storage['save_open_files_on_close']
    end
    
    def self.save_files=(toggle)
      storage['save_open_files_on_close'] = toggle
    end
    
    def self.save_project_files(project)
      loaders[project.path].save
    end
    
    attr_accessor :project
    
    def initialize(project)
      @project = project
    end
    
    def storage
      @storage ||= begin
        storage = project.storage('project_loader')
        storage.set_default('open_files', [])
        storage
      end
    end
    
    def open_files
      Redcar.app.all_tabs.select do |tab|
        tab.is_a?(Redcar::EditTab) &&
        tab.document && tab.document.path &&
        tab.document.path.start_with?(project.path)
      end.collect do |tab|
        path = tab.document.path
        path = path[project.path.length + 1 .. path.length]
      end
    end
    
    def saved_files
      storage['open_files'] ||= []
    end
    
    def saved_files=(files)
      storage['open_files'] = files
    end
    
    def restore
      Redcar.log.info("Sessions::Loader: opening files last open for #{project.path}")
      unless (files = saved_files).empty?
        paths = files.each do |file|
          path = Pathname.new(file).expand_path(project.path)
          Redcar::Project::Manager.open_file(path.to_s) if path.exist?
        end
        Redcar::Project::Manager.find_open_file_tab(paths.first).andand.focus
      end
    end
    
    def save
      Redcar.log.info("Sessions::Loader: saving files last open for #{project.path}")
      self.saved_files = open_files
    end
  end
end
