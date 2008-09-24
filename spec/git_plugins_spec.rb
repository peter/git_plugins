require File.dirname(__FILE__) + '/spec_helper'
require 'fileutils'
require 'pathname'

describe GitPlugins do
  before(:each) do
    clear_git_plugins_config
    GitPlugins.configure do |g|
      g.plugin :name => "server_config", :url => "http://server.plugin.url"
      g.plugin :name => "foobar", :url => "http://foobar.plugin.url"
      g.plugin :name => "git_plugin_test", :url => "git://github.com/peter/server_config.git"
    end
    @plugins = GitPlugins.instance
    GitPlugins.instance.gitignore_file = ignore_path      
  end

  after(:each) do
    FileUtils.rm_rf(plugin_path) if File.exists?(plugin_path)    
    FileUtils.rm_f(ignore_path) if File.exists?(ignore_path)
  end

  it "has a plugins accessor method" do
    @plugins.plugins.size.should == 3
    @plugins.plugins[:server_config][:url].should == "http://server.plugin.url"
    @plugins.plugins[:foobar][:url].should == "http://foobar.plugin.url"
  end

  it "has an each method that lets you iterate over all plugins" do
    GitPlugins.each do |name, plugin|
      [:server_config, :foobar, :git_plugin_test].should include(name)
      plugin[:url].should == "http://server.plugin.url" if name == :server_config
    end
  end

  ###################################################################
  #
  # Git operations
  #
  ###################################################################

  describe "git operations" do
    before(:each) do
      GitPlugins.instance.plugins = {}
      GitPlugins.configure do |g|
        g.plugin :name => "git_plugin_test", :url => "git://github.com/peter/server_config.git"
      end      
    end
    
    it "has a checkout method that clones out a plugin under vendor/plugins" do
      FileUtils.rm_rf(plugin_path)
      GitPlugins.checkout(:git_plugin_test)
      File.exists?(plugin_path).should be_true
      File.exists?(File.join(plugin_path, ".git")).should be_true
      File.exists?(File.join(plugin_path, "README")).should be_true
      File.exists?(File.join(plugin_path, "lib", "server_config.rb")).should be_true
    end

    it "has a checkout_all method that clones out all plugins under vendor/plugins and adds them to .gitignore" do
      GitPlugins.instance.should_receive(:checkout).with(:git_plugin_test)
      GitPlugins.checkout_all
      IO.readlines(ignore_path).should == ["plugins/git_plugin_test\n"]    
    end

    it "has status method that does a git status on all plugins" do
      GitPlugins.instance.should_receive(:run_command).with("cd #{plugin_path} && git status")
      GitPlugins.status
    end

    it "has a pull method that does a git pull on all plugins" do
      GitPlugins.instance.should_receive(:run_command).with("cd #{plugin_path} && git pull")
      GitPlugins.pull
    end
    
    it "has a run_each method to run an arbitrary command in each plugin" do
      GitPlugins.instance.should_receive(:run_command).with("cd #{plugin_path} && arbitrary command")
      GitPlugins.run_each("arbitrary command")
    end
  end

  ###################################################################
  #
  # Managing .gitignore files
  #
  ###################################################################
  
  it "has a gitignore_file accessor method for setting which .gitignore file to use" do
    GitPlugins.instance.gitignore_file = nil
    GitPlugins.instance.gitignore_file.should == File.join(RAILS_ROOT, ".gitignore")
    GitPlugins.instance.gitignore_file = "foobar"
    GitPlugins.instance.gitignore_file.should == "foobar"
  end

  it "has a an ignore method that adds a plugin to new .gitignore file" do
    FileUtils.rm_f(ignore_path)      
    GitPlugins.ignore(:git_plugin_test)
    IO.readlines(ignore_path).should == ["plugins/git_plugin_test\n"]      
  end

  it "has a an ignore method that adds a plugin to an existing .gitignore file" do
    File.open(ignore_path, "w") { |file| file.puts "plugins/foobar" }
    GitPlugins.ignore(:git_plugin_test)
    IO.readlines(ignore_path).should == ["plugins/foobar\n", "plugins/git_plugin_test\n"]
  end

  it "has a an ignore method that doesn't change the .gitignore file if the plugin is already there" do
    File.open(ignore_path, "w") { |file| file.puts "plugins/git_plugin_test\nplugins/foobar" }
    GitPlugins.ignore(:git_plugin_test)
    IO.readlines(ignore_path).should == ["plugins/git_plugin_test\n", "plugins/foobar\n"]      
  end

  ###################################################################
  #
  # Helper methods
  #
  ###################################################################
  
  def ignore_path
    File.join(RAILS_ROOT, "vendor", ".gitignore_test")      
  end

  def clear_git_plugins_config
    GitPlugins.clear
    GitPlugins.plugins.should be_blank    
  end
  
  def plugin_path
    File.join(RAILS_ROOT, "vendor", "plugins", "git_plugin_test")
  end
end
