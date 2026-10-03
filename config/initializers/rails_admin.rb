RailsAdmin.config do |config|
  config.asset_source = :sprockets

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)
  config.authorize_with do
    unless current_user.admin?
      flash[:alert] = t("unauthorized")
      redirect_to main_app.root_path
    end
  end
  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  config.model "User" do
    list do
      field :id
      field :email
      field :admin
      field :first_name
      field :last_name
      field :school
      field :last_seen
    end
  end
end

# rails_admin liste les exercices avec leur contenu ActionText. ActionText y rend
# la partial d'un tableau dans le contexte du contrôleur de rails_admin, qui
# n'a pas les helpers de l'application : sans celui-ci, `table_cell_classes`
# manquait et la liste tombait en 500 dès qu'un exercice contenait un tableau.
Rails.application.config.to_prepare do
  RailsAdmin::ApplicationController.helper TablesHelper
end
