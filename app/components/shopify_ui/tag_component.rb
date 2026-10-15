# frozen_string_literal: true

module ShopifyUI
  # Shopify admin tag (Polaris Tag).
  #
  # Covers: plain, removable (✕; client-side with `sui:tag-remove` event, or a remove_url link),
  # link tag (href), clickable tag (button), disabled, sizes (medium 24px / large 32px),
  # long labels truncated with a tooltip, and an optional hidden input so tags submit with a form.
  # Phones: medium tags grow to 32px and the ✕ gets a 32px hit area; labels can use the full row width.
  class TagComponent < ViewComponent::Base
    strip_trailing_whitespace

    SIZES = {
      medium: "tw:min-h-6 tw:text-[12.5px] tw:max-sm:min-h-8 tw:max-sm:text-[13px]",
      large: "tw:min-h-8 tw:text-[13px] tw:max-sm:min-h-9 tw:max-sm:text-[14px]"
    }.freeze
    PADS = { medium: "tw:px-2", large: "tw:px-2.5" }.freeze

    ROOT = %w[
      tw:inline-flex tw:max-w-full tw:min-w-0 tw:items-center tw:rounded-lg tw:bg-fill-tertiary tw:font-sans
      tw:font-medium tw:leading-4 tw:text-ink tw:align-middle tw:transition-colors tw:duration-100
    ].freeze
    INTERACTIVE = %w[
      tw:cursor-pointer tw:no-underline tw:hover:no-underline tw:hover:bg-fill-tertiary-hover tw:hover:text-ink
      tw:active:bg-fill-tertiary-active tw:border-0
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
    ].freeze
    DISABLED = "tw:bg-surface-secondary tw:text-disabled tw:cursor-not-allowed tw:ring-1 tw:ring-inset tw:ring-border-secondary"
    LABEL = "tw:min-w-0 tw:truncate tw:py-0.5 tw:max-w-[240px] tw:max-sm:max-w-none"

    REMOVE = %w[
      tw:-mr-0.5 tw:ml-0.5 tw:inline-flex tw:size-5 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-md tw:border-0
      tw:bg-transparent tw:p-0 tw:text-muted tw:no-underline tw:cursor-pointer
      tw:hover:bg-fill-tertiary-hover tw:hover:text-ink tw:active:bg-fill-tertiary-active
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:disabled:cursor-not-allowed tw:disabled:text-disabled tw:disabled:hover:bg-transparent
      tw:max-sm:size-8 tw:max-sm:-mr-1.5 tw:max-sm:-my-1
    ].freeze

    REMOVE_SCRIPT = "var t = this.closest('[data-sui-tag]');" \
                    "var ok = t.dispatchEvent(new CustomEvent('sui:tag-remove', { bubbles: true, cancelable: true, detail: { value: t.getAttribute('data-value') } }));" \
                    "if (ok) { var next = t.nextElementSibling && t.nextElementSibling.querySelector('button, a, input');" \
                    " t.remove(); if (next) next.focus(); }"

    # removable: true -> ✕ removes it on the client; remove_url: -> ✕ is a link (e.g. data: { turbo_method: :delete }).
    # name: adds <input type=hidden name=… value=value> so the tag submits with its form.
    def initialize(label, value: nil, size: :medium, removable: false, remove_url: nil, remove_attributes: {},
                   href: nil, clickable: false, disabled: false, name: nil, **html_attributes)
      @label = label.to_s
      @value = (value || @label).to_s
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @removable = removable || remove_url.present?
      @remove_url = remove_url
      @remove_attributes = remove_attributes
      @href = href
      @clickable = clickable
      @disabled = disabled
      @name = name
      @html_attributes = html_attributes
    end

    def call
      label = tag.span(@label, class: LABEL, title: (@label if @label.length > 24))
      hidden = tag.input(type: "hidden", name: @name, value: @value, disabled: @disabled || nil) if @name

      if (@href || @clickable) && !@removable
        css = [ ROOT, SIZES[@size], PADS[@size], (@disabled ? DISABLED : INTERACTIVE), @html_attributes[:class] ].flatten.compact.join(" ")
        attrs = @html_attributes.merge(class: css, data: { sui_tag: "", value: @value }.merge(@html_attributes[:data] || {}))
        body = safe_join([ label, hidden ].compact)
        return tag.span(body, **attrs, aria: { disabled: true }) if @disabled
        return tag.a(body, href: @href, **attrs) if @href

        return tag.button(body, type: "button", **attrs)
      end

      css = [ ROOT, SIZES[@size], PADS[@size], (DISABLED if @disabled), @html_attributes[:class] ].flatten.compact.join(" ")
      label = tag.a(label, href: @href, class: "tw:min-w-0 tw:text-inherit tw:no-underline tw:hover:underline tw:flex") if @href && !@disabled
      tag.span(safe_join([ label, remove_tag, hidden ].compact), **@html_attributes, class: css,
               data: { sui_tag: "", value: @value }.merge(@html_attributes[:data] || {}),
               aria: { disabled: (@disabled || nil) })
    end

    private

    def remove_tag
      return unless @removable

      icon = tag.svg(tag.path(d: "m6 6 8 8m0-8-8 8"), viewBox: "0 0 20 20", width: 14, height: 14, fill: "none",
                     stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", aria: { hidden: true })
      label = "Remove #{@label}"
      if @remove_url && !@disabled
        tag.a(icon, href: @remove_url, class: REMOVE.join(" "), aria: { label: label }, **@remove_attributes)
      else
        tag.button(icon, type: "button", class: REMOVE.join(" "), aria: { label: label }, disabled: @disabled || nil,
                   onclick: (REMOVE_SCRIPT unless @disabled))
      end
    end
  end
end
