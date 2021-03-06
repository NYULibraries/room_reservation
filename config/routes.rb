Rooms::Application.routes.draw do

  # API v1
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      get 'rooms' => 'rooms#index'
    end
  end

  # Admin routes
  match 'admin' => "rooms#index", via: [:get, :post]
  scope "admin" do
    get 'rooms/sort' => "rooms#index_sort", :as => "sort_rooms"
    patch 'rooms/sort' => "rooms#update_sort"
    delete 'blocks/destroy/:id' => "blocks#destroy", :as => :destroy_block
    post 'blocks/destroy_existing_reservations' => "blocks#destroy_existing_reservations", :as => 'destroy_existing_reservations'
    get 'blocks/index_existing_reservations' => "blocks#index_existing_reservations", :as => 'index_existing_reservations'

    resources :users #only: [:index, :new, :create]
    resources :rooms
    resources :blocks
    resources :room_groups
  end

  # Alias rooms#show to show_room_details
  get 'rooms/:id' => "rooms#show", :as => "show_room_details"

  # Reservation routes
  match 'reservations/resend_email' => "reservations#resend_email", via: [:get, :post]
  resources :reservations do
    match "delete" => "reservations#delete", via: [:patch, :get]
  end

  # Devise routes
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks"}
  devise_scope :user do
    get 'logout', to: 'devise/sessions#destroy', as: :logout
    get 'login', to: redirect { |params, request| "/users/auth/nyulibraries?#{request.query_string}" }, as: :login
  end

  # Default route
  root :to => "reservations#index"
end
