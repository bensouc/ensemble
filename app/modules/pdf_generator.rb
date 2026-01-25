module PdfGenerator
  class Base
    def initialize(layout = "pdf.html")
      @layout = layout
    end

    # Méthode abstraite qui sera implémentée par les classes dérivées
    def generate
      raise NotImplementedError, "Vous devez implémenter la méthode `generate` dans une classe dérivée"
    end

    protected

    # Génère un PDF à partir de HTML en utilisant Ferrum
    # Les marges sont en pouces (inches) pour Ferrum
    def html_to_pdf(html, options = {})
      browser = Ferrum::Browser.new(
        browser_path: CHROME_PATH,
        headless: true,
        browser_options: {
          "no-sandbox": true,
          "disable-setuid-sandbox": true,
          "disable-dev-shm-usage": true
        }
      )

      begin
        page = browser.create_page
        page.content = html

        # Attendre que le contenu soit chargé
        page.network.wait_for_idle

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
        browser.quit
      end
    end
  end
end
