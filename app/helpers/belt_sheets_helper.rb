# frozen_string_literal: true

module BeltSheetsHelper
  # L'étiquette « Fiche de ceinture » / « Plan de travail » au-dessus d'un
  # éditeur : les deux se ressemblent trait pour trait. Seulement quand la
  # classe de l'élève a ouvert les fiches de ceinture — sans elles, il n'y a
  # rien à distinguer —, ou l'une de ses classes, sans élève.
  def etiqueter_le_document?(student)
    student ? student.classroom.belt_sheets? : fiches_de_ceinture_ouvertes?
  end

  # Sous le nom de la fiche : ce que le nom ne dit plus — le niveau d'une fiche
  # non assignée, le prénom de l'élève quand on l'a renommée —, et sa date.
  def sous_titre_fiche(fiche)
    contexte = if fiche.non_assignee? then [fiche.grade.name, "non assignée"]
               elsif fiche.name.present? then [fiche.student.first_name]
               end
    [*contexte, "préparée le #{l(fiche.created_at.to_date, format: :long)}"].join(" · ").upcase_first
  end

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
