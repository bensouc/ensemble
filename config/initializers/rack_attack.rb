class Rack::Attack
  # Bloquer les requêtes .php (scanners WordPress/bots)
  blocklist("block php scanners") do |req|
    req.path.end_with?(".php")
  end

  # Throttle général : 300 requêtes par IP toutes les 5 minutes
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle login : 5 tentatives par email toutes les 20 secondes
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Réponse personnalisée pour les throttles (429 Too Many Requests)
  self.throttled_responder = lambda do |req|
    [429, { "Content-Type" => "text/plain" }, ["Rate limit exceeded. Retry later.\n"]]
  end
end