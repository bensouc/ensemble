class SubscriptionsController < ApplicationController
  MESSAGE_SANS_ABONNEMENT = "Souscrivez un abonnement avant de demander à le modifier.".freeze
  MESSAGE_DEMANDE_ENVOYEE = "Votre demande nous est parvenue. Nous ajustons votre abonnement, " \
                            "et la facture correspondante vous sera envoyée.".freeze

  def school_pricing
    @customer = StripeHelper.get_or_create_customer(current_user.school)
    authorize Subscription
  end

  def on_boarding
    redirect_to dashboard_path, notice: "Vous avez déjà un abonnement" if current_user.school.valid_subscription?

    authorize Subscription
    @sequence = 1
  end

  def new
    redirect_to dashboard_path, notice: "Vous avez déjà un abonnement" if current_user.school.valid_subscription?
    @sequence = 3
    @school = current_user.school
    @subscription = Subscription.new
    authorize @subscription
    # @customer = StripeHelper.get_or_create_customer(current_user)
  end

  def create
    @subcription = Subscription.new(subscription_params)
    @subcription.school = current_user.school
    authorize @subcription
    # @subcription.save
    # @subcription.update(params.require(:costs).permit(:trial_end, :current_period_start, :current_period_end))
    @customer = StripeHelper.get_or_create_customer(current_user.school)
    @session = Stripe::CheckoutsHelper.create_subscription_checkout(@customer, @subcription)
    redirect_to @session.url, allow_other_host: true
  end

  # Le portail client de Stripe ne sait pas modifier un abonnement sur facture :
  # le responsable ne peut qu'y résilier. Sa demande passe donc par nous, qui la
  # portons dans le Dashboard — Stripe émet ensuite la facture correspondante.
  def change_request
    authorize Subscription
    charger_abonnement
    return redirect_to new_subscription_path, alert: MESSAGE_SANS_ABONNEMENT if @subscription.nil?

    @classes_souhaitees = @subscription.quantity.to_i
  end

  def create_change_request
    authorize Subscription
    charger_abonnement
    return redirect_to new_subscription_path, alert: MESSAGE_SANS_ABONNEMENT if @subscription.nil?

    @classes_souhaitees = change_request_params[:classes].to_i
    return refuser_la_demande unless @classes_souhaitees.positive?

    transmettre_la_demande
    redirect_to school_path(@school), notice: MESSAGE_DEMANDE_ENVOYEE
  end

  def cancel
  end

  def success
    authorize Subscription
    @sequence = 4
    #     Stripe.api_key = ENV["STRIPE_API_KEY"]
    # @subscription = Stripe::Subscription.retrieve( current_user.subscription.external_id)
  end

  def subscription_params
    params.require(:subscription).permit(:rythm, :quantity, :trial_end, :current_period_start, :current_period_end)
  end

  private

  def charger_abonnement
    @school = current_user.school
    @subscription = @school.subscription
  end

  def change_request_params
    params.require(:subscription_change).permit(:classes, :message)
  end

  # La notification interne d'abord : c'est elle qui déclenche le travail. Un
  # accusé parti sans que la demande nous soit arrivée promettrait dans le vide.
  def transmettre_la_demande
    demande_courante = demande
    ContactMailer.subscription_change_request(demande_courante).deliver_now
    accuser_reception(demande_courante)
  end

  # `flash.now` et non `flash` : on réaffiche le formulaire, on ne redirige pas —
  # la saisie du responsable doit lui revenir plutôt que d'être perdue.
  def refuser_la_demande
    flash.now[:alert] = "Indiquez un nombre de classes d'au moins 1."
    render :change_request, status: :unprocessable_content
  end

  # Tout ce qu'il faut pour agir dans le Dashboard sans rien avoir à chercher :
  # les deux identifiants Stripe, l'avant et l'après, et le nombre de classes
  # réellement créées — qui n'est pas forcément celui payé.
  def demande
    { school: @school,
      demandeur: current_user,
      classes_creees: @school.classrooms_total,
      quantite_avant: @subscription.quantity.to_i,
      quantite_apres: @classes_souhaitees,
      rythm: @subscription.rythm,
      # L'adresse du client Stripe, donc celle où partira la facture. L'accusé la
      # nomme pour que l'école puisse la corriger avant l'émission.
      facturation_email: @school.email,
      stripe_customer_id: @school.stripe_customer_id,
      stripe_subscription_id: @subscription.stripe_subscription_id,
      message: change_request_params[:message] }
  end

  # Sans destinataire, `mail` lève : une école ancienne peut n'avoir aucun email,
  # et ce serait une 500 sur une demande par ailleurs bien reçue.
  def accuser_reception(demande_courante)
    return if [demande_courante[:demandeur].email, demande_courante[:facturation_email]].compact_blank.empty?

    ContactMailer.subscription_change_confirmation(demande_courante).deliver_now
  end
end
