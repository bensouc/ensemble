# frozen_string_literal: true

module ClassroomsHelper
  # Libellé d'une classe d'accueil dans la liste de transfert :
  # "CE1 Étoiles — CE1 — Sophie, Marc"
  def classroom_transfer_label(classroom)
    teachers = classroom.teachers.filter_map { |teacher| teacher.first_name.presence&.capitalize }

    [classroom.safe_name, classroom.grade.name, teachers.join(", ").presence].uniq.compact.join(" — ")
  end

  # Pourquoi la création de classe est fermée. Un message unique couvrait cinq
  # situations : « demandez au responsable de modifier les quantités » s'affichait
  # aussi bien pour un abonnement résilié que pour une école qui n'en a jamais eu.
  def classroom_creation_block_reason(user)
    return :demo if user.demo?

    school = user.school
    return :no_subscription if school.nil? || school.subscription.nil?
    return :inactive_subscription unless school.valid_subscription?

    :quota_reached
  end

  # Une école peut se retrouver sans responsable : mieux vaut une tournure vague
  # qu'une parenthèse vide.
  def super_teachers_label(school)
    school&.super_teachers_first_name.presence || "votre responsable de groupe"
  end

  # Le portail Stripe exige un client : sans lui, l'action lève une erreur au
  # lieu d'ouvrir quoi que ce soit.
  def stripe_portal_reachable?(school)
    school&.stripe_customer_id.present?
  end
end
