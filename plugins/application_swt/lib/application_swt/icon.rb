
module Redcar
  class ApplicationSWT
    module Icon
      def self.swt_image(icon)
        case icon
        when :directory
          dir_image
        when :file
          file_image
        when Symbol
          image(File.expand_path(File.join(Redcar::ICONS_DIRECTORY, icon.to_s.gsub(/_/, "-") + ".png")))
        when String
          image(icon)
        end
      end
      
      def self.image(path)
        cached_images[path] ||= Swt::Graphics::Image.new(ApplicationSWT.display, path)
      end
      
      def self.cached_images
        @cached_images ||= {}
      end
      
      def self.dir_image
        path = File.join(Redcar.root, %w(plugins application icons darwin-folder.png))
        image(path)
      end
      
      def self.file_image
        path = File.join(Redcar.root, %w(plugins application icons darwin-file.png))
        image(path)
      end
    end
  end
end