# frozen_string_literal: true

Rails.application.routes.draw do
  root "preview#index"
  get "_search", to: "preview#search"
  get ":name", to: "preview#index", as: :component
end
