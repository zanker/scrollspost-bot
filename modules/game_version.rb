module Bot
  class GameVersion < Bot::Core
    GAME_VERSION = "game-version"
    RECHECK_GAME_VERSION = 30 * 60

    def receive_serverinfo(data)
      @game_news_url = "#{data["assetURL"]}news.txt"
      @cache_headers = {}

      Redis.current.with do |r|
        r.set(GAME_VERSION, data["version"])
      end

      logger.info "Current game version is #{data["version"]}"
      self.check_game_version
    end

    def check_game_version
      http = EventMachine::HttpRequest.new(@game_news_url).get(:head => @cache_headers)
      http.errback do
        StatTracker.increment("game.news/error")
        EventMachine.add_timer(RECHECK_GAME_VERSION) { self.check_game_version }
      end

      http.callback do
        StatTracker.increment("game.news/#{http.response_header.status}")

        # Something changed
        if http.response_header.status == 200
          digest = Digest::SHA1.hexdigest(http.response.strip)

          # News changed, reconnect since it should mean a version change
          if @news_digest and @news_digest != digest
            @news_digest = digest
            logger.info "Reconnecting due to news change, possible game update"

            conn.close_connection_after_writing
            next
          end

          @news_digest = digest
        end

        @cache_headers["If-None-Match"] = http.response_header.etag
        @cache_headers["If-Modified-Since"] = http.response_header.last_modified

        EventMachine.add_timer(RECHECK_GAME_VERSION) { self.check_game_version }
      end
    end
  end
end