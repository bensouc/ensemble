# frozen_string_literal: true

module BeltSheetsHelper
  # Les compétences du bloc qu'on peut encore y ajouter : celles de sa ceinture
  # qui n'y sont pas, à travailler d'abord, déjà validées ensuite — comme dans
  # l'éditeur de plan de travail.
  def options_competences_fiche(bloc)
    skills = competences_ajoutables(bloc)
    return nil if skills.empty?

    deja_validees, a_travailler = skills.partition { |skill| bloc.belt_sheet.competence_validee?(skill) }
    return options_for_select(options_de(a_travailler)) if deja_validees.empty?

    grouped_options_for_select("À travailler" => options_de(a_travailler),
                               "Déjà validées en ceinture" => options_de(deja_validees, prefixe: "✓ "))
  end

  private

  def competences_ajoutables(bloc)
    Skill.where(domain_id: bloc.domain_id, level: bloc.level).
      where.not(id: bloc.belt_sheet_skills.map(&:skill_id)).ordered.to_a
  end

  def options_de(skills, prefixe: "")
    skills.map { |skill| ["#{prefixe}#{skill.name}", skill.id] }
  end
end
