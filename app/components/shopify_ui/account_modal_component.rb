# frozen_string_literal: true

module ShopifyUI
  # "Add account" / "Edit account" popup: a Login section (email, password, confirm password) and an
  # Access section (permission checkboxes as cards), with Cancel / Create account in the footer.
  # Built on ModalComponent and wrapped in a <form>, so it submits like any Rails form.
  #
  # Covers: new and edit modes (edit makes passwords optional with a "leave blank" hint and pre-fills
  # values), any list of permissions (with help text, disabled, pre-selected), per-field errors and a
  # base error banner, re-opening on load after a failed submit, extra fields (name, role, ...) through
  # the `fields` slot, hidden Login or Access sections, custom labels / param names, read-only email,
  # a destructive "Delete account" action in edit mode, and a saving state. Phones get a bottom sheet
  # with full-width buttons and 16px inputs.
  #
  #   <%= render ShopifyUI::ButtonComponent.new(variant: :primary, **ShopifyUI::AccountModalComponent.open_attributes("add-account")) { "Add account" } %>
  #   <%= render ShopifyUI::AccountModalComponent.new(id: "add-account", url: admin_users_path, scope: :user,
  #         permissions: [{ label: "Returns portal", value: "returns", help_text: "Can open the Returns Center." }]) %>
  class AccountModalComponent < ViewComponent::Base
    strip_trailing_whitespace

    # Extra inputs rendered at the end of the Login section.
    renders_one :fields

    MODES = %i[new edit].freeze

    SECTION = "tw:flex tw:flex-col tw:gap-3"
    SECTION_TITLE = "tw:m-0 tw:flex tw:items-center tw:gap-1.5 tw:text-[14px] tw:font-semibold tw:leading-5 tw:text-ink"
    SECTION_ICON = "tw:size-4 tw:shrink-0 tw:text-muted"
    DESCRIPTION = "tw:m-0 tw:text-[13px] tw:leading-5 tw:text-muted"
    PASSWORDS = "tw:grid tw:gap-3 tw:sm:grid-cols-2"

    def self.open_attributes(id)
      ModalComponent.open_attributes(id)
    end

    # permissions: [{ label:, value:, help_text:, disabled: }] or ["Label", ...] or [["Label", "value"]]
    # errors:      { email: "...", password: "...", password_confirmation: "...", permissions: "...", base: "..." }
    #              (values may be arrays, e.g. user.errors.to_hash)
    def initialize(id:, url:, mode: :new, scope: :user, method: nil, email: nil, permissions: [], selected: [],
                   errors: {}, title: nil, submit_label: nil, cancel_label: "Cancel",
                   login_title: "Login", access_title: "Access",
                   access_description: "Every account can use the main dashboard.",
                   email_label: "Email", password_label: "Password", confirmation_label: "Confirm password",
                   password_help: nil, email_read_only: false, show_login: true, show_access: true,
                   delete_url: nil, delete_label: "Delete account", saving: false, **modal_options)
      @id = id
      @url = url
      @mode = MODES.include?(mode&.to_sym) ? mode.to_sym : :new
      @scope = scope.presence
      @method = method || (edit? ? :patch : :post)
      @email = email
      @permissions = permissions
      @selected = selected
      @errors = errors.to_h.transform_keys(&:to_sym).transform_values { |v| Array(v).first.presence }.compact
      @title = title || (edit? ? "Edit account" : "Add account")
      @submit_label = submit_label || (edit? ? "Save" : "Create account")
      @cancel_label = cancel_label
      @login_title = login_title
      @access_title = access_title
      @access_description = access_description
      @email_label = email_label
      @password_label = password_label
      @confirmation_label = confirmation_label
      @password_help = password_help || ("Leave blank to keep the current password." if edit?)
      @email_read_only = email_read_only
      @show_login = show_login
      @show_access = show_access
      @delete_url = delete_url
      @delete_label = delete_label
      @saving = saving
      # Re-open after a failed submit so the errors are visible.
      @modal_options = { open: @errors.any? }.merge(modal_options)
    end

    private

    def edit?
      @mode == :edit
    end

    def form_id
      "#{@id}-form"
    end

    def param(key)
      @scope ? "#{@scope}[#{key}]" : key.to_s
    end

    def modal
      secondary = [ { label: @cancel_label, close: true } ]
      if edit? && @delete_url
        secondary.unshift({ label: @delete_label, destructive: true, href: @delete_url,
                            attributes: { data: { turbo_method: :delete, turbo_confirm: "#{@delete_label}?" } } })
      end
      ModalComponent.new(
        id: @id, title: @title, flush: true, **@modal_options,
        primary_action: { label: @submit_label, loading: @saving, attributes: { type: "submit", form: form_id } },
        secondary_actions: secondary
      )
    end

    def text_field(key, label:, type:, value: nil, **options)
      render(TextFieldComponent.new(name: param(key), label: label, type: type, value: value, error: @errors[key],
                                    id: "#{@id}-#{key}", disabled: @saving, **options))
    end

    def section_title(title, icon)
      tag.h3(safe_join([ icon, title ]), class: SECTION_TITLE)
    end

    def user_icon
      icon("M10 10a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.5 6c0-2.5 2.46-4 5.5-4s5.5 1.5 5.5 4")
    end

    def shield_icon
      icon("M10 3 4.5 5v4.5c0 3.3 2.3 6 5.5 7.5 3.2-1.5 5.5-4.2 5.5-7.5V5L10 3Zm-2 7 1.5 1.5L12.5 8.5")
    end

    def icon(d)
      tag.svg(tag.path(d: d), viewBox: "0 0 20 20", fill: "none", stroke: "currentColor", "stroke-width": 1.5,
              "stroke-linecap": "round", "stroke-linejoin": "round", class: SECTION_ICON, aria: { hidden: true })
    end
  end
end
