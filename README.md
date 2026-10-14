# shopify-ui

Shared Shopify-admin-style UI for our Rails applications: ViewComponents, CSS and vanilla JavaScript.

This repository is **not** a Ruby gem, npm package, Rails app or deployable service. Rails apps include it as a Git submodule (e.g. `vendor/shopify-ui`), pinned to a specific commit or tag, and it is deployed as part of each app.

## Structure

```
shopify-ui/
├── app/
│   ├── components/shopify_ui/      ViewComponents (ShopifyUI::*Component: .rb + .html.erb)
│   ├── views/shopify_ui/           shared partials, if needed
│   └── assets/stylesheets/shopify_ui/
│       ├── tokens.css              design tokens (--sui-* CSS variables)
│       └── theme.css               Tailwind theme, imported by the app's Tailwind entry
├── lib/shopify_ui_setup.rb         one-line Rails setup (autoload + ShopifyUI namespace)
├── javascript/                     shared vanilla JS
├── docs/setup.md                   how to add shopify-ui to a Rails app
├── examples/                       example ERB usage
├── test/                           component tests
├── VERSION
└── README.md
```

## Component gallery (local)

One page that shows every component and its variants:

```bash
cd ~/projects/shopify-ui
bundle install   # first time only (Ruby 3.3.8, see .ruby-version)
bin/dev          # http://localhost:4000
```

`bin/dev` builds the CSS with Tailwind (the `tailwindcss-ruby` gem, so no Node is needed) and
starts the gallery. Refresh the page after changes.

To add a component to the gallery, create `dev/app/views/components/_<name>.html.erb` with its
variants; it appears on the page automatically.

The `Gemfile` and `dev/` are for the gallery only. Rails apps using shopify-ui never load them,
and nothing here is deployed.

## Usage in a Rails app

```bash
git submodule add <shopify-ui-repo-url> vendor/shopify-ui
```

Each app pins its own version, so apps can upgrade independently. Full steps (Ruby, Tailwind, layout): [docs/setup.md](docs/setup.md).

Components use Tailwind classes with the `tw:` prefix and the token names from `theme.css`
(e.g. `tw:bg-accent`, `tw:text-ink`, `tw:rounded-surface`).

## Versioning

`VERSION` follows semantic versioning, starting at `1.0.0`:

- **PATCH**: bug and style fixes
- **MINOR**: new components or features, backwards compatible
- **MAJOR**: breaking changes to a component's API
