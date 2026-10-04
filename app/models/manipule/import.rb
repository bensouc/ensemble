# frozen_string_literal: true

require "csv"

module Manipule
  # Lit un tableur et en fait des problèmes.
  #
  # Tout ou rien : une seule ligne fautive annule l'import entier. Importer la
  # moitié d'un fichier laisserait l'enseignante deviner ce qui est passé, et
  # réimporter créerait des doublons.
  #
  # Les problèmes arrivent en brouillon. Elle les relit, puis les met en
  # circulation — c'est sa Q36, voir ce que l'élève verra avant qu'il le voie.
  class Import
    EN_TETES = {
      enonce: /enonce/,
      question: /question/,
      bonne: /bonne/,
      fausse1: /(mauvaise|fausse).*1/,
      fausse2: /(mauvaise|fausse).*2/
    }.freeze

    EXTENSIONS = %w[.csv .xlsx].freeze

    attr_reader :erreurs, :problemes

    def initialize(skill:, user:, fichier:)
      @skill = skill
      @user = user
      @fichier = fichier
      @erreurs = []
      @problemes = []
    end

    def executer!
      lignes = lire
      return self if erreurs.any?

      colonnes = reperer(lignes.first)
      return self if erreurs.any?

      batir(lignes.drop(1), colonnes)
      enregistrer if erreurs.empty?
      self
    end

    def reussi?
      erreurs.empty? && problemes.any?
    end

    private

    def lire
      extension = File.extname(@fichier.original_filename.to_s).downcase
      return erreur("Format non reconnu (#{extension}). Attendu : un fichier .csv ou .xlsx.") unless
        EXTENSIONS.include?(extension)

      lignes = ouvrir(@fichier.tempfile.path, extension)
      return erreur("Le fichier est vide.") if lignes.length < 2

      lignes
    rescue StandardError => e
      erreur("Le fichier n'a pas pu être lu : #{e.message}")
    end

    # Ni roo ni rien de neuf : la bibliothèque standard pour le CSV, et le
    # lecteur de classeurs dont l'application se sert déjà pour importer les
    # compétences. Une dépendance de moins à auditer.
    def ouvrir(chemin, extension)
      return Array(SimpleXlsxReader.open(chemin).sheets.first&.rows).map(&:to_a) if extension == ".xlsx"

      CSV.read(chemin, col_sep: separateur(chemin), encoding: "bom|utf-8")
    end

    # Un tableur français exporte en CSV avec des points-virgules. Deviner
    # plutôt qu'imposer : personne ne va expliquer ça à une enseignante.
    def separateur(chemin)
      premiere = File.open(chemin, "r:bom|utf-8", &:readline).to_s
      premiere.count(";") > premiere.count(",") ? ";" : ","
    rescue StandardError
      ","
    end

    def reperer(en_tete)
      colonnes = colonnes_de(en_tete)
      manquantes = colonnes.select { |_clef, rang| rang.nil? }.keys
      return colonnes if manquantes.empty?

      erreur("Colonnes manquantes : #{manquantes.join(', ')}. Attendu : " \
             "Énoncé, Question, Bonne réponse, Mauvaise réponse 1, Mauvaise réponse 2.")
    end

    # Les titres sont rapprochés sans accents ni casse : « Enonce » vaut
    # « Énoncé », et l'ordre des colonnes n'a aucune importance.
    def colonnes_de(en_tete)
      cellules = Array(en_tete).map { |cellule| I18n.transliterate(cellule.to_s).downcase.strip }
      EN_TETES.transform_values { |motif| cellules.index { |cellule| cellule.match?(motif) } }
    end

    def batir(lignes, colonnes)
      lignes.each_with_index do |ligne, index|
        valeurs = colonnes.transform_values { |rang| ligne[rang].to_s.strip }
        next if valeurs.values.all?(&:blank?) # une ligne vide en fin de fichier

        probleme = problem_pour(valeurs)
        @problemes << probleme
        next if probleme.valid?

        @erreurs << "Ligne #{index + 2} : #{probleme.errors.full_messages.to_sentence}"
      end
    end

    def problem_pour(valeurs)
      probleme = Problem.new(skill: @skill, user: @user, published: false,
                             statement: valeurs[:enonce], question: valeurs[:question])
      probleme.choices.build(label: valeurs[:bonne], correct: true, position: 1)
      probleme.choices.build(label: valeurs[:fausse1], correct: false, position: 2)
      probleme.choices.build(label: valeurs[:fausse2], correct: false, position: 3)
      probleme
    end

    def enregistrer
      Problem.transaction { @problemes.each(&:save!) }
    end

    def erreur(message)
      @erreurs << message
      []
    end
  end
end
