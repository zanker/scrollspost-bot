class StatTracker
  def self.batch
    unless Thread.current[:statsd_batch]
      client = Statsd.new
      client.namespace = "scrollspost-bot"
      Thread.current[:statsd_batch] = Statsd::Batch.new(client)
      Thread.current[:statsd_batch].batch_size = 30
    end

    Thread.current[:statsd_batch]
  end

  def self.increment(key); self.gauge(key) end

  def self.gauge(key, inc=1)
    Thread.current[:statsd_agg] ||= {}
    Thread.current[:statsd_agg][key] ||= 0
    Thread.current[:statsd_agg][key] += inc
  end

  def self.flush
    return unless Thread.current[:statsd_agg]

    Thread.current[:statsd_agg].each do |key, inc|
      self.batch.gauge(key, inc)
    end

    self.batch.flush
    Thread.current[:statsd_agg].clear
  end
end