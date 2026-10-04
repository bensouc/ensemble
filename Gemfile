source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '2.7.4'
ruby "3.3.12"

# gem  'nokogiri', '1.12.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'

gem "rails", "~> 8.1.4"
gem "turbo-rails"

# STRIPE setup
# STRIPE SWITCH OFF
gem "stripe"
gem "stripe_event"
# gem "recaptcha"
gem "recaptcha"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 6.0"
# Use SCSS for stylesheets and  minifies them
gem "sassc-rails"
# Transpile app-like JavaScript with esbuild
gem "jsbundling-rails"
# Temps réel (Action Cable) et cache (Rack::Attack) en base, sans Redis
gem "solid_cable"
gem "solid_cache"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Jobs en base (Postgres) : Solid Queue tourne dans Puma, sans worker à part.
gem "solid_queue"
# Tableau de bord des jobs, réservé aux admins (/jobs)
gem "mission_control-jobs"
# gem "actioncable-enhanced-postgresql-adapter" back to Redis for Action Cable

# Admin
gem "rails_admin", "~> 3.0"

# Use Active Storage variant
gem "image_processing", "~> 1.2"

# Reduces boot times through caching; required errrein config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false
# Notification erroer email + slack
gem "exception_notification"
gem "slack-notifier"
gem "devise"
# Invitation d'un collègue par email : le responsable ne choisit plus le mot de
# passe à sa place. `invite_for` fixe la durée de validité du lien.
gem "devise_invitable"
# devise plug_in to manage last seen
gem "devise_last_seen"
# usurpation d'identité par un admin (« naviguer en tant que »)
gem "pretender"
gem "pundit"
gem "autoprefixer-rails", "10.2.5"
gem "font-awesome-sass"
gem "simple_form"
gem "rails-i18n"
gem "bootstrap", "~> 5.2"

#  add red or unred object gem
gem "unread"

# act_as_list help manage list
gem "acts_as_list", "~> 0.7.2"
# xlsx spreadsheet generation
gem "caxlsx"
gem "caxlsx_rails"
# xlsx spreadsheet upload and read
gem "simple_xlsx_reader", "~> 1.0", ">= 1.0.4"

# reduce log size with lograge
gem "lograge"

# Protection bots / brute-force (throttle, blocklist, fail2ban applicatif)
gem "rack-attack"

# PDF : Chrome headless piloté par Ferrum
gem "ferrum"

# Détection du navigateur (PagesController)
gem "browser"

# view_component 4 ne dérive plus d'ActionView::Base ; les trois composants de
# l'app (ceintures, bouton de validation) n'utilisent rien de ce qu'elle retire.
gem "view_component", "~> 4.15"

# Simple cov test
gem "simplecov", require: false, group: :test

group :development, :test do
  gem "rails-controller-testing"
  gem "erb-formatter"
  gem "htmlbeautifier"
  gem "pry-byebug"
  gem "pry-rails"
  gem "dotenv-rails"
  # autoindent erb file

  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 4.0"
  gem "faker"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.

  # Lit les mails produits par l'app sur /letter_opener, sans rien envoyer.
  gem "letter_opener_web"

  gem "bullet"
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.2"
  gem "rubocop-rails", require: false
  # Audits de sécurité lancés par bin/ci : le code (Brakeman) et les gems
  # (avis publiés contre les versions du Gemfile.lock).
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# add cloudinary
gem "cloudinary", "~> 1.16.0"
