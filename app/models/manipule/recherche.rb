# frozen_string_literal: true

module Manipule
  # Choisir une compétence parmi celles de l'école. Une école en porte plus de
  # mille — 1 093 sur le compte de démo — donc on ne les déroule jamais toutes.
  #
  # Trois crans, les mêmes que « Mes progressions de compétences » : le niveau,
  # le domaine, la ceinture. Tant qu'aucun n'est posé, on s'en tient aux
  # compétences où l'enseignante a déjà écrit : c'est son travail, et la liste
  # tient en un écran.
  #
  # Dès qu'un cran est posé, on montre tout le périmètre demandé, compétences
  # vides comprises. C'était le chemin manquant : une compétence sans problème
  # n'apparaissait nulle part, donc on ne pouvait jamais y écrire le premier.
  class Recherche
    # Un seul niveau peut porter cinq cents compétences. Au-delà d'une
    # soixantaine de cartes, personne ne parcourt plus rien : la page annonce
    # le compte entier et demande d'affiner.
    MAXIMUM = 60

    def initialize(ecole:, niveaux:, deja_ecrites:, filtres: {})
      @ecole = ecole
      @niveaux = niveaux
      @deja_ecrites = deja_ecrites
      @niveau = filtres[:niveau].presence
      @domaine = filtres[:domaine].presence
      @ceinture = filtres[:ceinture].presence
    end

    def filtree?
      [@niveau, @domaine, @ceinture].any?
    end

    # Les niveaux de ses classes, pas ceux de l'école : une enseignante de CE1
    # n'a rien à écrire pour le CM2, et l'école en porte sept.
    attr_reader :niveaux

    # Rangés sous leur niveau : chaque niveau porte les siens, et ils portent
    # les mêmes noms — à plat, la liste alignait quatre « Calcul »
    # indiscernables. L'ordre est scolaire et non alphabétique, sans quoi le CP
    # tomberait après le CM2.
    def domaines
      grouper(domaines_du_perimetre.order(:name))
    end

    def competences
      @competences ||= toutes.first(MAXIMUM)
    end

    def total
      toutes.size
    end

    def plafonnee?
      total > competences.size
    end

    private

    def toutes
      @toutes ||= filtree? ? competences_du_perimetre : @deja_ecrites.uniq.sort_by { |c| [c.level, c.name] }
    end

    def domaines_du_perimetre
      portee = Domain.preload(:grade).where(grade_id: @niveaux)
      @niveau ? portee.where(grade_id: @niveau) : portee
    end

    # Les niveaux de ses classes bornent déjà le périmètre. On y ajoute le
    # `school_id` de la compétence elle-même : il peut diverger de celui du
    # niveau de son domaine, et un filtre ne doit jamais faire passe-droit.
    def competences_du_perimetre
      portee = Skill.joins(:domain).preload(domain: :grade).
        where(school_id: @ecole&.id, domains: { grade_id: @niveaux })
      portee = portee.where(domains: { grade_id: @niveau }) if @niveau
      portee = portee.where(domain_id: @domaine) if @domaine
      portee = portee.where(level: @ceinture) if @ceinture
      portee.order(:level, :name).to_a
    end

    def grouper(domaines)
      domaines.group_by(&:grade).
        sort_by { |niveau, _| Classroom::GRADE.index(niveau&.grade_level) || Classroom::GRADE.size }.
        map { |niveau, liste| [niveau&.name.to_s, liste.map { |domaine| [domaine.name, domaine.id] }] }
    end
  end
end
