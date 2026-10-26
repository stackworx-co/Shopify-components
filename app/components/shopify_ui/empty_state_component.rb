# frozen_string_literal: true

module ShopifyUI
  # Shopify admin empty state (Polaris EmptyState + IndexTable "no results").
  #
  # Covers: illustration (built-in line illustrations or your own image / slot), heading, body content,
  # primary + secondary actions, footer help text (e.g. "Learn more about orders"), layouts
  # (centered / full_width with image beside the text on wide screens), sizes (default page-level /
  # compact for inside cards and tables), contained image, inside a card, and the "no results" search variant.
  # Phones: everything stacks centred, illustration scales down, buttons go full width (primary on top).
  class EmptyStateComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :illustration
    renders_one :footer

    ILLUSTRATIONS = {
      orders: <<~SVG,
        <rect x="38" y="52" width="124" height="88" rx="12" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <path d="M38 76h124" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <path d="M84 52V36a16 16 0 0 1 32 0v16" fill="none" stroke="var(--sui-faint)" stroke-width="2.5" stroke-linecap="round"/>
        <rect x="56" y="92" width="52" height="8" rx="4" fill="var(--sui-fill-tertiary)"/><rect x="56" y="108" width="80" height="8" rx="4" fill="var(--sui-fill-tertiary)"/>
        <circle cx="150" cy="128" r="18" fill="var(--sui-good-light)" stroke="var(--sui-good-icon)" stroke-width="2"/><path d="m142 128 6 6 10-11" fill="none" stroke="var(--sui-good-icon)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
      SVG
      products: <<~SVG,
        <path d="M94 30h46a12 12 0 0 1 12 12v46a8 8 0 0 1-2.3 5.7l-56 56a8 8 0 0 1-11.4 0l-46-46a8 8 0 0 1 0-11.4l56-56A8 8 0 0 1 94 30Z" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <circle cx="128" cy="54" r="8" fill="var(--sui-info-light)" stroke="var(--sui-info-icon)" stroke-width="2"/>
        <path d="m70 100 30 30M84 86l30 30" stroke="var(--sui-fill-tertiary)" stroke-width="7" stroke-linecap="round"/>
      SVG
      customers: <<~SVG,
        <circle cx="82" cy="66" r="22" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <path d="M44 138c0-22 17-38 38-38s38 16 38 38" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <circle cx="132" cy="78" r="16" fill="var(--sui-info-light)" stroke="var(--sui-info-icon)" stroke-width="2"/>
        <path d="M108 138c0-16 11-28 24-28s26 12 26 28" fill="var(--sui-info-light)" stroke="var(--sui-info-icon)" stroke-width="2"/>
      SVG
      search: <<~SVG,
        <circle cx="90" cy="76" r="38" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <path d="m118 104 30 30" stroke="var(--sui-faint)" stroke-width="7" stroke-linecap="round"/>
        <path d="M74 66h32M74 80h22" stroke="var(--sui-fill-tertiary)" stroke-width="6" stroke-linecap="round"/>
      SVG
      files: <<~SVG,
        <path d="M66 28h48l32 32v84a10 10 0 0 1-10 10H66a10 10 0 0 1-10-10V38a10 10 0 0 1 10-10Z" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <path d="M114 28v32h32" fill="none" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <path d="M100 124V88m-14 14 14-14 14 14" fill="none" stroke="var(--sui-info-icon)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
      SVG
      generic: <<~SVG
        <rect x="40" y="40" width="120" height="96" rx="14" fill="var(--sui-surface)" stroke="var(--sui-border-hover)" stroke-width="2"/>
        <circle cx="76" cy="74" r="10" fill="var(--sui-warn-light)" stroke="var(--sui-warn-icon)" stroke-width="2"/>
        <path d="m48 128 34-30 20 18 22-22 28 34" fill="none" stroke="var(--sui-faint)" stroke-width="2.5" stroke-linejoin="round"/>
      SVG
    }.freeze

    ROOT = {
      centered: "tw:flex tw:flex-col tw:items-center tw:text-center",
      full_width: "tw:flex tw:flex-col tw:items-center tw:text-center tw:md:flex-row-reverse tw:md:items-center tw:md:justify-between tw:md:text-left tw:md:gap-10"
    }.freeze
    PADDING = { default: "tw:px-6 tw:py-14 tw:max-sm:px-4 tw:max-sm:py-10", compact: "tw:px-4 tw:py-8 tw:max-sm:py-6" }.freeze
    BASE = "tw:font-sans tw:text-ink tw:min-w-0"
    CARD = "tw:rounded-surface tw:bg-surface tw:shadow-card tw:max-sm:rounded-none tw:max-sm:ring-0 tw:max-sm:border-y tw:max-sm:border-border"

    IMAGE = {
      default: "tw:w-[226px] tw:max-w-[70%] tw:max-sm:w-[180px]",
      compact: "tw:w-[120px] tw:max-w-[50%]",
      large: "tw:w-[320px] tw:max-w-[80%] tw:max-sm:w-[220px]"
    }.freeze
    IMAGE_WRAP = "tw:mb-5 tw:flex tw:shrink-0 tw:justify-center tw:max-sm:mb-4"
    IMAGE_WRAP_FULL = "tw:md:mb-0 tw:md:w-[40%] tw:md:max-w-[360px]"
    CONTAINED = "tw:rounded-surface tw:bg-surface-secondary tw:p-4"

    TEXT = "tw:flex tw:min-w-0 tw:max-w-[400px] tw:flex-col tw:items-center tw:gap-2 tw:md:max-w-[460px]"
    TEXT_FULL = "tw:md:items-start"
    HEADING = { default: "tw:m-0 tw:text-[16px] tw:font-semibold tw:leading-6 tw:text-ink tw:text-balance", compact: "tw:m-0 tw:text-[14px] tw:font-semibold tw:leading-5 tw:text-ink tw:text-balance" }.freeze
    BODY = "tw:text-[13px] tw:leading-5 tw:text-muted tw:text-pretty tw:[&_p]:m-0 tw:[&_a]:text-link"

    ACTIONS = "tw:mt-3 tw:flex tw:flex-wrap tw:items-center tw:justify-center tw:gap-2 tw:max-sm:w-full tw:max-sm:flex-col-reverse tw:max-sm:items-stretch"
    ACTIONS_FULL = "tw:md:justify-start"
    FOOTER = "tw:mt-3 tw:text-[12.5px] tw:text-muted tw:[&_a]:text-link tw:[&_a]:underline"

    # image: :orders | :products | :customers | :search | :files | :generic | "https://…/image.svg"
    # primary_action / secondary_action: { label:, href:, attributes: {} }
    def initialize(heading:, image: :generic, image_alt: "", layout: :centered, size: :default, large_image: false,
                   image_contained: false, card: false, primary_action: nil, secondary_action: nil, **html_attributes)
      @heading = heading
      @image = image
      @image_alt = image_alt
      @layout = ROOT.key?(layout&.to_sym) ? layout.to_sym : :centered
      @size = PADDING.key?(size&.to_sym) ? size.to_sym : :default
      @large_image = large_image
      @image_contained = image_contained
      @card = card
      @primary = primary_action&.to_h&.symbolize_keys
      @secondary = secondary_action&.to_h&.symbolize_keys
      @html_attributes = html_attributes
    end

    # Ready-made "no results" state for searches / filtered tables.
    def self.no_results(resource: "items", clear_href: nil, **options)
      new(heading: "No #{resource} found", image: :search, size: :compact,
          secondary_action: (clear_href ? { label: "Clear filters", href: clear_href } : nil), **options)
    end

    private

    def full?
      @layout == :full_width
    end

    def root_attributes
      @html_attributes.merge(class: [ BASE, ROOT[@layout], PADDING[@size], (CARD if @card), @html_attributes[:class] ].compact.join(" "))
    end

    def image_size
      @large_image ? :large : @size
    end

    def image_tag_html
      return illustration if illustration?
      return if @image.blank?

      css = [ IMAGE[image_size], "tw:h-auto", (CONTAINED if @image_contained) ].compact.join(" ")
      if @image.is_a?(Symbol) && ILLUSTRATIONS.key?(@image)
        tag.svg(ILLUSTRATIONS[@image].html_safe, viewBox: "0 0 200 170", class: css, role: (@image_alt.present? ? "img" : nil),
                aria: { hidden: (@image_alt.blank? || nil), label: @image_alt.presence }, focusable: "false")
      else
        tag.img(src: @image, alt: @image_alt, loading: "lazy", decoding: "async", class: css)
      end
    end

    def action_button(action, variant)
      return unless action

      render(ButtonComponent.new(variant: variant, href: action[:href], full_width: :mobile, **(action[:attributes] || {}))) { action[:label] }
    end
  end
end
