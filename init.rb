require File.join(File.dirname(__FILE__), 'lib', 'git_plugins')

config_file = File.join(File.dirname(__FILE__), "..", "..", "..", "config", "initializers", "git_plugins.rb")
require config_file if File.exists?(config_file)
