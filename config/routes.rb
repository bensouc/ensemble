Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  get '/dashboard', to: "dashboard#show"

  resources :work_plans, only: [:index, :show, :update, :new, :create, :destroy] do
    resources :work_plan_domains, only: [:new, :create]
    post '', to: 'work_plans#clone', as: :clone
    # patch '', to: 'work_plans#edit', as: :edit
  end

  resources :work_plan_domains, only: [:destroy] do
    resources :work_plan_skills, only: [:create]
  end

  resources :work_plan_skills, only: [:update, :destroy] do
    resources :challenges, only: [:create, :update]
    post '/challenges/:id', to: 'challenges#clone', as: :clone
  end

  # route for tab editing
  resources :tables, only: [:show, :create, :update]

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
