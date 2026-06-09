# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root 'time_entries#log'
  get 'log', to: 'time_entries#log', as: :log_time

  resources :time_entries, only: [:show, :create, :edit, :update, :destroy] do
    collection { get :preview }
    member     { patch :update_inline }
  end

  get  'import',         to: 'imports#new',     as: :new_import
  post 'import/preview', to: 'imports#preview', as: :preview_import
  post 'import',         to: 'imports#create'

  get 'reports/monthly_hours', to: 'reports#monthly_hours', as: :monthly_hours_report
  get 'reports/daily_log',     to: 'reports#daily_log',     as: :daily_log_report
  get 'reports/task_totals',   to: 'reports#task_totals',   as: :task_totals_report

  get   'invoices/new',                      to: 'invoices/wizard#new',  as: :new_invoice
  get   'invoices/:invoice_id/wizard/:step', to: 'invoices/wizard#show', as: :invoice_wizard_step
  patch 'invoices/:invoice_id/wizard/:step', to: 'invoices/wizard#update'
  patch 'invoices/:invoice_id/finalize',     to: 'invoices/wizard#finalize', as: :finalize_invoice

  resources :invoices, only: [:index, :show] do
    member do
      patch :mark_sent
      patch :mark_paid
    end

    resources :lines, only: [:index, :create, :update, :destroy], controller: 'invoices/lines' do
      collection { patch :sort }
    end
  end

  resources :tasks, only: [:index, :show, :new, :create, :edit, :update] do
    collection do
      get  :search
      get  :inline_new
      post :inline_create
    end
    member do
      patch :archive
      patch :update_inline
    end
    resources :ticket_references, only: [:create, :destroy]
  end

  resources :customers, only: [:index, :show, :new, :create, :edit, :update] do
    resources :customer_rates, only: [:create, :edit, :update, :destroy]
    resources :project_codes,  only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      member { patch :archive }
      collection do
        get  :import_form
        post :import
      end
    end
  end

  get   'settings', to: 'settings#edit', as: :settings
  patch 'settings', to: 'settings#update'

  get    'login',  to: 'sessions#new', as: :login
  post   'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: :logout
end
