# frozen_string_literal: true

# Loads shopify-ui components into a host Rails app.
# Paths are resolved from this file, so the checkout can live anywhere
# (vendor/shopify-ui submodule, ../shopify-ui sibling, ...).
#
#   # config/application.rb
#   require_relative "../vendor/shopify-ui/lib/shopify_ui_setup"
#
#   class Application < Rails::Application
#     ShopifyUISetup.configure(config)
#   end
module ShopifyUISetup
  ROOT = File.expand_path("..", __dir__)
  COMPONENTS_PATH = File.join(ROOT, "app", "components")

  module_function

  def configure(config)
    config.autoload_paths << COMPONENTS_PATH
    config.eager_load_paths << COMPONENTS_PATH

    # app/components/shopify_ui/ => ShopifyUI (Rails' default would be ShopifyUi).
    Rails.autoloaders.each do |loader|
      loader.inflector.inflect("shopify_ui" => "ShopifyUI")
    end
  end

  def version
    File.read(File.join(ROOT, "VERSION")).strip
  end
end
