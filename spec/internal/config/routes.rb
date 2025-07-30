Rails.application.routes.draw do
  mount Mobbie::Rails::Engine => "/api"
end