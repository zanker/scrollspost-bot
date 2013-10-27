module Bot
  class PriceCheck < Bot::Core
    PRICE_CHANNEL = "scrollspost-pc"
    CARD_STATS = "card-stats"

    def receive_ok_signin(data)
      conn.trigger_event(:internal_auto_join, PRICE_CHANNEL)
    end

    def receive_roomenter(data)
      if data["roomName"] == PRICE_CHANNEL
        conn.send_response(:msg => "RoomChatMessage", :roomName => PRICE_CHANNEL, :text => "ScrollsPost Price Check ready to go! Type .p <name> for a price check.")
      end
    end

    def internal_shutdown(now)
      conn.send_response(:msg => "RoomChatMessage", :roomName => PRICE_CHANNEL, :text => "Shutting down quickly, back in a second.")
    end

    def receive_roomchatmessage(data)
      return unless data["roomName"] == PRICE_CHANNEL

      if data["text"] == ".h" || data["text"] == ".help" || data["text"] == ".help"
        conn.send_response(:msg => "RoomChatMessage", :roomName => PRICE_CHANNEL, :text => "Type .p <name> for a price check.")

      elsif data["text"] =~ /^\.p (.+)/
        name = data["text"].split(" ", 2).last
        return unless name

        # Strip out parts to make it easier to look up and slightly more resilient to typos
        parsed_name = name.gsub(/[^a-zA-Z0-9]/, "").downcase

        card_id = Redis.current.with {|r| r.hget(Bot::CardData::CARD_MAP, parsed_name)}
        if card_id
          stats, card_name = nil, nil
          Redis.current.with do |r|
            stats = r.hget(CARD_STATS, card_id)
            card_name = r.hget("card:#{card_id}", "name")
          end

          # Found price
          if stats
            suggested, buy, sell = stats.split(",")
            conn.send_response(:msg => "RoomChatMessage", :roomName => PRICE_CHANNEL, :text => "[#{card_name}] Last 24 hours: #{(suggested.to_f / 5).round * 5}g suggested, #{(buy.to_f / 5).round * 5}g buy, #{(sell.to_f / 5).round * 5}g sell")

          # Good card, no info found
          else
            conn.send_response(:msg => "RoomChatMessage", :roomName => PRICE_CHANNEL, :text => "[#{card_name}] No price data found yet")
          end

        # No card found
        else
          conn.send_response(:msg => "RoomChatMessage", :roomName => PRICE_CHANNEL, :text => "[#{name}] Unknown scroll")
        end
      end
    end
  end
end