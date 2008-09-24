require File.join(File.dirname(__FILE__), "..", "init")

namespace :git do
  namespace :plugins do
    task :environment do
      require File.join(File.dirname(__FILE__), '..', 'lib', 'git_plugins')
    end
    
    desc "Checkout all external Git plugins under vendor/plugins and add them to .gitignore"
    task :checkout => :environment do
      GitPlugins.checkout_all
    end
    
    desc "Run git status on all Git plugins"
    task :status => :environment do
      GitPlugins.status
    end

    desc "Run git pull on all Git plugins"
    task :pull => :environment do
      GitPlugins.pull
    end
    
    desc "Run CMD='some command' in each Git plugin"
    task :run => :environment do
      ENV['CMD'] || raise("please specify a command to run in the environment variable CMD")
      GitPlugins.run_each(ENV['CMD'])
    end    
  end
end
