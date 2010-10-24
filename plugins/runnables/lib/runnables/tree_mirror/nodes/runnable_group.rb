module Redcar
  class Runnables
    class RunnableGroup
      include Redcar::Tree::Mirror::NodeMirror
      attr_reader :text

      def initialize(name, path, runnables)
        @text      = name
        @runnables = []
        @subgroups = {}
        runnables.each do |runnable|
          if runnable["type"].nil? or runnable["type"].empty?
            @runnables << Runnable.new(runnable["name"], path, runnable)
          else
            type_group(runnable["type"]).add_runnable Runnable.new(runnable["name"], path, runnable)
          end
        end
      end

      def leaf?
        false
      end

      def icon
        :file
      end

      # Sort the subgroups first, the runnables after that
      def children
        @children ||= (@subgroups.sort_by(&:first).collect(&:last) + @runnables.sort_by(&:text))
      end

      # Return the type group that corresponds to the passed name-path, or self, if name is empty
      # If a child with the specified path does not exist, create it and clear the children cache
      def type_group(name)
        names = name.split("/")
        unless @subgroups[names.first]
          @children = nil
          @subgroups[names.first] = RunnableTypeGroup.new(names.first)
        end
        @subgroups[names.first].type_group(names[1..-1].join)
      end
    end
  end
end