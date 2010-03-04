require 'rubygems'
require 'zip/zipfilesystem'

module Zip

# unzip a .zip file into the directory it is located
def self.unzip_file(source)
  source = File.expand_path(source)
  Dir.chdir(File.dirname(source)) do
      Zip::ZipFile.open(source) do |zipfile|
        zipfile.entries.each do |entry|
      	  FileUtils.mkdir_p File.dirname(entry.name)
      	  begin
        	  entry.extract
        	rescue Zip::ZipDestinationFileExistsError
        	  # ignore
        	end
        end
      end
  end

end
end