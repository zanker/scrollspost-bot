module Bot
  class Ping < Bot::Core
    def receive_serverinfo(data)
      conn.send_response(:msg => :Ping)
    end

    def receive_ping(data)
      EventMachine.add_timer(rand(4..6)) { conn.send_response(:msg => :Ping)}
    end
  end
end