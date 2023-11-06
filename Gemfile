source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '2.7.4'
ruby "3.1.2"

# gem  'nokogiri', '1.12.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'

# 7.0.0 UPGRADE
gem "rails", "~> 7.0.0"
gem "turbo-rails"
# end of 7.0.0 UPGRADE v df

#STRIPE setup
gem "money-rails", "~> 1.12"
gem "stripe"
gem "stripe_event"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 4.1"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker", "~> 4.0"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Admin
gem "rails_admin", "~> 3.0"

# Use Active Storage variant
gem "image_processing", "~> 1.2"

# Reduces boot times through caching; required errrein config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false
# =============== SETUP SINCE ruby 3.1.2 migration===================
# force psych version for ruby 3.1.2 migration
gem "psych", "< 4"
# to resolve rspec issues since migrating to ruby 3.1.2
gem "net-smtp", require: false
gem "net-imap", require: false
gem "net-pop", require: false
# =============== END SETUP SINCE ruby 3.1.2 migration===================

# add sweet alert
gem "devise"
gem "sweetalert2"
gem "pundit"
gem "autoprefixer-rails", "10.2.5"
gem "font-awesome-sass"
gem "simple_form"
gem "rails-i18n"
gem "bootstrap", "~> 5.2"

# xlsx spreadsheet generation
gem "caxlsx"
gem "caxlsx_rails"
# reduce log size with lograge
gem "lograge"

# gem de navbar
gem "simple_calendar", "~> 2.4"

# gem for pdf-output
gem "wicked_pdf"
gem "wkhtmltopdf-binary", "~> 0.12.3", group: :development
# gem "wkhtmltopdf-binary", group: :development
# gem 'wkhtmltopdf-heroku', '~> 2.12', '>= 2.12.6.0'
gem "wkhtmltopdf-heroku", group: :production

# Mobile device detection
gem "mobile"

# group :development, :test do
# # gem for pdf-output
#   gem 'wkhtmltopdf-binary', '~> 0.12.5'
# end

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

  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.

  gem "bullet"
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "rubocop-rails", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# add cloudinary
gem "cloudinary", "~> 1.16.0"
