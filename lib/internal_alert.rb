class InternalAlert
  def self.deliver(klass, subject, body="")
    if defined?(Bot::Server) and Bot::Server.env != :production
      puts "#{klass.name}: #{subject}"
      # Strip out the body at the very end as it's unneeded
      puts body.gsub(/\n\n(.+)$/, "")
      return
    end

    StatTracker.increment("error/total")

    id = Digest::MD5.hexdigest("#{klass}#{subject}")

    Redis.current.with do |r|
      res = r.setnx("alerts-#{id}", "1")
      # Already set
      return unless res
      r.expire("alerts-#{id}", 10.minutes)
    end

    Mail.new do
      to "alerts@scrollspost.com"
      from "alerts@scrollspost.com"
      subject "[#{klass.name}] #{subject}"
      body body
    end.deliver
  end
end