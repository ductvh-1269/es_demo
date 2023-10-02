# frozen_string_literal: true

Rails.application.routes.draw do

  resources :post

  get "/admin", to: "post#ok"
end
