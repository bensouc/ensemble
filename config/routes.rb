Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users
  root to: 'pages#home'
  get '/dashboard', to: "dashboard#show"

  resources :work_plans, only: [:index, :show, :update, :new, :create, :destroy] do
    resources :work_plan_domains, only: [:new, :create]

    post '', to: 'work_plans#clone', as: :clone
  end

  get "work_plans/:id/eval", to: "work_plans#eval", as: :eval

  resources :work_plan_domains, only: [:destroy] do
    resources :work_plan_skills, only: [:create]
  end

  resources :work_plan_skills, only: [:update, :destroy] do
    resources :challenges, only: [:create, :update]
    post '/challenges/:id', to: 'challenges#clone', as: :clone

    # completed / failed / redo
    post '', to: 'work_plan_skills#update_eval', as: :update_eval

  end

  # route for tab editing
  resources :tables, only: [:show, :create, :update]

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
