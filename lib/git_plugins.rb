class GitPlugins
  attr_accessor :plugins, :gitignore_file
  
  def self.instance
    @@git_plugins ||= GitPlugins.new
  end
  
  def self.configure
    yield instance
  end

  def self.plugins
    instance.plugins
  end

  def plugins
    @plugins ||= {}
  end

  def gitignore_file
    @gitignore_file ||= default_ignore_file
  end

  def self.clear
    @@git_plugins = nil
  end

  def self.each(&block)
    plugins.each(&block)
  end
  
  def self.checkout(*args)
    instance.checkout(*args)
  end

  def checkout(plugin_name)
    unless already_checked_out?(plugin_name)
      run_command("cd #{plugins_dir} && #{git_command} clone #{url(plugin_name)} #{plugin_name}") 
    end
  end

  def already_checked_out?(plugin_name)
    File.exists?(plugin_path(plugin_name))
  end
  
  def self.checkout_all
    instance.checkout_all
  end

  def checkout_all
    plugins.keys.each do |name|
      checkout(name)
      ignore(name)
    end
  end

  def self.status
    instance.status
  end

  def status
    run_each("#{git_command} status")
  end

  def self.pull
    instance.pull
  end

  def pull
    run_each("#{git_command} pull")
  end

  def self.run_each(command)
    instance.run_each(command)
  end

  def run_each(command)
    plugins.keys.each do |name|
      run_command("cd #{plugin_path(name)} && #{command}")
    end    
  end

  def self.ignore(plugin_name)
    instance.ignore(plugin_name)
  end
  
  def ignore(plugin_name)
    ignore_pattern = 
      Pathname.new(File.join(plugins_dir, plugin_name.to_s)).relative_path_from(Pathname.new(File.dirname(gitignore_file)))
    if !File.exists?(gitignore_file) || IO.read(gitignore_file) !~ /^#{ignore_pattern}$/
        File.open(gitignore_file, "a") { |file| file.puts ignore_pattern }        
    end
  end
  
  def plugin(options = {})
    require_options(options, :name, :url)
    plugins[options[:name].to_sym] = options.reject { |key, value| key == :name }
  end
  
  def url(plugin_name)
    plugins[plugin_name.to_sym][:url]    
  end
  
  private
  def default_ignore_file
    File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "..", ".gitignore"))
  end
  
  def plugins_dir
    File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  end
  
  def plugin_path(plugin_name)
    File.join(plugins_dir, plugin_name.to_s)
  end
  
  def require_options(options, *required_options)
    required_options.each do |required_option|
      options[required_option] || raise("Missing '#{required_option}' option in '#{options.inspect}'")
    end    
  end

  def git_command
    "git --no-pager"
  end

  def run_command(command)
    puts command
    system command
    raise "command='#{command}' failed with return code '#{$?}'" if $? != 0
  end
end

config_file = File.join(File.dirname(__FILE__), "..", "..", "..", "..", "config", "git_plugins.rb")
File.exists?(config_file) ? require(config_file) : raise("Missing Git plugins config file at #{config_file}")
