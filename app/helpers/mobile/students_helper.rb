module Mobile::StudentsHelper
  # La ceinture d'un domaine sur la fiche mobile de l'élève : c'est elle que
  # remplace l'enregistrement de la modale de validation.
  def tuile_ceinture_id(student, domain)
    "mobile_ceinture_#{student.id}_#{domain.id}"
  end

  # Où en est l'élève sur la ceinture qu'il prépare. Accordé à la main :
  # `pluralize` ne fléchit pas le français (voir `eleves_label`).
  def avancement_ceinture(ceinture)
    validees = ceinture.deja_validees.size
    texte = case validees
            when 0 then "Aucune compétence validée"
            when 1 then "1 compétence validée"
            else "#{validees} compétences validées"
            end
    texte = "#{texte} sur #{ceinture.competences.size}"
    encore = ceinture.encore_pour_la_ceinture
    encore ? "#{texte} · encore #{encore} pour la ceinture #{ceinture.couleur}" : texte
  end
end
