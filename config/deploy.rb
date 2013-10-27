# General
set :normalize_asset_timestamps, false

# Colorizing
require "capistrano_colors"
Capistrano::Logger.add_color_matcher({:match => /\**.*/, :color => :magenta, :level => 1, :prio => -10})
Capistrano::Logger.add_color_matcher({:match => /\*\**.*/, :color => :red, :level => 0, :prio => -10})

# Set the Ruby to use
set :default_shell, "rvm-shell 'ruby-2.0.0-p247'"

# Directory to put the files into
set :application, "scrollspost-bot"

# Keep the last 5 deploys
set :keep_releases, 5
after "deploy:update", "deploy:cleanup"

# Bundler config
set :bundle_without, [:development, :test]
set :bundle_flags, "--deployment --quiet"

# Git setup
set :repository, "file:///repos/scrollspost-bot"
set :local_repository, "file://."
set :scm, "git"
set :user, "cap-deploy"

set :branch, "master"

# Server config
set :deploy_to, "/var/www/vhosts/scrollspost-bot"
set :use_sudo, false

# Server definition
server "74.91.28.2", :web, :app

#before "deploy:update_code", "deploy:prepare"

namespace :deploy do
  task :restart, :except => {:no_release => true} do
    parallel(:pty => true) do |session|
      session.when "in?(:app)", "sudo restart_bot; true"
    end
  end
end
