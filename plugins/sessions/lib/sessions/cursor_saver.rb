class Sessions
  class CursorSaver

    def self.project_closed(project, window)
      open_tabs(project, window).each do |tab|
        tab.remove_listener(tab_close_handlers.delete(tab))
        save_cursor(tab.document, project)
      end
    end
    
    def self.tab_added(tab)
      if document = tab.document
        document_new_mirror_handlers[tab] = document.add_listener(:new_mirror) do
          document.remove_listener(document_new_mirror_handlers.delete(document))
          
          if tab.document && tab.document.path
            tab_focus_handlers[tab] = tab.add_listener(:focus) do
              tab.remove_listener(tab_focus_handlers.delete(tab))
              CursorSaver.restore_cursor(document)
            end
            
            tab_close_handlers[tab] = tab.add_listener(:before => :close) do
              tab.remove_listener(tab_close_handlers.delete(tab))
              CursorSaver.save_cursor(document) if document.path
            end
          end
        end
      end
    end
    
    def self.save_cursor(document, project = nil)
      data = {
        :path          => document.path,
        :cursor_offset => document.cursor_offset,
        :timestamp     => document.mirror.timestamp
      }
      if document.selection?
        data[:selection_offset]     = document.selection_offset
        data[:block_selection_mode] = document.block_selection_mode?
      end
      restored_paths.delete(document.path) # FIXME(chrislwade): see note on <restored_paths>
      Redcar.log.debug("Sessions::CursorSaver: saving cursor data: #{data.inspect}")
      save_file_data(data, project)
    end
    
    def self.restore_cursor(document)
      return if restored_paths[document.path] # FIXME(chrislwade): see note on <restored_paths>
      data = get_file_data(document.path)
      return if data.nil?
      restored_paths[document.path] = true # FIXME(chrislwade): see note on <restored_paths>
      Redcar.log.debug("Sessions::CursorSaver: restoring cursor data: #{data.inspect}")
      if data[:cursor_offset] > document.length
        Redcar.log.debug("Sessions::CursorSaver: offset #{data[:cursor_offset]} doesn't exist, truncated file? [max offset = #{document.length}]")
      elsif user_storage['check_timestamps'] && data[:timestamp] != document.mirror.timestamp
        Redcar.log.debug("Sessions::CursorSaver: timestamp #{data[:timestamp]} doesn't match! [new timestamp = #{document.mirror.timestamp}]")
      else
        if user_storage['restore_selection'] && data.has_key?(:selection_offset) && data[:selection_offset] <= document.length
          document.set_selection_range(data[:cursor_offset], data[:selection_offset])
          document.block_selection_mode = data[:block_selection_mode]
        else
          document.cursor_offset = data[:cursor_offset]
        end
        document.ensure_cursor_visible
      end
    end
    
    private
    
    # FIXME(chrislwade): find a better way to prevent "double restore"
    # Helps prevent double-restore once Redcar is running.  When files are opened via the
    # project tree, the tab receives the :focus event twice.  When they are opened programmatically,
    # the tab only receives a single :focus event.  Unfortunately, removing the :focus handler during
    # handler itself doesn't prevent a second run!
    def self.restored_paths
      @restored_paths ||= {}
    end
    
    def self.document_new_mirror_handlers
      @document_new_mirror_handlers ||= {}
    end
    
    def self.tab_close_handlers
      @tab_close_handlers ||= {}
    end
    
    def self.tab_focus_handlers
      @tab_focus_handlers ||= {}
    end
    
    def self.user_storage
      @storage ||= begin
        storage = Redcar::Plugin::Storage.new('cursor_saver')
        storage.set_default('cursor_positions', [])
        storage.set_default('files_to_retain', 200)
        storage.set_default('check_timestamps', true)
        storage.set_default('restore_selection', true)
        storage
      end
    end
    
    def self.project_storage(project)
      storage = project.storage('cursor_saver')
      storage.set_default('cursor_positions', [])
      storage.set_default('files_to_retain', 0)
      storage
    end
    
    def self.project_for_path(path)
      Redcar.log.debug("Sessions::CursorSaver: searching for open project for #{path}")
      project = Redcar::Project::Manager.find_projects_containing_path(path).last
      Redcar.log.debug("Sessions::CursorSaver: found: #{project.inspect}")
      project
    end
    
    def self.open_tabs(project, window)
      window.all_tabs.select do |tab|
        tab.is_a?(Redcar::EditTab) &&
        tab.document.path &&
        tab.document.path.start_with?(project.path)
      end
    end
    
    def self.trim(storage)
      if storage['files_to_retain'] && storage['files_to_retain'] > 0
        while storage['cursor_positions'].length > storage['files_to_retain']
          storage['cursor_positions'].shift
        end
      end
    end
    
    def self.save_file_data(data, project = nil)
      if project ||= project_for_path(data[:path])
        storage = project_storage(project)
        data[:path] = data[:path][(project.path.length + 1) .. data[:path].length]
        Redcar.log.debug("Sessions::CursorSaver: using project storage to store offset for #{data[:path]}")
      else
        storage = user_storage
        pathname = Pathname.new(data[:path])
        data[:path] = pathname.absolute? ? pathname.to_s : pathname.expand_path.to_s
        Redcar.log.debug("Sessions::CursorSaver: using user storage to store offset for #{data[:path]}")
      end
      storage['cursor_positions'].delete_if {|obj| obj[:path] == data[:path]}
      storage['cursor_positions'] << data
      trim(storage)
      storage.save
    end
    
    def self.get_file_data(path)
      if project = project_for_path(path)
        storage = project_storage(project)
        scoped_path = path[(project.path.length + 1) .. path.length]
        Redcar.log.debug("Sessions::CursorSaver: restoring offset from project storage for #{scoped_path}")
      else
        storage = user_storage
        pathname = Pathname.new(path)
        scoped_path = pathname.absolute? ? pathname.to_s : pathname.expand_path.to_s
        Redcar.log.debug("Sessions::CursorSaver: restoring offset from user storage for #{scoped_path}")
      end
      storage['cursor_positions'].find {|obj| obj[:path] == scoped_path}
    end
  end
end
