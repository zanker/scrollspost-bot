module Bot
  class TradeDebugger < Bot::Core
    def receive_tradeinviteforward(data)
      if data["inviter"]["userUuid"] == "0d81542494b54eeb97988d59cce536bb"
        conn.send_response(:msg => "TradeAccept", :inviter => data["inviter"]["id"])
      end
    end
  end
end