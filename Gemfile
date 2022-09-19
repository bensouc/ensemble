source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.4'



# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.0.4', '>= 6.0.4.1'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# add sweet alert
gem 'devise'
gem 'sweetalert2'

gem 'autoprefixer-rails', '10.2.5'
gem 'font-awesome-sass'
gem 'simple_form'
gem 'rails-i18n'
# gem "bootstrap", "~> 5.0.2"

# add a form_for with bbotstrap
# gem "bootstrap_form", "~> 5.1"



# reduce log size with lograge
gem "lograge"

# admin
gem 'rails_admin', ['>= 3.0.0.rc2', '< 4']
# gem de navbar
gem "simple_calendar", "~> 2.4"
# gem 'install faker'

# gem for pdf-output
gem 'wicked_pdf'
# gem "wkhtmltopdf-binary", group: :development
gem "wkhtmltopdf-heroku", '2.12.6.0'
# gem "wkhtmltopdf-heroku", group: :production

# group :development, :test do
# # gem for pdf-output
#   gem 'wkhtmltopdf-binary', '~> 0.12.5'
# end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  # autoindent erb file




  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'htmlbeautifier'
  gem "rubocop-rails", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# add cloudinary
gem 'cloudinary', '~> 1.16.0'
