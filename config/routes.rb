Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  devise_for :users,
    controllers: { registrations: "registrations" }
  root to: "pages#home"
  get "/dashboard", to: "dashboard#show"

  # ############### MOBILE ROUTES###############
  namespace "mobile" do
    resources :work_plans, only: [:index]
    resources :students, only: [:index]
    get "work_plans/:id/evaluation", to: "work_plans#evaluation", as: :evaluation
  end
  # ############### CONTACTROUTES ###############
  post "", to: "contact#create", as: :contact_create

  # ############### WORK_PLAN ROUTES###############
  resources :work_plans, only: [:index, :show, :update, :new, :create, :destroy] do
    resources :work_plan_domains, only: [:new, :create]
    post "", to: "work_plans#clone", as: :clone
  end
  get "work_plans/:id/evaluation", to: "work_plans#evaluation", as: :evaluation
  # post "work_plans/:id", to: "work_plans#share", as: :share

  resources :work_plan_domains, only: [:destroy, :show] do
    resources :work_plan_skills, only: [:create]
  end

  # ############### routes for WORK_PLAN_SKILLS###############
  resources :work_plan_skills, only: [:update, :destroy, :show] do
    resources :challenges, only: [:create, :update]
    post "/challenges/:id", to: "challenges#clone", as: :clone
    get "remove_special_wps", to: "work_plan_skills#remove_special_wps", as: :remove_special_wps
    patch "eval_update", to: "work_plan_skills#eval_update", as: :eval_update
    # completed / failed / redo
    patch "change_challenge", to: "work_plan_skills#change_challenge", as: :change_challenge
    post "challenges/:id/display_challenges", to: "challenges#display_challenges", as: :display_challenges
  end

  # ###############routes for CLASSROOMS###############
  resources :classrooms, only: [:index, :show, :update, :new, :create, :destroy] do
    resources :students, only: [:new, :edit] # :create, :destroy
    resources :shared_classrooms, only: [:create, :destroy]
  end
  get "classrooms/:id/results_by_domain", to: "classrooms#results_by_domain", as: :results_by_domain
  get "classrooms/:id/results", to: "classrooms#results", as: :classroom_results

  # ###############routes for STUDENTS###############
  resources :students, only: [:create, :update, :show, :destroy] do
    resources :belts, only: [:create]
    post "", to: "work_plans#auto_new_wp", as: :auto_new_wp
    get "new_validated_wps", to: "students#new_validated_wps", as: :new_validated_wps
    post "new_validated_wps", to: "work_plan_skills#add_validated_wps", as: :add_validated_wps
    get "add_completed_wps", to: "students#add_completed_wps", as: :add_completed_wps
  end

  # ###############routes for BELTS###############
  resources :belts, only: [:destroy, :edit, :update]

  # ###############route for tab editing###############
  resources :tables, only: [:show, :create, :update]

  # ###############stripe routes###############
  mount StripeEvent::Engine, at: "/stripe-webhooks"
  post "create-customer-portal-session", to: "stripe#create_portal_session"

  # Routes for subscription
  resources :subscriptions, only: [:create, :new]
  get "subscriptions/success", to: "subscriptions#success"
  get "subscriptions/cancel", to: "subscriptions#cancel"

  # ###############END OF STRIPE ROUTES############

  # ###############routes for SKILLS###############
  resources :skills

  # ###############routesfor Challenge#########
  resources :challenges, only: [:show, :edit, :update, :destroy, :index, :new, :create]

  # ###############routes for SCHOOL/SCHOOL_ROLES###############
  resources :schools, only: %w[show]

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
