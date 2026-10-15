# frozen_string_literal: true

module ShopifyUI
  # Shopify admin tabs (Polaris Tabs / IndexFilters views).
  #
  # Covers: pill tabs (admin views: All / Unfulfilled / Unpaid…) and underline tabs, link tabs (href,
  # server-side) or panel tabs (client-side, with with_panel), counts, badges, disabled tabs, actions
  # menu on the selected tab (Rename / Duplicate / Delete view), "+" create-view button, fitted tabs
  # (equal widths), and a "More views" overflow menu on wide screens.
  # Phones: the strip scrolls sideways with snap and the selected tab is scrolled into view; tap targets
  # grow to 40px. Keyboard: ←/→/Home/End move between tabs (roving tabindex).
  class TabsComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_many :panels, ->(id:, &block) { panel_tag(id, block ? capture(&block) : nil) }

    VARIANTS = %i[pills underline].freeze

    ROOT = "tw:flex tw:min-w-0 tw:flex-col tw:font-sans"
    BAR = {
      pills: "tw:relative tw:flex tw:min-w-0 tw:items-center tw:gap-1",
      underline: "tw:relative tw:flex tw:min-w-0 tw:items-end tw:gap-1 tw:border-b tw:border-border"
    }.freeze
    LIST = %w[
      tw:flex tw:min-w-0 tw:flex-1 tw:items-center tw:gap-1 tw:overflow-x-auto tw:overscroll-x-contain
      tw:snap-x tw:snap-proximity tw:[scrollbar-width:none] tw:[&::-webkit-scrollbar]:hidden
      tw:md:overflow-x-visible
    ].freeze
    LIST_UNDERLINE = "tw:items-end tw:gap-0"
    FITTED_LIST = "tw:[&>*]:flex-1 tw:md:overflow-x-auto"

    TAB = %w[
      tw:inline-flex tw:shrink-0 tw:snap-start tw:items-center tw:justify-center tw:gap-1.5 tw:border-0 tw:bg-transparent
      tw:font-sans tw:font-medium tw:no-underline tw:whitespace-nowrap tw:cursor-pointer
      tw:transition-colors tw:duration-100 tw:hover:no-underline
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
      tw:aria-disabled:cursor-not-allowed tw:aria-disabled:text-disabled tw:aria-disabled:hover:bg-transparent
      tw:data-overflow:hidden
    ].freeze
    TAB_VARIANT = {
      pills: "tw:h-7 tw:rounded-full tw:px-3 tw:text-[12.5px] tw:max-sm:h-10 tw:max-sm:px-3.5 tw:max-sm:text-[14px] " \
             "tw:text-muted tw:hover:bg-surface-hover tw:hover:text-ink " \
             "tw:aria-selected:bg-fill-tertiary tw:aria-selected:text-ink tw:aria-[current=page]:bg-fill-tertiary tw:aria-[current=page]:text-ink",
      underline: "tw:relative tw:h-10 tw:rounded-t-control tw:px-3 tw:text-[13px] tw:max-sm:h-11 " \
                 "tw:text-muted tw:hover:text-ink tw:hover:bg-surface-hover " \
                 "tw:after:absolute tw:after:inset-x-2 tw:after:bottom-[-1px] tw:after:h-[3px] tw:after:rounded-t-full tw:after:bg-transparent " \
                 "tw:hover:after:bg-border-hover tw:aria-selected:text-ink tw:aria-selected:after:bg-accent " \
                 "tw:aria-[current=page]:text-ink tw:aria-[current=page]:after:bg-accent"
    }.freeze
    COUNT = "tw:text-[12px] tw:font-regular tw:text-muted tw:tabular-nums"
    CHEVRON = "tw:size-3.5 tw:-mr-1 tw:hidden tw:in-aria-selected:block tw:in-aria-[current=page]:block"

    ICON_BUTTON = %w[
      tw:inline-flex tw:size-7 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:hover:bg-surface-hover tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
      tw:max-sm:size-10
    ].freeze
    MORE = %w[
      tw:hidden tw:h-7 tw:shrink-0 tw:items-center tw:gap-1 tw:rounded-full tw:border-0 tw:bg-transparent tw:px-2.5
      tw:font-sans tw:text-[12.5px] tw:font-medium tw:text-muted tw:cursor-pointer tw:hover:bg-surface-hover tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
      tw:data-visible:md:inline-flex
    ].freeze

    MENU = %w[
      tw:m-0 tw:min-w-[180px] tw:max-w-[min(320px,calc(100vw-16px))] tw:max-h-[min(360px,60vh)] tw:overflow-y-auto
      tw:rounded-[12px] tw:border-0 tw:bg-surface tw:p-1.5 tw:font-sans tw:text-ink
      tw:shadow-[0_4px_6px_-2px_rgba(26,26,26,.2),0_0_0_1px_rgba(0,0,0,.08)]
    ].freeze
    MENU_ITEM = %w[
      tw:flex tw:w-full tw:items-center tw:justify-between tw:gap-3 tw:rounded-[8px] tw:border-0 tw:bg-transparent tw:px-2
      tw:py-1.5 tw:text-left tw:font-sans tw:text-[13px] tw:leading-5 tw:text-ink tw:no-underline tw:cursor-pointer
      tw:hover:bg-surface-hover tw:hover:no-underline tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2
      tw:focus-visible:outline-link tw:data-hidden:hidden tw:max-sm:py-2.5 tw:max-sm:text-[15px]
    ].freeze
    MENU_DESTRUCTIVE = "tw:text-danger tw:hover:bg-danger-light"

    PANEL = "tw:pt-4 tw:outline-none tw:focus-visible:outline-2 tw:focus-visible:outline-link tw:rounded-control"

    SCRIPT = <<~JS.squish.freeze
      (function () {
        if (window.__suiTabs) return; window.__suiTabs = true;
        function tabs(root) { return Array.prototype.slice.call(root.querySelectorAll('[data-sui-tab]')); }
        function select(root, tab, focus) {
          if (!tab || tab.getAttribute('aria-disabled') === 'true') return;
          if (root.hasAttribute('data-panels')) {
            tabs(root).forEach(function (t) {
              var on = t === tab; t.setAttribute('aria-selected', on ? 'true' : 'false'); t.tabIndex = on ? 0 : -1;
              var p = document.getElementById(t.getAttribute('aria-controls')); if (p) p.hidden = !on;
            });
            root.dispatchEvent(new CustomEvent('sui:tab-change', { bubbles: true, detail: { id: tab.getAttribute('data-sui-tab') } }));
          }
          if (focus) tab.focus();
          tab.scrollIntoView({ block: 'nearest', inline: 'nearest' });
        }
        function place(menu, anchor) {
          var r = anchor.getBoundingClientRect();
          menu.style.right = menu.style.bottom = 'auto';
          menu.style.left = Math.max(8, Math.min(r.left, innerWidth - menu.offsetWidth - 8)) + 'px';
          menu.style.top = (r.bottom + 4) + 'px';
        }
        function overflow(root) {
          var list = root.querySelector('[data-sui-tab-list]'), more = root.querySelector('[data-sui-tab-more]');
          if (!more) return;
          var all = tabs(root); all.forEach(function (t) { t.removeAttribute('data-overflow'); });
          var items = root.querySelectorAll('[data-sui-more-item]');
          items.forEach(function (i) { i.setAttribute('data-hidden', ''); });
          if (!matchMedia('(min-width: 48rem)').matches) { more.removeAttribute('data-visible'); return; }
          more.setAttribute('data-visible', '');
          var limit = list.getBoundingClientRect().right, hidden = 0;
          all.forEach(function (t, i) {
            if (t.getBoundingClientRect().right > limit + 1 && t.getAttribute('aria-selected') !== 'true' && t.getAttribute('aria-current') !== 'page') {
              t.setAttribute('data-overflow', ''); items[i].removeAttribute('data-hidden'); hidden++;
            }
          });
          if (!hidden) more.removeAttribute('data-visible');
        }
        document.addEventListener('click', function (e) {
          var item = e.target.closest('[data-sui-more-item]');
          if (item) { var root = item.closest('[data-sui-tabs]'); item.closest('[popover]').hidePopover();
            var t = root.querySelector('[data-sui-tab="' + item.getAttribute('data-sui-more-item') + '"]');
            if (t.tagName === 'A') { location.href = t.href; } else select(root, t, true); return; }
          var tab = e.target.closest('[data-sui-tab]'); if (!tab) return;
          var root = tab.closest('[data-sui-tabs]'), menu = tab.getAttribute('data-actions') && document.getElementById(tab.getAttribute('data-actions'));
          var active = tab.getAttribute('aria-selected') === 'true' || tab.getAttribute('aria-current') === 'page';
          if (tab.getAttribute('aria-disabled') === 'true') { e.preventDefault(); return; }
          if (menu && active) { e.preventDefault(); menu.togglePopover(); if (menu.matches(':popover-open')) place(menu, tab); return; }
          if (tab.tagName !== 'A') select(root, tab, false);
        });
        document.addEventListener('toggle', function (e) {
          if (e.newState === 'open' && e.target.matches && e.target.matches('[data-sui-tabs] [popover]')) {
            var anchor = document.querySelector('[popovertarget="' + e.target.id + '"]') || document.querySelector('[data-actions="' + e.target.id + '"]');
            if (anchor) place(e.target, anchor);
          }
        }, true);
        document.addEventListener('keydown', function (e) {
          var tab = e.target.closest && e.target.closest('[data-sui-tab]'); if (!tab) return;
          var root = tab.closest('[data-sui-tabs]');
          var list = tabs(root).filter(function (t) { return t.getAttribute('aria-disabled') !== 'true' && !t.hasAttribute('data-overflow'); });
          var i = list.indexOf(tab), next = null;
          if (e.key === 'ArrowRight') next = list[(i + 1) % list.length];
          else if (e.key === 'ArrowLeft') next = list[(i - 1 + list.length) % list.length];
          else if (e.key === 'Home') next = list[0];
          else if (e.key === 'End') next = list[list.length - 1];
          if (!next) return; e.preventDefault();
          if (root.hasAttribute('data-panels')) select(root, next, true); else next.focus();
        });
        function init() {
          document.querySelectorAll('[data-sui-tabs]').forEach(function (root) {
            overflow(root);
            var sel = root.querySelector('[data-sui-tab][aria-selected=true], [data-sui-tab][aria-current=page]');
            if (sel) { var l = root.querySelector('[data-sui-tab-list]'); l.scrollLeft = sel.offsetLeft - l.offsetLeft - 16; }
          });
        }
        var timer; window.addEventListener('resize', function () { clearTimeout(timer); timer = setTimeout(init, 100); });
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
      })();
    JS

    # tabs: [{ id:, label:, href:, count:, badge: { label:, tone: }, disabled:, actions: [{ label:, href:, destructive: }] }]
    # add_view: { label: "Create view", href: } adds the "+" button.
    def initialize(tabs:, selected: nil, variant: :pills, fitted: false, add_view: nil, label: "Views",
                   id: nil, **html_attributes)
      @tabs = Array(tabs).map { |t| t.to_h.symbolize_keys }.each_with_index.map { |t, i| t.merge(id: (t[:id] || "tab-#{i}").to_s) }
      @selected = (selected || @tabs.first&.dig(:id)).to_s
      @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :pills
      @fitted = fitted
      @add_view = add_view&.to_h&.symbolize_keys
      @label = label
      @id = id || "sui-tabs-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    private

    def panels_mode?
      @tabs.none? { |t| t[:href] }
    end

    def root_attributes
      @html_attributes.merge(id: @id, class: [ ROOT, @html_attributes[:class] ].compact.join(" "),
                             data: { sui_tabs: "", panels: (panels_mode? ? "" : nil) })
    end

    def list_attributes
      { role: (panels_mode? ? "tablist" : nil), "aria-label": @label, data: { sui_tab_list: "" },
        class: [ LIST, (LIST_UNDERLINE if @variant == :underline), (FITTED_LIST if @fitted) ].flatten.compact.join(" ") }
    end

    def dom_id(tab, suffix)
      "#{@id}-#{tab[:id].parameterize}-#{suffix}"
    end

    def selected?(tab)
      tab[:id] == @selected
    end

    def tab_tag(tab)
      on = selected?(tab)
      actions = Array(tab[:actions]).any? && !tab[:disabled]
      body = safe_join([
        tag.span(tab[:label]),
        (tag.span(tab[:count], class: COUNT) unless tab[:count].nil?),
        (render(BadgeComponent.new(tone: tab[:badge][:tone] || :neutral)) { tab[:badge][:label] } if tab[:badge]),
        (chevron if actions)
      ].compact)
      attrs = { class: [ TAB, TAB_VARIANT[@variant] ].flatten.join(" "), id: dom_id(tab, "tab"),
                data: { sui_tab: tab[:id], actions: (dom_id(tab, "actions") if actions) },
                aria: { disabled: (tab[:disabled] ? "true" : nil), haspopup: (actions ? "menu" : nil) } }

      if panels_mode?
        tag.button(body, type: "button", role: "tab", tabindex: on ? 0 : -1,
                   **attrs, aria: attrs[:aria].merge(selected: on.to_s, controls: dom_id(tab, "panel")))
      else
        tag.a(body, href: tab[:disabled] ? nil : tab[:href], **attrs, aria: attrs[:aria].merge(current: (on ? "page" : nil)))
      end
    end

    def chevron
      tag.svg(tag.path(d: "m6 8 4 4 4-4"), viewBox: "0 0 20 20", fill: "none", stroke: "currentColor", "stroke-width": 1.8,
              "stroke-linecap": "round", "stroke-linejoin": "round", class: CHEVRON, aria: { hidden: true })
    end

    def actions_menu(tab)
      return if Array(tab[:actions]).empty? || tab[:disabled]

      items = tab[:actions].map do |raw|
        a = raw.to_h.symbolize_keys
        css = [ MENU_ITEM, (MENU_DESTRUCTIVE if a[:destructive]) ].flatten.compact.join(" ")
        a[:href] ? tag.a(a[:label], href: a[:href], class: css, role: "menuitem") : tag.button(a[:label], type: "button", class: css, role: "menuitem", onclick: "this.closest('[popover]').hidePopover()", **(a[:attributes] || {}))
      end
      tag.div(safe_join(items), id: dom_id(tab, "actions"), popover: "auto", role: "menu", class: MENU.join(" "))
    end

    def more_tag
      return if @fitted

      menu_id = "#{@id}-more"
      button = tag.button(safe_join([ "More views", tag.svg(tag.path(d: "m6 8 4 4 4-4"), viewBox: "0 0 20 20", width: 14, height: 14, fill: "none", stroke: "currentColor", "stroke-width": 1.8) ]),
                          type: "button", class: MORE.join(" "), popovertarget: menu_id, data: { sui_tab_more: "" }, aria: { haspopup: "menu" })
      items = @tabs.map do |t|
        tag.button(safe_join([ tag.span(t[:label]), (tag.span(t[:count], class: COUNT) unless t[:count].nil?) ].compact),
                   type: "button", class: MENU_ITEM.join(" "), role: "menuitem", data: { sui_more_item: t[:id], hidden: "" })
      end
      safe_join([ button, tag.div(safe_join(items), id: menu_id, popover: "auto", role: "menu", class: MENU.join(" ")) ])
    end

    def add_tag
      return unless @add_view

      plus = tag.svg(tag.path(d: "M10 4.5v11M4.5 10h11"), viewBox: "0 0 20 20", width: 16, height: 16, fill: "none", stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round")
      label = @add_view[:label] || "Create view"
      @add_view[:href] ? tag.a(plus, href: @add_view[:href], class: ICON_BUTTON.join(" "), aria: { label: label }, title: label) :
                         tag.button(plus, type: "button", class: ICON_BUTTON.join(" "), aria: { label: label }, title: label, **(@add_view[:attributes] || {}))
    end

    def panel_tag(id, body)
      tab = @tabs.find { |t| t[:id] == id.to_s }
      return body unless tab

      tag.div(body, id: dom_id(tab, "panel"), role: "tabpanel", tabindex: 0, hidden: !selected?(tab),
              aria: { labelledby: dom_id(tab, "tab") }, class: PANEL)
    end
  end
end
