# frozen_string_literal: true

module ShopifyUI
  # Shopify admin card (Polaris Card / LegacyCard).
  #
  # Covers: plain card, header (title, subtitle, badge, header actions as plain links or a "…" menu,
  # or a fully custom header slot), sections with dividers (each with optional title, actions,
  # subdued background, flush/no padding), subdued (grey) card background, padding sizes,
  # footer (primary + secondary actions or custom content), collapsible card, and edge-to-edge on phones.
  # Phones: no side border/radius by default (like the admin), tighter padding, header actions and footer
  # buttons wrap, footer buttons stretch to full width.
  class CardComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :header
    renders_one :footer
    renders_many :sections, ->(title: nil, actions: [], subdued: false, flush: false, &block) {
      section_tag(title: title, actions: actions, subdued: subdued, flush: flush, body: block ? capture(&block) : nil)
    }

    PADDINGS = {
      none: "",
      tight: "tw:p-3",
      base: "tw:p-4 tw:max-sm:p-3.5",
      loose: "tw:p-5 tw:max-sm:p-4"
    }.freeze
    X_PADDINGS = { none: "", tight: "tw:px-3", base: "tw:px-4 tw:max-sm:px-3.5", loose: "tw:px-5 tw:max-sm:px-4" }.freeze

    CARD = "tw:relative tw:min-w-0 tw:overflow-hidden tw:font-sans tw:text-[13px] tw:leading-5 tw:text-ink tw:shadow-card tw:ring-1 tw:ring-border-secondary tw:rounded-surface"
    EDGE_TO_EDGE = "tw:max-sm:rounded-none tw:max-sm:ring-0 tw:max-sm:border-y tw:max-sm:border-border"
    BACKGROUNDS = { default: "tw:bg-surface", subdued: "tw:bg-surface-secondary" }.freeze

    HEADER = "tw:flex tw:flex-wrap tw:items-start tw:justify-between tw:gap-x-3 tw:gap-y-1"
    TITLE_GROUP = "tw:flex tw:min-w-0 tw:flex-1 tw:basis-[160px] tw:flex-col tw:gap-0.5"
    TITLE_ROW = "tw:flex tw:min-w-0 tw:flex-wrap tw:items-center tw:gap-2"
    TITLE = "tw:m-0 tw:min-w-0 tw:text-[14px] tw:font-semibold tw:leading-5 tw:text-ink tw:break-words"
    SUBTITLE = "tw:m-0 tw:text-[13px] tw:text-muted tw:break-words"
    HEADER_ACTIONS = "tw:flex tw:shrink-0 tw:flex-wrap tw:items-center tw:gap-x-3 tw:gap-y-1 tw:-my-1"

    SECTION = "tw:border-t tw:border-border-secondary tw:first:border-t-0"
    SECTION_SUBDUED = "tw:bg-surface-secondary"
    SECTION_HEADER = "tw:mb-2 tw:flex tw:flex-wrap tw:items-baseline tw:justify-between tw:gap-x-3 tw:gap-y-1"
    SECTION_TITLE = "tw:m-0 tw:text-[12px] tw:font-semibold tw:uppercase tw:tracking-[.02em] tw:text-muted"

    FOOTER = "tw:flex tw:flex-wrap tw:items-center tw:justify-end tw:gap-2 tw:border-t tw:border-border-secondary tw:py-3 tw:max-sm:[&>*]:flex-1"

    TOGGLE = %w[
      tw:inline-flex tw:size-7 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-control tw:text-muted
      tw:hover:bg-fill-tertiary tw:hover:text-ink tw:transition-transform tw:duration-150
      tw:group-open:rotate-180 tw:max-sm:size-9 tw:-my-1 tw:-mr-1
    ].freeze
    SUMMARY = "tw:list-none tw:cursor-pointer tw:[&::-webkit-details-marker]:hidden tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link"

    # actions:         [{ label:, href:, destructive:, attributes: {} }] shown as plain links in the header
    # menu_actions:    [{ label:, href:, destructive: }] shown in a "…" menu in the header
    # primary_footer_action / secondary_footer_actions: buttons in the footer
    # badge:           { label:, tone:, appearance: }
    # collapsible:     true / :open (collapsed by default with true)
    def initialize(title: nil, subtitle: nil, badge: nil, actions: [], menu_actions: [],
                   primary_footer_action: nil, secondary_footer_actions: [],
                   sectioned: false, padding: :base, background: :default, edge_to_edge: true,
                   collapsible: false, **html_attributes)
      @title = title
      @subtitle = subtitle
      @badge = badge&.to_h&.symbolize_keys
      @actions = Array(actions).map { |a| a.to_h.symbolize_keys }
      @menu_actions = Array(menu_actions).map { |a| a.to_h.symbolize_keys }
      @primary = primary_footer_action&.to_h&.symbolize_keys
      @secondary = Array(secondary_footer_actions).map { |a| a.to_h.symbolize_keys }
      @sectioned = sectioned
      @padding = PADDINGS.key?(padding&.to_sym) ? padding.to_sym : :base
      @background = BACKGROUNDS.key?(background&.to_sym) ? background.to_sym : :default
      @edge_to_edge = edge_to_edge
      @collapsible = collapsible
      @html_attributes = html_attributes
    end

    private

    def root_attributes
      @html_attributes.merge(class: [ CARD, BACKGROUNDS[@background], (EDGE_TO_EDGE if @edge_to_edge),
                                      @html_attributes[:class] ].compact.join(" "))
    end

    def pad
      PADDINGS[@padding]
    end

    def has_header?
      header? || @title.present?
    end

    def header_tag
      return header if header?
      return unless @title.present?

      title_row = tag.div(safe_join([
        tag.h2(@title, class: TITLE),
        (render(BadgeComponent.new(tone: @badge[:tone] || :neutral, appearance: @badge[:appearance] || :fill)) { @badge[:label] } if @badge)
      ].compact), class: TITLE_ROW)
      group = tag.div(safe_join([ title_row, (tag.p(@subtitle, class: SUBTITLE) if @subtitle.present?) ].compact), class: TITLE_GROUP)
      tag.div(safe_join([ group, header_actions_tag, (toggle_icon if @collapsible) ].compact), class: HEADER)
    end

    def header_actions_tag
      return if @actions.empty? && @menu_actions.empty?

      links = @actions.map do |a|
        render(ButtonComponent.new(variant: :plain, href: a[:href], **(a[:attributes] || {}),
                                   class: ("tw:text-danger tw:hover:text-danger" if a[:destructive]))) { a[:label] }
      end
      menu = if @menu_actions.any?
               render(DropdownMenuComponent.new(icon_label: "More actions", align: :end)) do |m|
                 @menu_actions.each { |a| m.with_action(href: a[:href], destructive: a[:destructive] || false) { a[:label] } }
               end
             end
      tag.div(safe_join([ *links, menu ].compact), class: HEADER_ACTIONS)
    end

    def toggle_icon
      tag.span(tag.svg(tag.path(d: "m6 8 4 4 4-4"), viewBox: "0 0 20 20", width: 18, height: 18, fill: "none",
                       stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round"),
               class: TOGGLE.join(" "), aria: { hidden: true })
    end

    def section_tag(title:, actions:, subdued:, flush:, body:)
      head = if title.present? || Array(actions).any?
               links = Array(actions).map { |a| a = a.to_h.symbolize_keys; render(ButtonComponent.new(variant: :plain, href: a[:href])) { a[:label] } }
               tag.div(safe_join([ (tag.h3(title, class: SECTION_TITLE) if title.present?), tag.div(safe_join(links), class: "tw:flex tw:gap-3 tw:ml-auto") ].compact),
                       class: [ SECTION_HEADER, (X_PADDINGS[@padding] + " tw:pt-3" if flush) ].compact.join(" "))
             end
      tag.div(safe_join([ head, body ].compact),
              class: [ SECTION, (pad unless flush), (SECTION_SUBDUED if subdued) ].compact.join(" "))
    end

    def footer_present?
      footer? || @primary || @secondary.any?
    end

    def footer_tag
      inner = if footer?
                footer
              else
                safe_join([
                  *@secondary.map { |a| render(ButtonComponent.new(href: a[:href], **(a[:attributes] || {}))) { a[:label] } },
                  (render(ButtonComponent.new(variant: @primary[:destructive] ? :critical : :primary, href: @primary[:href],
                                              disabled: @primary[:disabled] || false, **(@primary[:attributes] || {}))) { @primary[:label] } if @primary)
                ].compact)
              end
      tag.div(inner, class: [ FOOTER, X_PADDINGS[@padding] ].join(" "))
    end

    def body_tag
      if sections?
        tag.div(safe_join(sections), class: "tw:border-t tw:border-border-secondary tw:first:border-t-0")
      elsif content.present?
        tag.div(content, class: [ pad, (has_header? && !@sectioned ? "tw:pt-0" : nil),
                                  ("tw:border-t tw:border-border-secondary" if has_header? && @sectioned) ].compact.join(" "))
      end
    end
  end
end
