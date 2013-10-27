EventMachine.error_handler do |ex|
  Airbrake.notify(ex)
end

trap("SIGINT") do
  puts "Attempting to shut down"

  Bot::Server.shutdown
  StatTracker.flush
end

# Note that this will block current thread.
EventMachine.run do
  # 107.21.58.31 54.208.22.193
  EventMachine.connect("54.208.22.193", 8081, Bot::Server)
end