# frozen_string_literal: true

module ShopifyUI
  # Shopify admin sidebar (black frame navigation).
  #   Desktop (lg+): fixed 240px column, full viewport height, scrolls on its own.
  #   Below lg: a black top bar with a menu button; the sidebar opens as an off-canvas drawer
  #   with a backdrop (closes on backdrop tap, Esc, link tap or resizing to desktop).
  #
  # sections: [{ title: "Sales channels", title_href: nil, items: [item, ...] }, ...]
  #   A divider is drawn between sections, as between Shopify's nav and app-installed items.
  # item: { label:, href:, icon: :orders | "<svg>…</svg>".html_safe, active: true, count: 414,
  #         children: [{ label:, href:, active: }] }  (children show when the item or a child is active)
  # footer_items: items pinned to the bottom (e.g. Settings).
  # store: { name:, badge: "dev", href:, notifications_href: }
  # search: { placeholder: "Search", href: } or false. Ctrl/⌘ K activates it.
  # contained: true fills the parent's height instead of sticking to the viewport.
  class SidebarComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :brand

    ROOT = "tw:group tw:font-sans tw:lg:w-60 tw:lg:shrink-0"
    # viewport: sticks to the window at full height (app layouts). contained: fills its parent (previews, frames).
    ROOT_LAYOUTS = { viewport: "tw:lg:sticky tw:lg:top-0 tw:lg:h-dvh", contained: "tw:lg:h-full" }.freeze

    TOPBAR = %w[
      tw:sticky tw:top-0 tw:z-30 tw:flex tw:h-14 tw:items-center tw:gap-2 tw:bg-frame tw:px-2 tw:text-frame-ink
      tw:lg:hidden
    ].freeze

    ICON_BUTTON = %w[
      tw:inline-flex tw:size-10 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:p-0
      tw:bg-transparent tw:text-frame-ink tw:cursor-pointer tw:appearance-none tw:no-underline
      tw:hover:bg-frame-hover tw:active:bg-frame-active
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-0 tw:focus-visible:outline-white
    ].freeze

    BACKDROP = %w[
      tw:fixed tw:inset-0 tw:z-40 tw:bg-[rgba(0,0,0,.5)] tw:opacity-0 tw:pointer-events-none
      tw:transition-opacity tw:duration-200 tw:motion-reduce:transition-none
      tw:group-data-open:opacity-100 tw:group-data-open:pointer-events-auto tw:lg:hidden
    ].freeze

    PANEL = %w[
      tw:fixed tw:inset-y-0 tw:left-0 tw:z-50 tw:flex tw:w-[min(300px,86vw)] tw:flex-col tw:bg-frame tw:text-frame-ink
      tw:text-[13px] tw:-translate-x-full tw:invisible tw:transition-[translate,visibility] tw:duration-200
      tw:motion-reduce:transition-none
      tw:group-data-open:translate-x-0 tw:group-data-open:visible
      tw:lg:static tw:lg:z-auto tw:lg:h-full tw:lg:w-60 tw:lg:translate-x-0 tw:lg:visible tw:lg:transition-none
    ].freeze

    HEADER = "tw:flex tw:items-center tw:gap-2 tw:px-3.5 tw:pt-3.5 tw:pb-2.5 tw:max-lg:pl-4 tw:max-lg:pr-2 tw:max-lg:pt-2"
    LOGO = %w[
      tw:inline-flex tw:size-[22px] tw:shrink-0 tw:items-center tw:justify-center tw:rounded-lg
      tw:bg-frame-logo tw:text-[12px] tw:font-bold tw:text-frame-on-logo
    ].freeze

    SEARCH = %w[
      tw:mx-3 tw:mb-2.5 tw:mt-1 tw:flex tw:h-8 tw:max-lg:h-10 tw:items-center tw:gap-2 tw:rounded-full tw:border-0 tw:px-3
      tw:bg-frame-input tw:text-[12px] tw:max-lg:text-[14px] tw:text-frame-muted tw:no-underline tw:cursor-pointer tw:text-left
      tw:hover:bg-frame-hover tw:hover:text-frame-ink tw:hover:no-underline
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-0 tw:focus-visible:outline-white
    ].freeze
    SEARCH_HINT = "tw:ml-auto tw:text-[11px] tw:text-frame-muted tw:max-lg:hidden tw:[@media(hover:none)]:hidden"

    SCROLL = "tw:relative tw:flex-1 tw:min-h-0 tw:overflow-y-auto tw:overscroll-contain tw:pb-2 tw:[scrollbar-width:thin] tw:[scrollbar-color:#3a3a3a_transparent]"
    SECTION = "tw:flex tw:flex-col tw:gap-px tw:px-2 tw:py-0.5"
    SECTION_TITLE = %w[
      tw:flex tw:items-center tw:justify-between tw:px-2.5 tw:pt-2 tw:pb-1 tw:text-[12px] tw:font-semibold
      tw:text-frame-muted tw:no-underline tw:hover:no-underline
    ].freeze
    SECTION_TITLE_LINK = "tw:rounded-full tw:hover:bg-frame-hover tw:hover:text-frame-ink tw:focus-visible:outline-2 tw:focus-visible:outline-white"
    DIVIDER = "tw:mx-3 tw:my-2 tw:h-px tw:border-0 tw:bg-frame-border"

    ITEM = %w[
      tw:flex tw:min-h-8 tw:max-lg:min-h-10 tw:items-center tw:justify-between tw:gap-2 tw:rounded-full tw:px-2.5 tw:py-1.5
      tw:text-[13px] tw:max-lg:text-[14px] tw:no-underline tw:hover:no-underline
      tw:transition-colors tw:duration-100
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-white
    ].freeze
    ITEM_IDLE = "tw:text-frame-muted tw:hover:bg-frame-hover tw:hover:text-frame-ink"
    ITEM_ACTIVE = "tw:bg-frame-active tw:text-white tw:font-medium tw:hover:bg-frame-active"
    ITEM_OPEN = "tw:text-frame-ink tw:font-medium tw:hover:bg-frame-hover"
    ITEM_LEFT = "tw:flex tw:min-w-0 tw:items-center tw:gap-2.5"
    ITEM_LABEL = "tw:truncate"
    SUB_ITEM = "tw:pl-[38px] tw:text-[12.5px] tw:max-lg:text-[13.5px]"
    COUNT = "tw:shrink-0 tw:text-[11px] tw:tabular-nums tw:text-frame-muted"
    COUNT_ACTIVE = "tw:shrink-0 tw:text-[11px] tw:tabular-nums tw:text-frame-ink"

    FOOTER = "tw:border-t tw:border-frame-border tw:px-2 tw:pt-2 tw:pb-[max(8px,env(safe-area-inset-bottom))]"
    STORE = "tw:flex tw:items-center tw:gap-1 tw:pt-1"
    STORE_LINK = %w[
      tw:flex tw:min-w-0 tw:flex-1 tw:items-center tw:gap-2 tw:rounded-full tw:px-2 tw:py-1.5 tw:max-lg:py-2
      tw:text-frame-ink tw:no-underline tw:hover:no-underline tw:hover:bg-frame-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-white
    ].freeze
    STORE_AVATAR = "tw:inline-flex tw:size-6 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-md tw:bg-frame-logo tw:text-[11px] tw:font-bold tw:text-frame-on-logo"
    STORE_NAME = "tw:truncate tw:text-[13px] tw:font-medium"
    STORE_BADGE = "tw:shrink-0 tw:rounded-full tw:bg-frame-active tw:px-1.5 tw:py-px tw:text-[11px] tw:font-medium tw:text-frame-ink"

    ICON_SVG = { viewBox: "0 0 20 20", width: 18, height: 18, fill: "none", stroke: "currentColor",
                 "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round",
                 class: "tw:shrink-0", aria: { hidden: true }, focusable: "false" }.freeze

    # Thin-stroke line icons from the reference preview.
    ICONS = {
      home: '<path d="M3 9.5 10 3l7 6.5"/><path d="M5 8.5V17h10V8.5"/>',
      orders: '<rect x="3" y="7" width="14" height="10" rx="2"/><path d="M7 7V5a3 3 0 0 1 6 0v2"/>',
      products: '<rect x="3" y="4" width="14" height="13" rx="2"/><path d="M3 8h14"/>',
      customers: '<circle cx="10" cy="7" r="3"/><path d="M4 17c0-3 2.5-5 6-5s6 2 6 5"/>',
      growth: '<path d="M3 17 8 10l3 3 6-7"/><path d="M12 6h5v5"/>',
      marketing: '<path d="M3 17 8 10l3 3 6-7"/><path d="M12 6h5v5"/>',
      discounts: '<path d="M4 10 10 4l6 6-6 6-6-6Z"/>',
      content: '<rect x="4" y="3" width="12" height="14" rx="1.5"/><path d="M7 7h6M7 10h6M7 13h3"/>',
      markets: '<circle cx="10" cy="10" r="7"/><path d="M10 3v14M3 10h14"/>',
      finance: '<rect x="4" y="9" width="3" height="7" rx="1"/><rect x="8.5" y="5" width="3" height="11" rx="1"/><rect x="13" y="12" width="3" height="4" rx="1"/>',
      analytics: '<path d="M3 17V7M8 17V3M13 17v-9M18 17V9"/>',
      online_store: '<path d="M3 7.5 4.5 4h11L17 7.5"/><path d="M3 7.5a2.3 2.3 0 0 0 4.7 0 2.3 2.3 0 0 0 4.6 0 2.3 2.3 0 0 0 4.7 0"/><path d="M4.5 10.5V16h11v-5.5"/>',
      apps: '<rect x="3.5" y="3.5" width="5" height="5" rx="1.2"/><rect x="11.5" y="3.5" width="5" height="5" rx="1.2"/><rect x="3.5" y="11.5" width="5" height="5" rx="1.2"/><rect x="11.5" y="11.5" width="5" height="5" rx="1.2"/>',
      settings: '<circle cx="10" cy="10" r="2.5"/><path d="M10 2.5v2M10 15.5v2M2.5 10h2M15.5 10h2M4.7 4.7l1.4 1.4M13.9 13.9l1.4 1.4M4.7 15.3l1.4-1.4M13.9 6.1l1.4-1.4"/>',
      search: '<circle cx="8.5" cy="8.5" r="5.5"/><path d="m16 16-3.5-3.5"/>',
      bell: '<path d="M5.5 13.5V9a4.5 4.5 0 0 1 9 0v4.5l1.5 1.5H4z"/><path d="M8.5 17.5h3"/>',
      menu: '<path d="M3.5 6h13M3.5 10h13M3.5 14h13"/>',
      close: '<path d="m5 5 10 10M15 5 5 15"/>',
      chevron: '<path d="m8 5 5 5-5 5"/>'
    }.freeze

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiSidebar) return; window.__suiSidebar = true;
        var desktop = window.matchMedia('(min-width: 64rem)');
        function setOpen(root, open, restore) {
          if (!root) return;
          var toggle = root.querySelector('[data-sui-sidebar-toggle]');
          if (open) { root.setAttribute('data-open', ''); document.documentElement.style.overflow = 'hidden';
            var close = root.querySelector('[data-sui-sidebar-close]'); if (close) close.focus(); }
          else if (root.hasAttribute('data-open')) { root.removeAttribute('data-open'); document.documentElement.style.overflow = '';
            if (restore && toggle) toggle.focus(); }
          if (toggle) toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        }
        document.addEventListener('click', function (event) {
          var t = event.target.closest('[data-sui-sidebar-toggle], [data-sui-sidebar-close], [data-sui-sidebar-backdrop], [data-sui-sidebar] nav a');
          if (!t) return;
          var root = t.closest('[data-sui-sidebar]');
          if (t.hasAttribute('data-sui-sidebar-toggle')) setOpen(root, !root.hasAttribute('data-open'), false);
          else if (!desktop.matches) setOpen(root, false, !t.matches('a'));
        });
        document.addEventListener('keydown', function (event) {
          if (event.key === 'Escape') document.querySelectorAll('[data-sui-sidebar][data-open]').forEach(function (r) { setOpen(r, false, true); });
          if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
            var search = document.querySelector('[data-sui-sidebar-search]');
            if (search) { event.preventDefault(); search.click(); }
          }
        });
        desktop.addEventListener('change', function (e) {
          if (e.matches) document.querySelectorAll('[data-sui-sidebar][data-open]').forEach(function (r) { setOpen(r, false, false); });
        });
      })();
    JS

    def initialize(sections:, footer_items: [], store: nil, search: { placeholder: "Search" },
                   label: "Main navigation", id: "sui-sidebar", contained: false, **html_attributes)
      @sections = Array(sections).map { |s| s.to_h.symbolize_keys }
      @footer_items = Array(footer_items).map { |i| i.to_h.symbolize_keys }
      @store = store&.to_h&.symbolize_keys
      @search = search ? { placeholder: "Search" }.merge(search.to_h.symbolize_keys) : nil
      @label = label
      @id = id
      @layout = contained ? :contained : :viewport
      @html_attributes = html_attributes
    end

    private

    def root_attributes
      @html_attributes.merge(class: [ ROOT, ROOT_LAYOUTS[@layout], @html_attributes[:class] ].compact.join(" "),
                             data: { sui_sidebar: "" }.merge(@html_attributes[:data] || {}))
    end

    def icon(name_or_svg, size: 18)
      return if name_or_svg.blank?

      inner = name_or_svg.is_a?(Symbol) || ICONS.key?(name_or_svg.to_s.to_sym) ? ICONS[name_or_svg.to_sym] : nil
      return name_or_svg if inner.nil? # caller passed their own html_safe <svg>

      tag.svg(inner.html_safe, **ICON_SVG, width: size, height: size)
    end

    def logo
      brand? ? brand : tag.span("S", class: LOGO.join(" "), aria: { hidden: true })
    end

    def search_tag(mobile: false)
      return unless @search

      label = @search[:placeholder]
      if mobile
        attrs = { class: ICON_BUTTON.join(" "), aria: { label: label } }
        return @search[:href] ? tag.a(icon(:search), href: @search[:href], **attrs) : tag.button(icon(:search), type: "button", **attrs)
      end

      body = safe_join([ icon(:search, size: 14), tag.span(label), tag.kbd("Ctrl K", class: SEARCH_HINT) ])
      attrs = { class: SEARCH.join(" "), data: { sui_sidebar_search: "" } }
      @search[:href] ? tag.a(body, href: @search[:href], **attrs) : tag.button(body, type: "button", **attrs)
    end

    def open?(item)
      Array(item[:children]).any? { |c| c[:active] }
    end

    def item_tag(item, sub: false)
      active = item[:active]
      state = if active then ITEM_ACTIVE
              elsif !sub && open?(item) then ITEM_OPEN
              else ITEM_IDLE
              end
      left = tag.span(safe_join([ (icon(item[:icon]) unless sub), tag.span(item[:label], class: ITEM_LABEL) ].compact), class: ITEM_LEFT)
      count = tag.span(item[:count], class: active ? COUNT_ACTIVE : COUNT) if item[:count].present?
      tag.a(safe_join([ left, count ].compact), href: item[:href] || "#",
            class: [ ITEM, state, (SUB_ITEM if sub) ].flatten.join(" "),
            aria: { current: (active ? "page" : nil) })
    end

    def items_tag(items)
      safe_join(items.map do |raw|
        item = raw.to_h.symbolize_keys
        children = Array(item[:children]).map { |c| c.to_h.symbolize_keys }
        expanded = item[:active] || open?(item)
        sub = expanded && children.any? ? safe_join(children.map { |c| item_tag(c, sub: true) }) : nil
        safe_join([ item_tag(item), sub ].compact)
      end)
    end

    def section_title(section)
      return if section[:title].blank?

      if section[:title_href]
        tag.a(safe_join([ tag.span(section[:title]), icon(:chevron, size: 14) ]), href: section[:title_href],
              class: [ SECTION_TITLE, SECTION_TITLE_LINK ].flatten.join(" "))
      else
        tag.div(section[:title], class: SECTION_TITLE.join(" "))
      end
    end

    def store_tag
      return unless @store

      initial = @store[:name].to_s.strip[0].to_s.upcase
      body = safe_join([ tag.span(initial, class: STORE_AVATAR, aria: { hidden: true }),
                         tag.span(@store[:name], class: STORE_NAME),
                         (tag.span(@store[:badge], class: STORE_BADGE) if @store[:badge].present?) ].compact)
      bell = if @store[:notifications_href]
               tag.a(icon(:bell), href: @store[:notifications_href], class: ICON_BUTTON.join(" "), aria: { label: "Notifications" })
             end
      tag.div(safe_join([ tag.a(body, href: @store[:href] || "#", class: STORE_LINK.join(" ")), bell ].compact), class: STORE)
    end
  end
end
