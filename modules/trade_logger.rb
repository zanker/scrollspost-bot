module Bot
  class TradeLogger < Bot::Core
    TRADE_CHANNELS = Hash[(["trading", "wtb", "wts"] + 30.times.map {|i| "trading-#{i + 1}"}).map {|r| [r, true]}]
    TRADE_QUEUE = "trade-msg-queue"

    # Can start trying to join Trading
    def receive_roomslist(data)
      TRADE_CHANNELS.each_key do |channel|
        conn.trigger_event(:internal_auto_join, channel)
      end
    end

    def receive_roomchatmessage(data)
      # Log trade messages to redis for further parsing
      if TRADE_CHANNELS[data["roomName"].downcase]
        StatTracker.increment("trade.volume/#{data["roomName"].downcase}")

        Redis.current.with do |r|
          r.lpush(TRADE_QUEUE, MultiJson.dump("room" => data["roomName"], "from" => data["from"], "msg" => data["text"], "created_at" => Time.now.utc.to_i))
        end
      end
    end
  end
end