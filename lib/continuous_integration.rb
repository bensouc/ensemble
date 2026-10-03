# frozen_string_literal: true

# Copie de ActiveSupport::ContinuousIntegration (Rails 8.1.4, licence MIT), qui
# n'existe pas en Rails 7.1. Même DSL que le `config/ci.rb` généré par Rails
# 8.1 : à la montée, bin/ci requerra la classe de Rails et ce fichier partira.
#
# Seule différence : `report` inversait les arguments de `colorize` sur Ctrl-C.
#
# Outil en ligne de commande, hors de l'app : écrire sur la sortie standard et
# sortir en erreur, c'est son travail.
# rubocop:disable Rails/Exit, Rails/Output
class ContinuousIntegration
  COLORS = {
    banner: "\033[1;32m",   # Vert
    title: "\033[1;35m",    # Violet
    subtitle: "\033[1;90m", # Gris
    error: "\033[1;31m",    # Rouge
    success: "\033[1;32m"   # Vert
  }.freeze

  attr_reader :results

  # Exécute chaque étape, affiche résultat et durée, et sort en erreur si l'une
  # a échoué.
  def self.run(title = "Continuous Integration", subtitle = "Running tests, style checks, and security audits", &)
    new.tap do |ci|
      ENV["CI"] = "true"
      ci.heading title, subtitle, padding: false
      ci.report(title, &)
      abort unless ci.success?
    end
  end

  def initialize
    @results = []
  end

  # La commande est une chaîne passée au shell, ou plusieurs chaînes passées
  # telles quelles à `system`.
  def step(title, *command)
    heading title, command.join(" "), type: :title
    report(title) { results << system(*command) }
  end

  def success?
    results.all?
  end

  def failure(title, subtitle = nil)
    heading title, subtitle, type: :error
  end

  def heading(heading, subtitle = nil, type: :banner, padding: true)
    echo "#{"\n\n" if padding}#{heading}", type: type
    echo "#{subtitle}#{"\n" if padding}", type: :subtitle if subtitle
  end

  def echo(text, type:)
    puts colorize(text, type)
  end

  def report(title, &block)
    Signal.trap("INT") { abort colorize("\n❌ #{title} interrupted", :error) }

    ci = self.class.new
    elapsed = timing { ci.instance_eval(&block) }

    if ci.success?
      echo "\n✅ #{title} passed in #{elapsed}", type: :success
    else
      echo "\n❌ #{title} failed in #{elapsed}", type: :error
    end

    results.concat ci.results
  ensure
    Signal.trap("INT", "-")
  end

  private

  def timing
    started_at = Time.now.to_f
    yield
    min, sec = (Time.now.to_f - started_at).divmod(60)
    "#{"#{min}m" if min.positive?}#{format('%.2fs', sec)}"
  end

  def colorize(text, type)
    "#{COLORS.fetch(type)}#{text}\033[0m"
  end
end
# rubocop:enable Rails/Exit, Rails/Output
