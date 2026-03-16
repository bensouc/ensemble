module PdfGenerator
  # Retourne un data URI base64 pour une image locale (avec cache)
  # Usage dans les templates PDF : PdfGenerator.image_data_uri("belts/belt_1.png")
  def self.image_data_uri(relative_path)
    @image_cache ||= {}
    @image_cache[relative_path] ||= begin
      full_path = Rails.root.join("app", "assets", "images", relative_path)
      "data:image/png;base64,#{Base64.strict_encode64(File.binread(full_path))}"
    end
  end

  # Retourne un data URI base64 pour une font locale (avec cache)
  def self.font_data_uri(font_filename)
    @font_cache ||= {}
    @font_cache[font_filename] ||= begin
      full_path = Rails.root.join("app", "assets", "fonts", font_filename)
      "data:font/woff2;base64,#{Base64.strict_encode64(File.binread(full_path))}"
    end
  end

  # Remplace les url("font.woff2") par des data URIs dans le HTML
  def self.inline_fonts(html)
    html.gsub(/url\("([^"]+\.woff2)"\)/) do |_match|
      font_file = Regexp.last_match(1)
      if File.exist?(Rails.root.join("app", "assets", "fonts", font_file))
        "url(\"#{font_data_uri(font_file)}\")"
      else
        _match
      end
    end
  end

  # Crée un browser Ferrum partageable pour générer plusieurs PDFs
  def self.create_browser(retries: 2)
    Rails.logger.info "[PdfGenerator] Lancement de Chrome: #{CHROME_PATH} (exists: #{File.exist?(CHROME_PATH.to_s)})"
    Ferrum::Browser.new(
      browser_path: CHROME_PATH,
      headless: true,
      timeout: 60,
      process_timeout: 60,
      browser_options: {
        "no-sandbox": true,
        "disable-setuid-sandbox": true,
        "disable-dev-shm-usage": true,
        "disable-gpu": true,
        "single-process": true
      }
    )
  rescue Ferrum::ProcessTimeoutError => e
    retries -= 1
    if retries >= 0
      Rails.logger.warn "[PdfGenerator] Chrome timeout, retry (#{retries} restants)..."
      retry
    end
    raise e
  end

  # Exécute un bloc avec un browser partagé, puis le ferme proprement
  def self.with_browser
    browser = create_browser
    yield browser
  ensure
    browser&.quit
  end

  class Base
    def initialize(layout = "pdf.html")
      @layout = layout
      @shared_browser = nil
    end

    # Permet d'injecter un browser partagé pour les générations en lot
    def with_browser(browser)
      @shared_browser = browser
      self
    end

    # Méthode abstraite qui sera implémentée par les classes dérivées
    def generate
      raise NotImplementedError, "Vous devez implémenter la méthode `generate` dans une classe dérivée"
    end

    protected

    # Génère un PDF à partir de HTML en utilisant Ferrum
    # Les marges sont en pouces (inches) pour Ferrum
    def html_to_pdf(html, options = {})
      if @shared_browser
        generate_pdf_with_browser(@shared_browser, html, options)
      else
        browser = PdfGenerator.create_browser
        begin
          generate_pdf_with_browser(browser, html, options)
        ensure
          browser.quit
        end
      end
    end

    private

    def generate_pdf_with_browser(browser, html, options)
      page = browser.create_page
      # Inliner les fonts en base64 pour éviter les requêtes réseau
      page.content = PdfGenerator.inline_fonts(html)

      # Marges en pouces (1 inch = 25.4mm)
      pdf_options = {
        format: :A4,
        print_background: true,
        margin_top: options[:margin_top] || 0.3,
        margin_bottom: options[:margin_bottom] || 0.3,
        margin_left: options[:margin_left] || 0.2,
        margin_right: options[:margin_right] || 0.2
      }

      # Ajouter header/footer si spécifié
      if options[:display_header_footer]
        pdf_options[:display_header_footer] = true
        pdf_options[:header_template] = options[:header_template] || "<span></span>"
        pdf_options[:footer_template] = options[:footer_template] || "<span></span>"
      end

      pdf_data = page.pdf(**pdf_options)
      # Ferrum retourne le PDF en base64, il faut le décoder
      Base64.decode64(pdf_data)
    ensure
      page&.close
    end
  end
end
