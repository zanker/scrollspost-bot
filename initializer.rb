require "rubygems"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../Gemfile", __FILE__)
require "bundler/setup"

env = (ENV["RACK_ENV"] || "development").to_sym
Bundler.require(:default, env)

# Load the app
require "./lib/internal_alert"
require "./lib/stat_tracker"
require "./config/airbrake"
require "./config/redis"
require "./modules/server"
require "./modules/core"
Dir["./modules/**/*.rb"].each {|f| require f}

# Hookup config
Bot::Server.logger = Logger.new(STDOUT)
Bot::Server.env = env

if env == :test and !ENV["VERBOSE"] and !ENV["VVERBOSE"]
  Bot::Server.logger.level = Logger::Severity::WARN
else
  Bot::Server.logger.level = ENV["VVERBOSE"] ? Logger::Severity::DEBUG : Logger::Severity::INFO
end

require "./app"
