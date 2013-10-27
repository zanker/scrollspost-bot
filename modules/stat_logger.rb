module Bot
  class StatLogger < Bot::Core
    STATS_QUEUE = "stats-queue"
    STATS_TIMER = 5 * 60

    def receive_ok_signin(data)
      conn.send_response(:msg => "OverallStats")
    end

    def receive_overallstats(data)
      Redis.current.with do |r|
        r.multi do
          r.lpush(STATS_QUEUE, "online,#{data["nrOfProfiles"]},#{Time.now.utc.to_i}")
          r.lpush(STATS_QUEUE, "totalcards,#{data["totalCards"]},#{Time.now.utc.to_i}")
          r.lpush(STATS_QUEUE, "totalgold,#{data["totalGoldRewarded"]},#{Time.now.utc.to_i}")
          r.lpush(STATS_QUEUE, "totalsold,#{data["totalSoldCards"]},#{Time.now.utc.to_i}")
        end
      end

      # Update stats periodically
      EventMachine.add_timer(STATS_TIMER) { conn.send_response(:msg => "OverallStats")}
    end
  end
end