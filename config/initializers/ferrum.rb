# Ferrum Configuration
#
# Ferrum uses Chrome DevTools Protocol directly (no Node.js/Puppeteer needed)
# Documentation: https://github.com/rubycdp/ferrum

# Find Chrome executable
CHROME_PATH = ENV.fetch("CHROME_PATH") do
  candidates = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium-browser",
    "/usr/bin/chromium",
    Dir.glob(File.expand_path("~/.cache/puppeteer/chrome/*/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing")).first
  ].compact

  candidates.find { |path| File.exist?(path) }
end

Rails.logger.info "Ferrum Chrome path: #{CHROME_PATH}" if defined?(Rails)
