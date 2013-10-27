module Bot
  class Core
    def conn; @conn end
    def conn=(conn); @conn = conn end
    def logger; Bot::Server.logger end
  end
end