
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
          image(File.expand_path(File.join(Redcar.icons_directory, icon.to_s.gsub(/_/, "-") + ".png")))
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
        swt_image(:darwin_folder)
      end
      
      def self.file_image
        swt_image(:darwin_file)
      end
    end
  end
end