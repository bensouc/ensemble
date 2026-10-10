# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
# Only use pidfile in development (Scalingo manages processes in production)
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" } unless ENV["RAILS_ENV"] == "production"

# Plusieurs processus Puma : un seul n'occupe qu'un cœur à la fois (le GVL de
# Ruby), quel que soit son nombre de threads. Le VPS en a quatre.
#
# Inerte tant que WEB_CONCURRENCY n'est pas posé à 2 ou plus : la production
# reste en un seul processus jusqu'à ce qu'on le décide dans Coolify, et le
# développement n'est jamais forké. Mesuré le 10/10/2026 avant d'en poser
# deux : 4,6 Go disponibles sur 7,6, le conteneur web à 607 Mo.
#
# `preload_app!` charge l'application une fois avant de forker : les processus
# partagent sa mémoire (copy-on-write) au lieu de la payer chacun. Solid Queue
# reste lancé une seule fois, par le processus maître (plugin plus bas).
web_concurrency = ENV["WEB_CONCURRENCY"].to_i # absente ou vide : 0, un seul processus
if web_concurrency > 1
  workers web_concurrency
  preload_app!
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Solid Queue dans Puma : le superviseur des jobs démarre avec le serveur web,
# sans conteneur worker à maintenir. Actif par défaut en production ;
# SOLID_QUEUE_IN_PUMA=false le coupe (si un conteneur lance `bin/jobs` à part),
# SOLID_QUEUE_IN_PUMA=true l'allume ailleurs. En développement : `bin/jobs`.
solid_queue_in_puma = ENV.fetch("SOLID_QUEUE_IN_PUMA") { ENV["RAILS_ENV"] == "production" ? "true" : "false" }
plugin :solid_queue if solid_queue_in_puma == "true"
