module Bot
  class RoomManager < Bot::Core
    NOTICE = "[Notice]"
    FROM_SERVER = "Scrolls"

    def initialize; @auto_join, @room_state = {}, {} end

    def internal_auto_join(channel)
      @auto_join[channel.downcase] = 0

      # Timer lets other auto triggers register too
      EventMachine.add_timer(1) { conn.send_response(:msg => "RoomEnter", :roomName => channel) }
    end

    # Entered a new room
    def receive_roomenter(data)
      if @auto_join[data["roomName"].downcase] == 0
        @auto_join[data["roomName"].downcase] = true

        # Check if we can leave [Notice]
        finished = true
        @auto_join.each do |channel, flag|
          if flag == 0
            finished = nil
            break
          end
        end

        if finished
          logger.info "Entered all auto join channels, can leave notice."
          conn.send_response(:msg => "RoomExit", :roomName => NOTICE)
        end
      end
    end

    # Check if we failed to auto join
    def receive_roomchatmessage(data)
      if data["roomName"] == NOTICE and data["from"] == FROM_SERVER
        name = data["text"].match(/.([a-z0-9]+). is full/i)
        if name and @auto_join[name[1].downcase] == 0
          EventMachine.add_timer(rand(1..3)) { conn.send_response(:msg => "RoomEnter", :roomName => name[1]) }
        end
      end
    end

    # Grab the room list
    def receive_ok_signin(data)
      conn.send_response(:msg => "RoomsList")
    end

    def receive_roominfo(data)
      state = @room_state[data["roomName"]] ||= {:profiles => {}}

      profiles_found = {}
      data["profiles"].each do |profile|
        id = profile.delete("id")

        profiles_found[id] = true
        next if state[:profiles][id]

        state[:profiles][id] = {:name => profile["name"], :trades => data["acceptTrades"], :joined_at => Time.now.utc, :admin => data["adminRole"] == "None" ? false : data["adminRole"]}

        #logger.info "#{profile["name"]} joined #{data["roomName"]}"
      end

      state[:profiles].each do |id, profile|
        unless profiles_found[id]
          #logger.info "#{profile[:name]} left #{data["roomName"]}"

          state[:profiles].delete(id)
        end
      end
    end

    def receive_roomexit(data)
      @room_state.delete(data["roomName"])
    end
  end
end