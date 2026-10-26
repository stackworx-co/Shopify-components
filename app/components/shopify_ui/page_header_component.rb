# frozen_string_literal: true

module ShopifyUI
  # Shopify admin page header (Polaris Page header).
  #
  # Covers: back action, title (or visually hidden title), title badges, subtitle, extra metadata slot
  # (e.g. location chip, "from Online Store"), primary action, secondary actions, action groups
  # (dropdowns like "More actions"), and record pagination (prev/next).
  # Below md the secondary actions and action groups collapse into one "…" menu, the primary action
  # stays visible, and long titles wrap.
  #
  # primary_action:    { label:, href:, disabled:, destructive:, attributes: {} }
  # secondary_actions: [{ label:, href:, icon:, disabled:, destructive:, attributes: {} }]
  # action_groups:     [{ label: "More actions", actions: [secondary action hashes] }]
  # badges:            [{ label:, tone:, appearance: }]
  # pagination:        PaginationComponent arguments, e.g. { previous_url:, next_url: }
  class PageHeaderComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :metadata

    WRAPPER = "tw:flex tw:flex-wrap tw:items-start tw:justify-between tw:gap-x-4 tw:gap-y-3 tw:font-sans tw:min-w-0 tw:pb-4 tw:max-sm:pb-3"
    TITLE_AREA = "tw:flex tw:min-w-0 tw:flex-1 tw:basis-[240px] tw:items-start tw:gap-2"
    BACK = %w[
      tw:mt-0.5 tw:inline-flex tw:size-7 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0
      tw:bg-transparent tw:text-ink tw:no-underline tw:cursor-pointer tw:transition-colors tw:duration-100
      tw:hover:bg-fill-tertiary tw:active:bg-fill-tertiary-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:size-9 tw:max-sm:-ml-1.5 tw:max-sm:mt-0
    ].freeze
    TITLE_STACK = "tw:flex tw:min-w-0 tw:flex-col tw:gap-0.5"
    TITLE_ROW = "tw:flex tw:min-w-0 tw:flex-wrap tw:items-center tw:gap-x-2 tw:gap-y-1"
    # Shared Polaris 2 type scale (TextComponent::SCALE) so page titles match HeadingComponent everywhere.
    TITLE = "tw:min-w-0 tw:break-words #{TextComponent.classes(:display_md)}"
    SUBTITLE = "tw:break-words #{TextComponent.classes(:body_md, tone: :subdued)}"
    METADATA = "tw:flex tw:flex-wrap tw:items-center tw:gap-2 tw:text-[13px] tw:text-muted"

    ACTIONS = "tw:flex tw:shrink-0 tw:items-center tw:gap-2 tw:max-w-full tw:ml-auto"
    DESKTOP_ONLY = "tw:max-md:hidden"
    MOBILE_ONLY = "tw:md:hidden"

    def initialize(title:, back_url: nil, back_label: "Back", title_hidden: false, subtitle: nil, badges: [],
                   primary_action: nil, secondary_actions: [], action_groups: [], pagination: nil, **html_attributes)
      @title = title
      @back_url = back_url
      @back_label = back_label
      @title_hidden = title_hidden
      @subtitle = subtitle
      @badges = Array(badges).map { |b| b.to_h.symbolize_keys }
      @primary = primary_action&.to_h&.symbolize_keys
      @secondary = Array(secondary_actions).map { |a| a.to_h.symbolize_keys }
      @groups = Array(action_groups).map { |g| g.to_h.symbolize_keys }
      @pagination = pagination&.to_h&.symbolize_keys
      @html_attributes = html_attributes
    end

    private

    def wrapper_attributes
      @html_attributes.merge(class: [ WRAPPER, @html_attributes[:class] ].compact.join(" "))
    end

    def collapsible?
      @secondary.any? || @groups.any?
    end

    def actions?
      collapsible? || @primary || @pagination
    end

    def back_tag
      return unless @back_url

      arrow = tag.svg(tag.path(d: "M16 10H4m5-5-5 5 5 5"), viewBox: "0 0 20 20", width: 20, height: 20, fill: "none",
                      stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round",
                      aria: { hidden: true }, focusable: "false")
      link_to(arrow, @back_url, class: BACK.join(" "), aria: { label: @back_label })
    end

    def badge_tags
      safe_join(@badges.map do |b|
        render(BadgeComponent.new(tone: b[:tone] || :neutral, appearance: b[:appearance] || :fill)) { b[:label] }
      end)
    end

    def button_for(action, variant: :page)
      variant = :critical if action[:destructive] && variant == :primary
      render(ButtonComponent.new(variant: variant, href: action[:href], disabled: action[:disabled] || false,
                                 **(action[:attributes] || {}))) do
        safe_join([ action[:icon], action[:label] ].compact)
      end
    end

    def menu_action(menu, action)
      menu.with_action(href: action[:href], icon: action[:icon], destructive: action[:destructive] || false,
                       disabled: action[:disabled] || false, **(action[:attributes] || {})) { action[:label] }
    end

    def group_menu(group)
      render(DropdownMenuComponent.new(label: group[:label], variant: :page, align: :end)) do |menu|
        Array(group[:actions]).each { |a| menu_action(menu, a.to_h.symbolize_keys) }
      end
    end

    # Everything except the primary action, in one menu for small screens.
    def mobile_menu
      render(DropdownMenuComponent.new(icon_label: "More actions", align: :end)) do |menu|
        @secondary.each { |a| menu_action(menu, a) }
        @groups.each_with_index do |group, index|
          menu.with_divider if index.positive? || @secondary.any?
          menu.with_heading(group[:label])
          Array(group[:actions]).each { |a| menu_action(menu, a.to_h.symbolize_keys) }
        end
      end
    end

    def pagination_tag
      return unless @pagination

      render(PaginationComponent.new(type: :page, previous_label: "Previous", next_label: "Next", **@pagination))
    end
  end
end
