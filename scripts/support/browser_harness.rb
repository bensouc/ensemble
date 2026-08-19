# frozen_string_literal: true

# Socle commun aux bancs d'essai navigateur de scripts/.
#
# Ces bancs existent parce que l'essentiel des bugs de l'éditeur de tableaux
# vient de son interaction avec Trix — sanitisation du balisage, re-rendu de la
# pièce jointe, gestion du focus — et qu'aucun ne se voit dans une spec Ruby.
# Ils chargent le vrai bundle et le vrai Trix dans un Chrome piloté par Ferrum,
# sur une page autonome : ni serveur, ni authentification, ni base au moment du
# test.
module BrowserHarness
  class Runner
    attr_reader :dir

    def initialize(name)
      @dir = Rails.root.join("tmp", name)
      @failures = []
      FileUtils.mkdir_p(@dir)
    end

    # Chrome lancé en local : un Chrome distant (CHROME_URL) ne verrait pas le
    # système de fichiers de Rails et ne pourrait pas ouvrir nos pages file://.
    # On passe par PdfGenerator pour hériter de la détection du binaire, des
    # flags conteneur et du retry sur démarrage lent.
    def with_browser(**options)
      browser = PdfGenerator.local_browser(**options)
      yield browser
    ensure
      browser&.quit
    end

    # Un tableau de test qui ne survit pas au banc.
    def sample_table(**attributes)
      result = nil
      ActiveRecord::Base.transaction do
        result = yield Table.create!(**attributes)
        raise ActiveRecord::Rollback
      end
      result
    end

    def dump_stylesheet(name)
      write("#{name}.css", Rails.application.assets["#{name}.css"].to_s)
    end

    # Le bundle en IIFE : une page file:// ne peut pas charger de module ES.
    def dump_bundle(filename = "application.js")
      builder = write("build.js", <<~JS)
        const esbuild = require(#{Rails.root.join("node_modules/esbuild").to_s.inspect})
        const rails = require(#{Rails.root.join("node_modules/esbuild-rails").to_s.inspect})
        esbuild.build({
          entryPoints: [#{Rails.root.join("app/javascript/application.js").to_s.inspect}],
          bundle: true, format: 'iife', outfile: #{@dir.join(filename).to_s.inspect},
          absWorkingDir: #{Rails.root.to_s.inspect}, plugins: [rails()], logLevel: 'error',
        }).catch(e => { console.error(e); process.exit(1) })
      JS
      raise "échec de la compilation du bundle" unless system("node", builder.to_s)
    end

    def page(name, head:, body:)
      write("#{name}.html", <<~HTML)
        <!doctype html><html lang="fr"><head><meta charset="utf-8">#{head}</head>
        <body>#{body}</body></html>
      HTML
    end

    def url(name) = "file://#{@dir.join("#{name}.html")}"

    def check(label, condition)
      puts format("  %-52s %s", label, condition ? "OK" : "ÉCHEC")
      @failures << label unless condition
      condition
    end

    def report!
      puts "\n#{@failures.empty? ? 'Tout est vert.' : "#{@failures.size} échec(s) : #{@failures.join(', ')}"}"
      exit(@failures.empty? ? 0 : 1)
    end

    private

    def write(filename, contents)
      path = @dir.join(filename)
      File.write(path, contents)
      path
    end
  end
end
