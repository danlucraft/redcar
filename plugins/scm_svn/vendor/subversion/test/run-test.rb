#!/usr/bin/env ruby

require "test/unit"
require "fileutils"

test_dir = File.expand_path(File.join(File.dirname(__FILE__)))
base_src_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
base_dir = Dir.pwd
top_dir = File.expand_path(File.join(base_dir, "..", "..", "..", ".."))

ext_dir = File.join(base_dir, ".ext")
ext_svn_dir = File.join(ext_dir, "svn")
ext_svn_ext_dir = File.join(ext_svn_dir, "ext")
FileUtils.mkdir_p(ext_svn_dir)
at_exit {FileUtils.rm_rf(ext_dir)}

$LOAD_PATH.unshift(test_dir)
require 'util'
require 'test-unit-ext'

SvnTestUtil.setup_test_environment(top_dir, base_dir, ext_svn_ext_dir)

$LOAD_PATH.unshift(ext_dir)
$LOAD_PATH.unshift(base_src_dir)
$LOAD_PATH.unshift(base_dir)
$LOAD_PATH.unshift(test_dir)

require 'svn/core'
Svn::Locale.set

if Test::Unit::AutoRunner.respond_to?(:standalone?)
  exit Test::Unit::AutoRunner.run($0, File.dirname($0))
else
  exit Test::Unit::AutoRunner.run(false, File.dirname($0))
end
