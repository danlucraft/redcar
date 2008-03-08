
require 'rubygems'
require 'hoe'
require 'fileutils'

# Hoe.new('Redcar', Redcar::VERSION) do |p|
#   p.rubyforge_name = 'redcar'
#   p.author = 'Daniel Lucraft'
#   p.email = 'dan@fluentradical.com'
#   p.summary = 'Pure Ruby text editor.'
#   p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
#   p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
#   p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
# end

namespace :test do
  task :all => [:syntax]
  
  task :syntax do
    sh "testrb test/syntax_texttab_test.rb"
    sh "rg test/syntax_grammar_test.rb"
    sh "rg test/syntax_scope_test.rb"
    sh "rg test/syntax_parser_test.rb"
    sh "rg test/syntax_theme_test.rb"
  end

  task :syntax_quick do
    sh "rg test/syntax_grammar_test.rb"
    sh "rg test/syntax_scope_test.rb"
    sh "rg test/syntax_parser_test.rb"
    sh "rg test/syntax_theme_test.rb"
  end
end

task :coredoc2 do
  FileUtils.rm_rf "doc"
  FileUtils.mkdir "tmpfordoc"
  Dir["plugins2/core/*"].each do |fn|
    if File.file? fn
      FileUtils.cp fn, "tmpfordoc/"+fn.split("/").last
    end
  end
  sh "rdoc -T jamis tmpfordoc/"
  FileUtils.rm_rf "tmpfordoc"
end

task :coredoc do
  FileUtils.rm_rf "doc"
  files = Dir["plugins2/core/*"].select{|f| File.file? f}
  sh "rdoc -T jamis #{files.join(" ")}"
end
