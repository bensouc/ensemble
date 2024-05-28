# rubocop:disable all
Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  devise_for :users,
    controllers: { registrations: "registrations" }
  devise_scope :user do
    post "create_demo_user", to: "registrations#add_demo_user"
  end
  root to: "pages#home"
  get "/dashboard", to: "dashboard#show"
  post "add_discovery", to: "dashboard#add_discovery_method"
  get "mentions_legales", to: "pages#mentions_legales"
  # ############### MOBILE ROUTES###############
  namespace "mobile" do
    resources :work_plans, only: [:index]
    resources :students, only: [:results]
    resources :classrooms, only: [:index, :show] do
      resources :students, only: [:show, :index]
    end
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
    get "domains/:id/modal", to: "modals#display_skills_modal", as: :display_skills_modal
    resources :belts, only: [:create]
    post "", to: "work_plans#auto_new_wp", as: :auto_new_wp
    get "domains/:id/:level", to: "belts#show", as: :show
    get "new_validated_wps", to: "students#new_validated_wps", as: :new_validated_wps
    post "new_validated_wps", to: "work_plan_skills#add_validated_wps", as: :add_validated_wps
    get "add_completed_wps", to: "students#add_completed_wps", as: :add_completed_wps
  end

  # ###############routes for BELTS###############
  resources :belts, only: [:destroy, :edit, :update]

  # ###############route for tab editing###############
  resources :tables, only: [:show, :create, :update]

  # ###############stripe routes###############
  # namespace :stripe do
  #   mount StripeEvent::Engine, at: "/stripe-webhooks"
  # end
  get "create-customer-portal-session", to: "stripe/stripe#create_portal_session"
  # get "/session-status", to: "stripe/checkouts#session_status"
  post "stripe-webhooks", to: "stripe/stripe_webhooks#create"
  # get "subscription-checkout", to: "stripe/checkouts#subscription_checkout"
  # ###############END OF STRIPE ROUTES ############

  # ############### Subscriptions ###############
  get "subscriptions/on_boarding", to: "subscriptions#on_boarding"
  resources :subscriptions, only: [:create, :new]
  get "subscriptions/success", to: "subscriptions#success"
  get "subscriptions/cancel", to: "subscriptions#cancel"
  get "subscriptions/school_pricing", to: "subscriptions#school_pricing"
  # ###############END OF Subscriptions ROUTES############

  # ###############routes for SKILLS###############
  get "skills/add_skills_from_xls", to: "skills#add_skills_from_xls", as: :add_skills_from_xls
  resources :skills
    # EXCEL UPLAD SKILLS
  # get "excel/upload", to: "excel#upload", as: "upload_excel"
  post "skills/upload", to: "skills#upload_skills_xlsx", as: :upload_skills
  # ###############END for SKILLS###############


  # ###############routesfor Challenge#########
  resources :challenges, only: [:show, :edit, :update, :destroy, :index, :new, :create]

  # ###############routes for SCHOOL/SCHOOL_ROLES###############
  get 'schools/join', to: "schools#join", as: :join_school
  post 'schools/create_sub_with_code', to: "school_roles#create"
  resources :schools, only: %w[show new create]

  # ###############    routes for GRADES /DOMAINS        ###############
  resources :grades, only: [:show, :destroy, :index, :new, :create] do
    resources :domains, only: [:new,:index]
  end
  # ###############    routes for DOMAINS         ###############
  resources :domains, only: [:show,:edit,:update,:create,:destroy] do
    member do
      patch :move
    end
  end
  # ###############ROUTES FOR MODALS###############
  get "students/:id/auto_gen", to: "modals#auto_gen", as: :student_auto_gen_modal

  # ###############END for SKILLS###############

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
