# config/routes.rb
Rails.application.routes.draw do
  # App root (Autodialer dashboard)
  root "calls#index"

  # Calls / Autodialer routes
  resources :calls, only: [:index, :create] do
    collection do
      post :upload
      post :start_batch
      post :ai_prompt
    end
  end

  # Twilio webhook endpoints (explicit routes to controller actions)
  # These map to TwilioController#voice and TwilioController#status
  post "/twilio/voice",  to: "twilio#voice"
  post "/twilio/status", to: "twilio#status"

  # Blog routes (AI-generated articles)
  resources :blog_posts, path: "/blog", only: [:index, :show]
  get  "/blog/generate_ui", to: "blog_posts#generate_ui"
  post "/blog/generate",    to: "blog_posts#generate"

  # Sidekiq web UI (development only)
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
