module Bot
  class Server < EventMachine::Connection
    STAT_FLUSH_INTERVAL = 10

    attr_accessor :disconnect_flag

    def post_init
      logger.debug "Connected"

      EventMachine.add_timer(STAT_FLUSH_INTERVAL) { self.flush_stats }
      self.class.connections << self

      @registered_msgs = {}
      @module_instances = {}
      @dispatch_cache = {}

      Dir["./modules/**/*.rb"].each do |path|
        name = File.basename(path, ".rb")
        next if name == "server" or name == "core"

        # Load it with crazy classify-ing
        klass = Bot.const_get(name.capitalize.gsub(/_([a-z])/) {|c| c.upcase}.gsub("_", ""))

        # Store the instance so we can call to it later too
        @module_instances[klass] = klass.new
        @module_instances[klass].conn = self

        # Find all of the receive methods they have registered for
        klass.instance_methods.each do |method|
          name = method.to_s
          # Internal event
          if name =~ /^internal_/
            @registered_msgs[method] ||= {}
            @registered_msgs[method][klass] = method
          # External event
          elsif name =~ /^receive_/
            name.gsub!("receive_", "")

            @registered_msgs[name] ||= {}
            @registered_msgs[name][klass] = method
          end
        end
      end
    end

    def receive_data(text)
      # No linebreak means it's a partial message and we're going to get more
      if text !~ /\n\n$/
        @pending_msg ||= ""
        @pending_msg << text
        return

      # We did have a linebreak and we're at the end of the message
      # time to re-assemble it and pass it off
      elsif @pending_msg
        text = "#{@pending_msg}#{text}"
        @pending_msg = nil
      end

      text.strip.split("\n\n").each do |data|
        logger.debug "DATA: #{data.length > 200 ? "#{data[0, 200]}..." : data.gsub("\n", '\n')}"

        data = MultiJson.load(data)

        # Figure out what key we're calling
        name = data["msg"].downcase
        if data["msg"] == "Ok"
          name = "ok_#{data["op"].downcase}"
        elsif data["msg"] == "Fail"
          name = data["op"] ? "fail_#{data["op"].downcase}" : "fail"
        else
          name = data["msg"].downcase
        end

        # And send it off if it's registered
        self.trigger_event(name, data)
      end

      logger.debug ""
    end

    def trigger_event(name, data)
      return unless @registered_msgs[name]

      @registered_msgs[name].each do |klass, method|
        @module_instances[klass].send(method, data)
      end
    end

    def send_response(data)
      data = MultiJson.dump(data)
      logger.debug "SENT: #{data}"

      send_data data << "\n"
    end

    def unbind
      logger.debug "Disconnected"
      self.class.connections.delete(self)

      # Reconnect requested already, somethings wrong
      if self.class.reconnecting
        self.class.reconnecting = nil

        logger.info "Disconnected while trying to reconnect, waiting 5 minutes and starting over..."
        sleep 5 * 60
        logger.info "Done, reconnecting"

        self.reconnect("54.208.22.193", 8081)
        return

      # Servers restarting, need to get off and then log back on
      elsif self.disconnect_flag == :server_restart
        loger.info "Got a server restart, waiting 5 minutes and reconnecting..."
        sleep 5 * 60
        logger.info "Done, reconnecting"

        self.class.reconnecting = true
        self.reconnect("54.208.22.193", 8081)
        return

      # Restart the connection automatically
      elsif self.disconnect_flag != :exit
        logger.debug "Reconnecting as we weren't told to exit."

        # Wait 5 seconds before we try and reconnect just to be safe
        sleep 5

        self.class.reconnecting = true
        self.reconnect("54.208.22.193", 8081)
        return
      end

      exit
    end

    # Flush stats to statsd
    def flush_stats
      StatTracker.flush
      EventMachine.add_timer(STAT_FLUSH_INTERVAL) { self.flush_stats }
    end

    # Trigger a shutdown
    def self.shutdown
      self.connections.each do |conn|
        conn.trigger_event(:internal_shutdown, true)

        conn.disconnect_flag = :exit
        conn.close_connection_after_writing
      end

      self.connections.clear
    end

    # Misc helpers
    def self.connections; @connections ||= [] end

    def self.logger=(logger); @logger = logger end
    def self.logger; @logger end

    def self.env=(env); @env = env end
    def self.env; @env end

    def logger; self.class.logger end
    def env; self.class.env end

    def self.reconnecting=(flag); @reconnecting = flag end
    def self.reconnecting; @reconnecting end
  end
end