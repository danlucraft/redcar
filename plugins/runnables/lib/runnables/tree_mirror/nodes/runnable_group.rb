module Redcar
  class Runnables
    class RunnableGroup
      include Redcar::Tree::Mirror::NodeMirror

      def initialize(name,path,runnables)
        @children = []
        @name = name
        if runnables.any?
          group = []
          type = nil
          i = 0
          runnables.map.sort_by{|r|r["type"]||""}.each do |runnable|
            if runnable["type"] == nil or runnable["type"] == ""
              @children << Runnable.new(runnable["name"],path,runnable)
            elsif type.nil?
              type = runnable["type"]
              group << runnable
            elsif type == runnable["type"]
              group << runnable
            end
            if i == runnables.length - 1 or type != runnable["type"]
              if type == name
                group.each {|r| @children << Runnable.new(r["name"],path,r)}
              else
                type = type[name.length,type.length] if type =~ /^#{name}/
                type = type[1,type.length] if type =~ /^\//
                if type == ""
                  @children << Runnable.new(runnable["name"],path,runnable)
                else
                  @children << RunnableTypeGroup.new(type,path,group) unless group.size == 0
                end
              end
              type = runnable["type"]
              group = [runnable]
            end
            i = i + 1
          end
        end
      end

      def leaf?
        false
      end

      def text
        @name
      end

      def icon
        :file
      end

      def children
        @children
      end
    end
  end
end