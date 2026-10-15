# frozen_string_literal: true

# Minimal Rails app that shows every shopify-ui component on one page.
# No database, no models, never deployed.
require "bundler/setup"
require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "view_component"
require_relative "../lib/shopify_ui_setup"

module ShopifyUIPreview
  class Application < Rails::Application
    config.load_defaults 7.2
    config.root = __dir__
    config.paths["public"] = "build"
    config.paths["config/routes.rb"] = "routes.rb"
    config.eager_load = false
    config.enable_reloading = true
    config.consider_all_requests_local = true
    config.secret_key_base = "shopify-ui-preview-only"
    config.hosts.clear
    config.public_file_server.enabled = true
    config.logger = ActiveSupport::Logger.new($stdout)
    config.log_level = :info

    ShopifyUISetup.configure(config)
  end
end

Rails.application.initialize!

# Each partial in preview/components/ is one section on the page, e.g. _button.html.erb.
class PreviewController < ActionController::Base
  prepend_view_path __dir__

  def self.local_prefixes = []

  def index
    @all_sections = Dir[File.join(__dir__, "components/_*.html.erb")]
                      .map { |path| File.basename(path, ".html.erb").delete_prefix("_") }
                      .sort
    @sections = params[:name] ? @all_sections & [ params[:name] ] : @all_sections
    raise ActionController::RoutingError, "No component #{params[:name]}" if @sections.empty?

    render template: "index", layout: false
  end

  # Fake remote search for the Combobox preview.
  PRODUCTS = [
    "Gift Card", "The Minimal Snowboard", "The Collection Snowboard: Hydrogen", "The Archived Snowboard",
    "Selling Plans Ski Wax", "The Complete Snowboard", "The Out of Stock Snowboard", "The Compare at Price Snowboard",
    "The Videographer Snowboard", "The Draft Snowboard", "The Inventory Not Tracked Snowboard"
  ].freeze

  def search
    q = params[:q].to_s.downcase
    hits = PRODUCTS.each_with_index.select { |name, _| name.downcase.include?(q) }.first(8)
    render json: hits.map { |name, i| { label: name, value: "gid://shopify/Product/#{1000 + i}", description: "#{(i * 7) % 40} in stock" } }
  end
end

run Rails.application
