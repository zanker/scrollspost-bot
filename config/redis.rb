redis_url = YAML::load_file("./config/redis.yml")[(ENV["RACK_ENV"] || "development").to_sym]

Redis.current = ConnectionPool.new(:size => 10) do
  Redis.new(:url => redis_url)
end