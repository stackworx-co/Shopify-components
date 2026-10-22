# frozen_string_literal: true

module ShopifyUI
  # Shopify admin breadcrumbs (Polaris Breadcrumbs + admin page trails).
  #
  #   variant: :back  -> square back-arrow button to the parent page (what Polaris Breadcrumbs renders)
  #   variant: :trail -> Home › Products › Snowboards › Hydrogen, last item is the current page
  # Covers: chevron or slash separators, icon on the first item, current page shown or hidden,
  # long trails collapsed into a "…" menu (max_items), and long labels truncated.
  # Phones: a trail collapses to a single "‹ Parent" back link with a 44px tap target.
  #
  # items: [{ label:, href:, icon: :home }] — the last item is the current page.
  # size:  :small (12px) | :medium (13px, default) | :large (15px) — text, icons, separators and back button scale together.
  # max_label_width: px before a label truncates (default 200), or false to never truncate.
  class BreadcrumbsComponent < ViewComponent::Base
    strip_trailing_whitespace

    NAV = "tw:min-w-0 tw:font-sans"
    LIST = "tw:m-0 tw:flex tw:min-w-0 tw:list-none tw:items-center tw:gap-1 tw:p-0 tw:max-sm:hidden"
    ITEM = "tw:flex tw:min-w-0 tw:items-center tw:gap-1"
    LINK = %w[
      tw:inline-flex tw:min-w-0 tw:items-center tw:gap-1.5 tw:rounded-md tw:px-1 tw:py-0.5 tw:text-muted tw:no-underline
      tw:hover:bg-fill-tertiary tw:hover:text-ink tw:hover:no-underline
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
    ].freeze
    CURRENT = "tw:inline-flex tw:min-w-0 tw:items-center tw:gap-1.5 tw:px-1 tw:py-0.5 tw:font-medium tw:text-ink"
    LABEL = "tw:truncate"
    SEPARATOR = "tw:shrink-0 tw:text-faint"
    ICON = "tw:shrink-0"

    SIZES = {
      small: { text: "tw:text-[12px]", icon: "tw:size-3.5", sep: "tw:size-3", back: "tw:size-6", back_icon: "tw:size-4", mobile: "tw:text-[13px]" },
      medium: { text: "tw:text-[13px]", icon: "tw:size-4", sep: "tw:size-3.5", back: "tw:size-7", back_icon: "tw:size-5", mobile: "tw:text-[14px]" },
      large: { text: "tw:text-[15px]", icon: "tw:size-5", sep: "tw:size-4", back: "tw:size-9", back_icon: "tw:size-6", mobile: "tw:text-[16px]" }
    }.freeze

    BACK = %w[
      tw:inline-flex tw:shrink-0 tw:items-center tw:justify-center tw:rounded-control tw:text-ink tw:no-underline
      tw:hover:bg-fill-tertiary tw:active:bg-fill-tertiary-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:size-10
    ].freeze
    MOBILE = %w[
      tw:hidden tw:max-sm:inline-flex tw:min-h-11 tw:max-w-full tw:items-center tw:gap-1 tw:-ml-1.5 tw:rounded-md tw:px-1.5
      tw:font-medium tw:text-muted tw:no-underline tw:hover:text-ink tw:hover:no-underline
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
    ].freeze

    ICONS = {
      home: '<path d="M3 9.5 10 3l7 6.5"/><path d="M5 8.5V17h10V8.5"/>',
      orders: '<rect x="3" y="7" width="14" height="10" rx="2"/><path d="M7 7V5a3 3 0 0 1 6 0v2"/>',
      products: '<rect x="3" y="4" width="14" height="13" rx="2"/><path d="M3 8h14"/>',
      customers: '<circle cx="10" cy="7" r="3"/><path d="M4 17c0-3 2.5-5 6-5s6 2 6 5"/>',
      settings: '<circle cx="10" cy="10" r="2.5"/><path d="M10 2.5v2M10 15.5v2M2.5 10h2M15.5 10h2M4.7 4.7l1.4 1.4M13.9 13.9l1.4 1.4M4.7 15.3l1.4-1.4M13.9 6.1l1.4-1.4"/>'
    }.freeze

    def initialize(items:, variant: :trail, separator: :chevron, show_current: true, max_items: nil,
                   size: :medium, max_label_width: 200, label: "Breadcrumb", **html_attributes)
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @max_label_width = max_label_width
      @items = Array(items).map { |i| i.to_h.symbolize_keys }
      @variant = variant&.to_sym == :back ? :back : :trail
      @separator = separator&.to_sym == :slash ? :slash : :chevron
      @show_current = show_current
      @max_items = max_items
      @label = label
      @html_attributes = html_attributes
    end

    def call
      tag.nav(@variant == :back ? back_tag : safe_join([ trail_tag, mobile_tag ].compact),
              **@html_attributes, aria: { label: @label }, class: [ NAV, @html_attributes[:class] ].compact.join(" "))
    end

    private

    def sz
      SIZES[@size]
    end

    def label_tag(item)
      style = "max-width: #{@max_label_width.to_i}px" if @max_label_width
      tag.span(item[:label], class: LABEL, title: item[:label], style: style)
    end

    def parent
      @items.size > 1 ? @items[-2] : @items.first
    end

    def svg(paths, css, size: 20)
      tag.svg(paths.html_safe, viewBox: "0 0 #{size} #{size}", fill: "none", stroke: "currentColor", "stroke-width": 1.6,
              "stroke-linecap": "round", "stroke-linejoin": "round", class: css, aria: { hidden: true }, focusable: "false")
    end

    def back_tag
      link_to(svg('<path d="M16 10H4m5-5-5 5 5 5"/>', sz[:back_icon]), parent[:href] || "#",
              class: [ BACK, sz[:back] ].flatten.join(" "), aria: { label: "Back to #{parent[:label]}" }, title: parent[:label])
    end

    def separator
      return tag.span("/", class: "#{SEPARATOR} tw:px-0.5", aria: { hidden: true }) if @separator == :slash

      svg('<path d="m8 5 5 5-5 5"/>', "#{SEPARATOR} #{sz[:sep]}")
    end

    def visible_items
      items = @show_current ? @items : @items[0...-1]
      return [ items, [] ] unless @max_items && items.size > @max_items && @max_items >= 2

      hidden = items[1...(items.size - (@max_items - 1))]
      [ [ items.first, :collapsed, *items.last(@max_items - 1) ], hidden ]
    end

    def trail_tag
      items, hidden = visible_items
      current = @items.last
      lis = items.each_with_index.map do |item, index|
        body = if item == :collapsed
                 collapsed_menu(hidden)
               elsif item.equal?(current) && @show_current
                 tag.span(safe_join([ icon_for(item, index), label_tag(item) ].compact),
                          class: CURRENT, aria: { current: "page" })
               else
                 link_to(safe_join([ icon_for(item, index), label_tag(item) ].compact),
                         item[:href] || "#", class: LINK.join(" "))
               end
        tag.li(safe_join([ (separator if index.positive?), body ].compact), class: ITEM)
      end
      tag.ol(safe_join(lis), class: "#{LIST} #{sz[:text]}")
    end

    def icon_for(item, index)
      return unless index.zero? && item[:icon]

      item[:icon].is_a?(Symbol) ? svg(ICONS[item[:icon]] || ICONS[:home], "#{ICON} #{sz[:icon]}") : item[:icon]
    end

    def collapsed_menu(hidden)
      icon = tag.svg(safe_join([ 5, 10, 15 ].map { |x| tag.circle(cx: x, cy: 10, r: 1.4) }), viewBox: "0 0 20 20",
                     width: 16, height: 16, fill: "currentColor", aria: { hidden: true })
      render(DropdownMenuComponent.new(icon: icon, icon_label: "Show #{hidden.size} more pages")) do |menu|
        hidden.each { |item| menu.with_action(href: item[:href] || "#") { item[:label] } }
      end
    end

    def mobile_tag
      return if @items.size < 2

      target = parent

      link_to(safe_join([ svg('<path d="m12 5-5 5 5 5"/>', "#{sz[:icon]} tw:shrink-0"), tag.span(target[:label], class: "tw:truncate") ]),
              target[:href] || "#", class: [ MOBILE, sz[:mobile] ].flatten.join(" "), aria: { label: "Back to #{target[:label]}" })
    end
  end
end
