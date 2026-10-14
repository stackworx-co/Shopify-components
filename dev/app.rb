# frozen_string_literal: true

# Minimal Rails app that shows every shopify-ui component on one page.
# No database, no models, never deployed.
require "bundler/setup"
require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "view_component"
require_relative "../lib/shopify_ui_setup"

module ShopifyUIGallery
  class Application < Rails::Application
    config.load_defaults 7.2
    config.root = __dir__
    config.eager_load = false
    config.enable_reloading = true
    config.consider_all_requests_local = true
    config.secret_key_base = "shopify-ui-gallery-only"
    config.hosts.clear
    config.public_file_server.enabled = true
    config.logger = ActiveSupport::Logger.new($stdout)
    config.log_level = :info

    ShopifyUISetup.configure(config)
  end
end

Rails.application.initialize!

Rails.application.routes.draw do
  root "gallery#index"
end
