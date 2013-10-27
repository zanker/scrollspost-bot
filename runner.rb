require "rubygems"

begin
  pidfile = "./tmp/pids/bot.pid"
  File.open(pidfile, "w") { |f| f << Process.pid }

  require "bundler/setup"
  require "./lib/stat_tracker.rb"

  # Dumpe verything to the logger
  require "logger"
  def reopen_files
    env = ENV["RACK_ENV"] || "development"
    STDOUT.reopen(File.open("./log/#{env}.out.log", "a"))
    STDOUT.sync = true

    STDERR.reopen(File.open("./log/#{env}.err.log", "a"))
    STDERR.sync = true
  end

  trap("USR2") do
    reopen_files

    puts "Log files reopened"
    STDOUT.flush
    STDERR.flush
  end

  reopen_files
  require "./initializer"

rescue SystemExit, SignalException
rescue Exception => e
  puts "#{e.class}: #{e.message}"
  puts e.backtrace.join("\n")

  require "airbrake"
  require "./config/airbrake"

  res = Airbrake.notify_or_ignore(e, {:parameters => {}, :session_data => {}, :controller => "internal", :action => "script", :url => "", :cgi_data => {}})
  sleep 5
  puts "Logger response #{res}"

ensure
  File.unlink(pidfile) rescue nil

  if defined?(::NewRelic)
    ::NewRelic::Agent.shutdown
  end
end