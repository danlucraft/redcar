module Redcar
  class Runnables
    class RunnableTypeGroup < RunnableGroup
      def initialize(name)
        name_parts = name.split("/")
        @text = name_parts.first
        @runnables = []
        @subgroups = {}
      end

      # Return the type group that corresponds to the passed name-path, or self, if name is empty
      # If a child with the specified path does not exist, create it and clear the children cache
      def type_group(name)
        return super unless name.empty?
        self
      end

      # Add a runnable to the children
      # Tries to avoid re-building the children array
      def add_runnable(runnable)
        @children << runnable unless @children.nil?
        return @runnables << runnable
      end

      def icon
        File.join(Redcar.icons_directory, "folder-open-small-gears.png")
      end
    end
  end
end