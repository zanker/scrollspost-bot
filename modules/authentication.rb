module Bot
  class Authentication < Bot::Core
    def receive_serverinfo(data)
      @login_timer = EventMachine.add_timer(10) { conn.close_connection_after_writing }

      conn.send_response(:msg => "SignIn", "email" => "secret", "password" => "secret")
    end

    def receive_serverrestart(data)
      Bot::Server.disconnect_flag = :server_restart
      conn.close_connection_after_writing
    end

    def receive_ok_signin(data)
      Bot::Server.reconnecting = nil

      EventMachine.cancel_timer(@login_timer)
      @authenticated = true
    end

    def receive_fail(data)
      InternalAlert.deliver(self.class, "Failure from connection", "#{data.inspect}")

      conn.close_connection_after_writing
    end
  end
end