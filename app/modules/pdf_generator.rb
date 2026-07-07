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

  # Remplace les url() de fonts woff2 par des data URIs base64 dans le HTML
  # Gère les deux formats :
  #   - Dev (Sprockets live) : url("roboto-400.woff2")
  #   - Prod (precompiled)   : url(/assets/roboto-400-DIGEST.woff2)
  # On inline en base64 pour éviter que Chrome headless fasse des requêtes file://
  # qui restent en "pending connections" et causent des timeouts.
  def self.resolve_font_paths(html)
    @font_cache ||= {}
    fonts_dir = Rails.root.join("app", "assets", "fonts")
    html.gsub(/url\(["']?([^"')]+\.woff2)["']?\)/) do |_match|
      font_url = Regexp.last_match(1)
      # Extraire le nom de base du fichier (sans /assets/ ni digest)
      # "/assets/roboto-400-abc123.woff2" → "roboto-400"
      basename = File.basename(font_url, ".woff2").sub(/-[0-9a-f]{32,}$/, "")
      font_file = "#{basename}.woff2"
      full_path = fonts_dir.join(font_file)
      if File.exist?(full_path)
        @font_cache[font_file] ||= Base64.strict_encode64(File.binread(full_path))
        "url(\"data:font/woff2;base64,#{@font_cache[font_file]}\")"
      else
        _match
      end
    end
  end

  # Crée un browser Ferrum partageable pour générer plusieurs PDFs.
  #
  # Deux modes selon l'environnement :
  #   - CHROME_URL défini (ex. "http://chrome:3000") → connexion à un Chromium
  #     distant long-lived (service dédié, ex. browserless sur Coolify). Aucun
  #     process n'est spawné localement ; le service pilote ses propres flags.
  #   - sinon → spawn d'un Chromium local (dev macOS, ou fallback conteneur).
  #     NB : PAS de "single-process" — ce flag (hack mémoire hérité de Scalingo)
  #     fait figer Chromium au démarrage en conteneur ("Browser did not produce
  #     websocket url").
  def self.create_browser(retries: 2)
    if (chrome_url = ENV["CHROME_URL"]).present?
      Rails.logger.info "[PdfGenerator] Connexion à Chrome distant: #{chrome_url.sub(/token=[^&]+/, 'token=***')}"
      opts = { timeout: 120, process_timeout: 120 }
      # ws://host:3000?token=... (browserless) → ws_url (utilisé tel quel par Ferrum).
      # http://host:9222 (endpoint CDP classique) → url (Ferrum lit /json/version).
      if chrome_url.start_with?("ws://", "wss://")
        opts[:ws_url] = chrome_url
      else
        opts[:url] = chrome_url
      end
      Ferrum::Browser.new(**opts)
    else
      Rails.logger.info "[PdfGenerator] Lancement de Chrome: #{CHROME_PATH} (exists: #{File.exist?(CHROME_PATH.to_s)})"
      Ferrum::Browser.new(
        browser_path: CHROME_PATH,
        headless: true,
        timeout: 120,
        process_timeout: 120,
        browser_options: {
          "no-sandbox": true,
          "disable-setuid-sandbox": true,
          "disable-dev-shm-usage": true,
          "disable-gpu": true
        }
      )
    end
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
      # Inline les fonts woff2 en data URIs base64 (avec les images déjà inlinées,
      # le HTML est 100% autonome : aucune requête réseau ni fichier).
      resolved_html = PdfGenerator.resolve_font_paths(html)

      page = browser.create_page
      # On injecte le HTML directement via CDP (Page.setDocumentContent) au lieu d'un
      # fichier file:// : INDISPENSABLE avec un Chrome DISTANT (browserless), où un
      # file:// pointerait vers le FS du conteneur Chrome, pas celui de Rails.
      page.content = resolved_html

      # S'assurer que les webfonts (data: URIs) sont appliquées avant de rendre le PDF.
      # NB : capturer le callback resolve (arguments[0]) AVANT le .then, sinon il est
      # ré-ombré par les arguments du callback.
      begin
        page.evaluate_async("var done = arguments[0]; document.fonts.ready.then(function() { done(true); });", 5)
      rescue Ferrum::Error => e
        Rails.logger.warn "[PdfGenerator] fonts.ready ignoré: #{e.message}"
      end

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
