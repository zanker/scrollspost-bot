load "deploy" if respond_to?(:namespace)

path = File.expand_path("../", __FILE__)
Dir["capistrano/**/*.rb"].each { |plugin| require "#{path}/#{plugin}" }

require "bundler/capistrano"
#require "airbrake/capistrano"
#require "new_relic/recipes"

load "config/deploy"