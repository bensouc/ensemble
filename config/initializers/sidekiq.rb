Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] || "redis://localhost:6379/0" }

  # Queue PDF avec concurrency 1 pour éviter que 2 Chrome tournent en //
  # sur un worker 256 MB
  config.capsule("pdf") do |cap|
    cap.concurrency = 1
    cap.queues = %w[pdf]
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] || "redis://localhost:6379/0" }
end
