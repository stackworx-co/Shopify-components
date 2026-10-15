# frozen_string_literal: true

module ShopifyUI
  # Shopify admin banner (Polaris Banner).
  #
  # Covers: tones (info / success / warning / critical), titled banners (coloured header bar + white body)
  # and untitled banners (tinted box), body content of any kind, primary + secondary actions,
  # dismiss button, hidden icon, and the compact in-card variant.
  # On phones actions wrap onto full rows, the dismiss button grows to a 36px tap target, and text wraps.
  class BannerComponent < ViewComponent::Base
    strip_trailing_whitespace

    TONES = %i[info success warning critical].freeze

    ICONS = {
      info: '<circle cx="10" cy="10" r="7.25"/><path d="M10 9v4.5"/><path d="M10 6.5h.01"/>',
      success: '<circle cx="10" cy="10" r="7.25"/><path d="m6.8 10.2 2.2 2.2 4.2-4.6"/>',
      warning: '<path d="M8.6 3.4 2.4 14.3A1.6 1.6 0 0 0 3.8 16.7h12.4a1.6 1.6 0 0 0 1.4-2.4L11.4 3.4a1.6 1.6 0 0 0-2.8 0Z"/><path d="M10 7.5v3.5"/><path d="M10 13.6h.01"/>',
      critical: '<path d="M7 2.75h6L17.25 7v6L13 17.25H7L2.75 13V7Z"/><path d="M10 6.5v4"/><path d="M10 13.4h.01"/>'
    }.freeze

    # Titled: strong header bar. Untitled / in card: light tint.
    HEADER_TONES = {
      info: "tw:bg-info-strong tw:text-on-strong-light",
      success: "tw:bg-good-strong tw:text-on-strong-dark",
      warning: "tw:bg-warn-strong tw:text-on-strong-light",
      critical: "tw:bg-danger-strong tw:text-on-strong-dark"
    }.freeze
    TINT_TONES = {
      info: "tw:bg-info-light",
      success: "tw:bg-good-light",
      warning: "tw:bg-warn-light",
      critical: "tw:bg-danger-light"
    }.freeze
    ICON_TONES = {
      info: "tw:text-info-icon",
      success: "tw:text-good-icon",
      warning: "tw:text-warn-icon",
      critical: "tw:text-danger-icon"
    }.freeze

    BASE = "tw:relative tw:font-sans tw:text-[13px] tw:leading-5 tw:text-ink tw:min-w-0 tw:break-words"
    TITLED = "tw:overflow-hidden tw:rounded-[12px] tw:bg-surface tw:shadow-card tw:ring-1 tw:ring-border-secondary"
    UNTITLED = "tw:rounded-[12px] tw:shadow-card"
    IN_CARD = "tw:rounded-lg"

    HEADER = "tw:flex tw:items-start tw:gap-2 tw:px-3 tw:py-2 tw:max-sm:py-2.5"
    HEADER_TITLE = "tw:m-0 tw:min-w-0 tw:flex-1 tw:pt-px tw:text-[13px] tw:font-semibold tw:leading-5"
    BODY_TITLED = "tw:flex tw:flex-col tw:gap-3 tw:p-3 tw:max-sm:px-3 tw:max-sm:py-3"

    ROW = "tw:flex tw:items-start tw:gap-2 tw:px-3 tw:py-2.5"
    ROW_IN_CARD = "tw:flex tw:items-start tw:gap-2 tw:px-2.5 tw:py-2"
    CONTENT = "tw:flex tw:min-w-0 tw:flex-1 tw:flex-col tw:gap-2.5 tw:pt-px"
    PROSE = "tw:min-w-0 tw:[&_p]:m-0 tw:[&_ul]:m-0 tw:[&_ul]:pl-5 tw:[&_a]:text-link tw:[&_a]:underline"

    ICON = "tw:size-5 tw:shrink-0"
    ACTIONS = "tw:flex tw:flex-wrap tw:items-center tw:gap-x-3 tw:gap-y-2 tw:max-sm:[&>*:first-child]:flex-1 tw:max-sm:[&>*:first-child]:basis-full"

    DISMISS = %w[
      tw:-my-0.5 tw:-mr-1 tw:inline-flex tw:size-6 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-control
      tw:border-0 tw:bg-transparent tw:p-0 tw:text-inherit tw:opacity-80 tw:cursor-pointer
      tw:hover:opacity-100 tw:hover:bg-[rgba(0,0,0,.08)]
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:max-sm:size-9 tw:max-sm:-my-2
    ].freeze

    DISMISS_SCRIPT = "var b = this.closest('[data-sui-banner]');" \
                     "b.dispatchEvent(new CustomEvent('sui:banner-dismiss', { bubbles: true }));" \
                     "b.remove();"

    # primary_action:   { label:, href:, attributes: {} }  (secondary-style button, as in Polaris)
    # secondary_action: { label:, href:, attributes: {} }  (plain link-style button)
    def initialize(tone: :info, title: nil, primary_action: nil, secondary_action: nil, dismissible: false,
                   hide_icon: false, in_card: false, **html_attributes)
      @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :info
      @title = title
      @primary = primary_action&.to_h&.symbolize_keys
      @secondary = secondary_action&.to_h&.symbolize_keys
      @dismissible = dismissible
      @hide_icon = hide_icon
      @in_card = in_card
      @html_attributes = html_attributes
    end

    private

    def titled?
      @title.present? && !@in_card
    end

    def root_attributes
      variant = if titled? then TITLED elsif @in_card then [ IN_CARD, TINT_TONES[@tone] ] else [ UNTITLED, TINT_TONES[@tone] ] end
      @html_attributes.merge(
        class: [ BASE, variant, @html_attributes[:class] ].flatten.compact.join(" "),
        role: (@tone == :critical || @tone == :warning ? "alert" : "status"),
        aria: { labelledby: (title_id if @title.present?) }.merge(@html_attributes[:aria] || {}),
        data: { sui_banner: "", tone: @tone }.merge(@html_attributes[:data] || {})
      )
    end

    def title_id
      @title_id ||= "sui-banner-#{SecureRandom.hex(4)}"
    end

    def icon_tag(colored: true)
      return if @hide_icon

      tag.svg(ICONS[@tone].html_safe, viewBox: "0 0 20 20", fill: "none", stroke: "currentColor", "stroke-width": 1.6,
              "stroke-linecap": "round", "stroke-linejoin": "round",
              class: [ ICON, (ICON_TONES[@tone] if colored) ].compact.join(" "), aria: { hidden: true }, focusable: "false")
    end

    def dismiss_tag
      return unless @dismissible

      x = tag.svg(tag.path(d: "m5.5 5.5 9 9m0-9-9 9"), viewBox: "0 0 20 20", width: 18, height: 18, fill: "none",
                  stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", aria: { hidden: true })
      tag.button(x, type: "button", class: DISMISS.join(" "), aria: { label: "Dismiss notification" }, onclick: DISMISS_SCRIPT)
    end

    def actions_tag
      return unless @primary || @secondary

      safe_join([
        tag.div(safe_join([
          (render(ButtonComponent.new(href: @primary[:href], size: @in_card ? :slim : :medium, **(@primary[:attributes] || {}))) { @primary[:label] } if @primary),
          (render(ButtonComponent.new(variant: :plain, href: @secondary[:href], **(@secondary[:attributes] || {}))) { @secondary[:label] } if @secondary)
        ].compact), class: ACTIONS)
      ])
    end

    def body_tag
      parts = [ (tag.div(content, class: PROSE) if content.present?), actions_tag ].compact
      safe_join(parts)
    end
  end
end
