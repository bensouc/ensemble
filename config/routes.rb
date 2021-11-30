Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  get '/dashboard', to: "dashboard#show"

  resources :work_plans, only: [:index, :show, :update, :new, :create] do
    resources :work_plan_domains, only: [:new, :create]
  end

  resources :work_plan_domains, only: [] do
    resources :work_plan_skills, only: [:create]
  end

  resources :work_plan_skills, only: [:update] do
    resources :challenges, only: [:create]
  end

  resources :challenges, only: [:update]

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
