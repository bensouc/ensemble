# frozen_string_literal: true

# La ceinture qu'un élève prépare dans un domaine, et les compétences qui y
# mènent : ce qu'ouvre, sur le mobile, un appui sur la ceinture d'un domaine.
#
# C'est celle qui suit la dernière validée — la blanche s'il n'en a aucune. Un
# domaine spécial range toutes ses compétences au niveau 1 et décerne ses
# ceintures au nombre de compétences validées : on y montre donc toutes ses
# compétences, et ce qu'il en reste à valider pour la ceinture suivante.
#
# Valider ici, c'est ce que fait la grille de résultats de la classe : un
# `Result` direct par compétence, et la cascade de `Result` décide de la
# ceinture. Retirer suit la même règle que le « − » de la grille : seulement ce
# qui a été posé à la main (`Result#deletable?`), et jamais ce qui fait tenir
# une ceinture obtenue.
class CeintureSuivante
  attr_reader :student, :domain, :level

  delegate :special?, to: :domain

  # `level` : la ceinture que la modale montre déjà. Chaque coche s'enregistre
  # aussitôt ; la ceinture obtenue en chemin doit rester à l'écran, pas céder la
  # place à la suivante sous le doigt. Un domaine spécial, lui, recompte à
  # chaque fois : sa ceinture suivante change avec le nombre de validées.
  def initialize(student, domain, level: nil)
    @student = student
    @domain = domain
    @level = level.to_i if level.to_i.between?(1, Belt::BELT_COLORS.size) && !domain.special?
    @level ||= derniere_obtenue + 1
    @level = nil if @level > Belt::BELT_COLORS.size
  end

  # Il a déjà la noire. Un domaine spécial garde quand même sa liste : ses
  # compétences se valident au-delà de la dernière ceinture.
  def toutes_obtenues?
    level.nil?
  end

  # La ceinture montrée vient d'être obtenue, sans quitter la modale.
  def obtenue?
    return false if special? || toutes_obtenues?

    @obtenue = Belt.completed.exists?(student:, domain:, level:) if @obtenue.nil?
    @obtenue
  end

  def couleur
    Belt::BELT_COLORS[level - 1] unless toutes_obtenues?
  end

  # La suivante, une fois celle-ci obtenue ; `nil` après la noire.
  def couleur_suivante
    Belt::BELT_COLORS[level] if obtenue?
  end

  # Dans l'ordre que l'école leur a donné, celles qui restent à valider d'abord.
  def competences
    @competences ||= begin
      niveau = special? ? 1 : level
      niveau ? Skill.where(domain:, level: niveau).ordered.to_a : []
    end
  end

  def a_valider
    competences.reject { |skill| validee?(skill) }
  end

  def deja_validees
    competences.select { |skill| validee?(skill) }
  end

  def validee?(skill)
    resultats[skill.id]&.belt_validated? || false
  end

  # Validée par une évaluation : elle se corrige depuis le plan de travail, pas
  # d'ici — la même règle que la grille de la classe.
  def obtenue_a_l_evaluation?(skill)
    validee?(skill) && !resultats[skill.id].deletable?
  end

  def verrouillee?(skill)
    return false unless validee?(skill)

    obtenue_a_l_evaluation?(skill) || obtenue? || plancher_atteint?
  end

  # Ce qu'il manque encore pour la ceinture suivante d'un domaine spécial ;
  # `nil` quand le barème du domaine est inconnu ou déjà atteint.
  def encore_pour_la_ceinture
    return if !special? || toutes_obtenues?

    reste = seuil_de(level).to_i - deja_validees.size
    reste if reste.positive?
  end

  # La plus haute ceinture obtenue, celle que montre la fiche de l'élève.
  def belt
    Belt.completed.where(student:, domain:).order(level: :desc).first
  end

  # Valide la compétence, ou retire sa validation. L'état voulu, et non une
  # bascule : deux appuis rapprochés, ou une modale restée ouverte pendant
  # qu'un collègue validait, ne défont pas ce qu'ils croient faire.
  #
  # Une compétence étrangère à cette ceinture, ou verrouillée, ne bouge pas.
  # Renvoie le niveau de la ceinture obtenue en chemin, ou `nil`.
  def enregistrer!(skill_id, validee:)
    skill = competences.find { |competence| competence.id == skill_id.to_i }
    return unless a_changer?(skill, validee)

    avant = derniere_obtenue
    validee ? valider(skill) : retirer(resultats[skill.id])
    reinitialiser
    derniere_obtenue if derniere_obtenue > avant
  end

  private

  def a_changer?(skill, validee)
    skill && !verrouillee?(skill) && validee?(skill) != validee
  end

  # Un domaine spécial décerne ses ceintures au nombre de compétences validées,
  # et la cascade ne les reprend jamais (`Belt.update_special_belts_on_domain`
  # ne fait que décerner). Retirer sous le barème de la dernière obtenue
  # laissait l'élève avec une ceinture orange pour une seule compétence
  # validée : on ne retire que ce qui dépasse.
  def plancher_atteint?
    special? && deja_validees.size <= seuil_de(derniere_obtenue).to_i
  end

  # Le nombre de compétences qu'il faut pour cette ceinture d'un domaine
  # spécial ; `nil` sans barème — seuls Géométrie et Grandeurs et Mesures en
  # CE1, CE2 et CM1 en ont un.
  def seuil_de(niveau)
    return unless niveau&.positive?

    Belt::SCORES_TO_VALIDATES.dig(domain.grade_level.to_sym, domain.name.to_sym)&.at(niveau - 1)
  end

  def valider(skill)
    Result.find_or_initialize_by(student:, skill:).validate!
  end

  # 0 sans ceinture.
  def derniere_obtenue
    @derniere_obtenue ||= Belt.completed.where(student:, domain:).maximum(:level).to_i
  end

  def resultats
    @resultats ||= Result.where(student:, skill: competences).index_by(&:skill_id)
  end

  # Après l'écriture, la modale se redessine sur l'état de la base. Un domaine
  # spécial recalcule aussi sa ceinture suivante.
  def reinitialiser
    @resultats = nil
    @obtenue = nil
    @derniere_obtenue = nil
    return unless special?

    @level = derniere_obtenue + 1
    @level = nil if @level > Belt::BELT_COLORS.size
  end

  # Le recalcul est explicite, comme dans `ResultsController#destroy` : `Result`
  # ne prévient ses ceintures qu'à la création et à la mise à jour.
  def retirer(result)
    result.destroy!
    result.belt_update_by_domain_and_level
  end
end
