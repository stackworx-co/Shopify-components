# Adding shopify-ui to a Rails app

Requirements: Rails 7+, Node 22+, Yarn or npm. Paths below assume the submodule lives at
`vendor/shopify-ui`; adjust them if you use another location.

## 1. Add the submodule

```bash
git submodule add <shopify-ui-repo-url> vendor/shopify-ui
```

Cloning an app that already uses it:

```bash
git clone --recurse-submodules <app-repo-url>
# or, in an existing clone
git submodule update --init
```

## 2. Ruby: ViewComponent + autoloading

`Gemfile`:

```ruby
gem "view_component", "~> 3.27"
```

`config/application.rb` (top of the file, after `Bundler.require`):

```ruby
require_relative "../vendor/shopify-ui/lib/shopify_ui_setup"
```

Inside `class Application < Rails::Application`:

```ruby
ShopifyUISetup.configure(config)
```

This adds `vendor/shopify-ui/app/components` to autoloading and maps the
`shopify_ui` folder to the `ShopifyUI` namespace, so views can call
`render ShopifyUI::ButtonComponent.new(...)`.

## 3. Tailwind

```bash
yarn add -D tailwindcss@4.3.3 @tailwindcss/cli@4.3.3
```

`package.json` scripts:

```json
"build:tailwind": "tailwindcss -i ./app/assets/stylesheets/tailwind.css -o ./app/assets/builds/tailwind.css --minify"
```

Also run it in production builds, e.g. add `&& yarn build:tailwind` to `heroku-postbuild`
(or `build`).

`app/assets/stylesheets/tailwind.css` (the app's entry file):

```css
/* tw: prefix + no Preflight + !important so it can sit next to Bootstrap or other CSS. */
@layer theme, base, components, utilities;
@import "tailwindcss/theme.css" layer(theme) prefix(tw);
@import "tailwindcss/utilities.css" layer(utilities) important;

@import "../../../vendor/shopify-ui/app/assets/stylesheets/shopify_ui/theme.css";

/* The app's own files that use tw: classes */
@source "../../views";
@source "../../components";
@source "../../helpers";
@source "../../javascript";
```

`theme.css` brings in the design tokens and tells Tailwind to scan shopify-ui's own components,
so their classes are generated in the app's build.

`Procfile.dev`:

```
tailwind: yarn build:tailwind --watch=always
```

Sprockets apps: `app/assets/builds` must be linked in `app/assets/config/manifest.js`
(`//= link_tree ../builds`), which is the default with cssbundling-rails.

## 4. Layout

In each layout that renders shopify-ui components, inside `<head>`:

```erb
<meta name="color-scheme" content="light">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@450;550;650;700&display=swap">
<%= stylesheet_link_tag "tailwind", media: "all", "data-turbo-track": "reload" %>
```

Place the Tailwind stylesheet after the app's other stylesheets.

## 5. Node version (recommended)

`.nvmrc` in the app root:

```
22.11.0
```

## 6. Check it works

```bash
bin/rails runner 'puts ShopifyUISetup.version'
yarn build:tailwind
```

The first prints the shopify-ui version; the second should finish without errors and
`app/assets/builds/tailwind.css` should contain the `--sui-*` tokens.

## Updating shopify-ui in an app

```bash
cd vendor/shopify-ui
git fetch --tags
git checkout v1.1.0        # or a commit SHA
cd ../..
git add vendor/shopify-ui
git commit -m "Bump shopify-ui to v1.1.0"
```

Each app pins its own commit, so apps upgrade independently. Production deploys exactly
the commit recorded in the app repo.
