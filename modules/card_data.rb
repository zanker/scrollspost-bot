module Bot
  class CardData < Bot::Core
    CARD_LIST = "card-list"
    CARD_QUEUE = "card-queue"
    CARD_MAP = "card-map"
    CARD_REFRESH_TIMER = 30 * 60

    def receive_ok_signin(data)
      @initial_query = true
      conn.send_response(:msg => "CardTypes")
    end

    def receive_cardtypes(data)
      Redis.current.with do |r|
        sync_flags = {}

        r.multi do
          ids = data["cardTypes"].map do |card|
            r.hset(CARD_MAP, "#{card["name"].gsub(/[^a-zA-Z0-9]/, "").downcase}", card["id"])

            r.hmset("card:#{card["id"]}",
              "name", card["name"], "desc", card["description"], "flav", card["flavor"],
              "types", card["subTypesStr"], "rarity", card["rarity"],
              "hp", card["hp"], "atk", card["ap"], "cd", card["ac"],
              "c-energy", card["costEnergy"], "c-decay", card["costDecay"], "c-order", card["costOrder"], "c-growth", card["costGrowth"],
              "rules", card["rulesList"].join(","),
              "img", card["cardImage"], "animPrevImg", card["animationPreviewImage"], "animPrevInfo", card["animationPreviewInfo"], "animBundle", card["animationBundle"],
              "abilities", MultiJson.dump(card["abilities"]),
              "target", card["targetArea"],
              "passiveRules", MultiJson.dump(card["passiveRules"]),
              "avail", card["available"])

            # Initial query, push them all into the queue to confirm nothing has changed
            if @initial_query
              r.lpush(CARD_QUEUE, card["id"])
            # Otherwise we actually found a new card and we need to update
            else
              sync_flags[card["id"]] = r.sadd(CARD_LIST, card["id"])
            end
          end
        end

        # Check if we added any new cards
        sync_flags.each do |id, future|
          if future.value == 1
            r.lpush(CARD_QUEUE, id)
          end
        end
      end

      @initial_query = nil

      EventMachine.add_timer(CARD_REFRESH_TIMER) { conn.send_response(:msg => "CardTypes") }
    end
  end
end