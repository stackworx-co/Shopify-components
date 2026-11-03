# frozen_string_literal: true

module ShopifyUI
  # Shopify admin tooltip: dark #303030 bubble, white 12px text, small arrow, short fade-in, no shadow.
  #
  #   <%= render ShopifyUI::TooltipComponent.new(text: "Stock last synced 5 minutes ago", position: :top) do %>
  #     <%= render ShopifyUI::ButtonComponent.new { "Sync" } %>
  #   <% end %>
  #
  #   Rich text: render(ShopifyUI::TooltipComponent.new) { |t| t.with_tip { "<b>Bold</b> tip".html_safe }; trigger }
  #
  # The block is the trigger (icon, button, text). Shows on hover (after `delay:` ms) and on keyboard
  # focus (at once), closes on Esc, pointer leave or blur, and stays open while the pointer is over the
  # bubble. On touch screens a tap shows it and a tap anywhere else hides it.
  # The bubble sits in the top layer (Popover API), so overflow / transform / z-index can't clip it;
  # it flips to the opposite side, then the other axis, when the preferred side has no room, and is
  # kept 8px inside the viewport with the arrow still pointing at the trigger.
  # The first focusable element in the trigger gets aria-describedby; a plain-text trigger is made focusable.
  #
  # Variants: shortcut ("Bold ⌘B"), underline (definition text), truncate (only when "…" clips it),
  # disabled_trigger (explain a disabled button), persist_on_click, open (shown on load).
  class TooltipComponent < ViewComponent::Base
    strip_trailing_whitespace

    # Rich content for the bubble, instead of `text:`.
    renders_one :tip

    POSITIONS = %w[top bottom left right].freeze

    # Shared dark tooltip look — every hover card in the gem (TooltipComponent, LineChart's data card,
    # StatsCard's sparkline tip) uses these so they stay identical.
    DARK_BG = "tw:bg-[#303030]"
    DARK = "#{DARK_BG} tw:text-white tw:shadow-none tw:rounded-[8px]".freeze
    DARK_SECONDARY = "tw:text-white/70"

    ROOT = "tw:inline-flex tw:max-w-full tw:align-middle"
    BLOCK_ROOT = "tw:flex tw:w-full"

    # popover="manual" UA styles (inset 0, margin auto, border, padding, overflow) are reset here.
    BUBBLE = %w[
      tw:fixed tw:inset-auto tw:m-0 tw:overflow-visible tw:border-0 tw:p-0 tw:bg-transparent
      tw:pointer-events-auto tw:opacity-0 tw:transition-opacity tw:duration-150 tw:ease-out
      tw:data-show:opacity-100 tw:motion-reduce:transition-none
    ].freeze
    BODY = %w[
      tw:relative tw:block tw:px-2 tw:py-1 tw:font-sans tw:text-[12px]
      tw:font-medium tw:leading-4 tw:break-words tw:text-left
      tw:max-sm:text-[13px] tw:max-sm:leading-5 tw:max-sm:px-2.5 tw:max-sm:py-1.5
    ].push(DARK).freeze
    WIDTHS = {
      default: "tw:w-max tw:max-w-[min(200px,calc(100vw-16px))]",
      wide: "tw:w-max tw:max-w-[min(320px,calc(100vw-16px))]"
    }.freeze
    ARROW = "tw:absolute tw:size-2 tw:rotate-45 #{DARK_BG}".freeze
    SHORTCUT = "tw:ml-2 tw:inline-flex tw:gap-0.5 tw:align-baseline"
    KBD = %w[
      tw:inline-flex tw:min-w-4 tw:justify-center tw:rounded-[4px] tw:bg-white/15 tw:px-1 tw:font-sans
      tw:text-[11px] tw:font-medium tw:leading-4 tw:text-white/80
    ].join(" ").freeze

    UNDERLINE = "tw:cursor-help tw:underline tw:decoration-dotted tw:decoration-faint tw:underline-offset-4"
    TRUNCATE_ROOT = "tw:inline-flex tw:min-w-0 tw:align-middle"
    TRUNCATE = "tw:block tw:min-w-0 tw:truncate"
    # Disabled controls don't get pointer events or focus, so the wrapper stands in for them.
    DISABLED_TRIGGER = %w[
      tw:cursor-not-allowed tw:rounded-[8px] tw:[&>*:not([role=tooltip])]:pointer-events-none
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
    ].freeze

    # One delegated listener set for every tooltip on the page.
    # A tip with data-pinned (clicked with persist_on_click, opened on load, or tapped on touch) ignores
    # pointer-leave / blur and closes on Esc, an outside click, or a second click on its trigger.
    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiTooltip) return; window.__suiTooltip = true;
        var G = 8, GAP = 6, timers = new WeakMap(), OPEN = '[data-sui-tooltip] > [role=tooltip][data-show]';
        var FOCUSABLE = 'a[href], button, input, select, textarea, summary, [tabindex]:not([tabindex="-1"])';
        function set(el, p, v) { el.style.setProperty(p, v, 'important'); }
        function rootOf(el) { return el && el.closest ? el.closest('[data-sui-tooltip]') : null; }
        function tipOf(root) { return root.querySelector(':scope > [role=tooltip]'); }
        function clear(root) { clearTimeout(timers.get(root)); timers.delete(root); }
        function init() {
          document.querySelectorAll('[data-sui-tooltip]:not([data-sui-ready])').forEach(function (root) {
            root.setAttribute('data-sui-ready', '');
            var tip = tipOf(root), target = null;
            if (!root.hasAttribute('data-truncate')) {
              if (!root.hasAttribute('data-disabled-trigger')) {
                for (var n = root.firstElementChild; n && !target; n = n.nextElementSibling) {
                  if (n !== tip) target = n.matches(FOCUSABLE) ? n : n.querySelector(FOCUSABLE);
                }
              }
              if (!target) { target = root; root.tabIndex = 0; }
              var ids = (target.getAttribute('aria-describedby') || '').split(' ').filter(Boolean);
              if (ids.indexOf(tip.id) < 0) target.setAttribute('aria-describedby', ids.concat(tip.id).join(' '));
            }
            if (root.hasAttribute('data-open')) { tip.setAttribute('data-pinned', ''); show(root); }
          });
        }
        function place(root, tip) {
          var r = root.getBoundingClientRect(), w = tip.offsetWidth, h = tip.offsetHeight, vw = innerWidth, vh = innerHeight;
          var want = root.dataset.position, opp = { top: 'bottom', bottom: 'top', left: 'right', right: 'left' };
          var room = { top: r.top - GAP - G, bottom: vh - r.bottom - GAP - G, left: r.left - GAP - G, right: vw - r.right - GAP - G };
          var order = [want, opp[want]].concat(want === 'top' || want === 'bottom' ? ['right', 'left'] : ['top', 'bottom']);
          var side = order.find(function (s) { return room[s] >= (s === 'top' || s === 'bottom' ? h : w); });
          if (!side) side = order.reduce(function (a, b) { return room[b] > room[a] ? b : a; });
          var top, left;
          if (side === 'top' || side === 'bottom') {
            top = side === 'top' ? r.top - GAP - h : r.bottom + GAP;
            left = Math.max(G, Math.min(r.left + r.width / 2 - w / 2, vw - w - G));
          } else {
            left = side === 'left' ? r.left - GAP - w : r.right + GAP;
            top = Math.max(G, Math.min(r.top + r.height / 2 - h / 2, vh - h - G));
          }
          set(tip, 'top', Math.round(top) + 'px'); set(tip, 'left', Math.round(left) + 'px');
          tip.dataset.side = side;
          var a = tip.querySelector('[data-arrow]');
          ['top', 'left', 'right', 'bottom'].forEach(function (p) { a.style.removeProperty(p); });
          if (side === 'top' || side === 'bottom') {
            set(a, 'left', Math.max(8, Math.min(r.left + r.width / 2 - left, w - 8)) - 4 + 'px');
            set(a, side === 'top' ? 'bottom' : 'top', '-4px');
          } else {
            set(a, 'top', Math.max(8, Math.min(r.top + r.height / 2 - top, h - 8)) - 4 + 'px');
            set(a, side === 'left' ? 'right' : 'left', '-4px');
          }
        }
        function truncated(root) {
          var el = root.querySelector('[data-sui-truncate]');
          return !el || el.scrollWidth > el.clientWidth + 1;
        }
        function show(root) {
          clear(root); var tip = tipOf(root);
          if (!tip || tip.hasAttribute('data-show')) return;
          if (root.hasAttribute('data-truncate') && !truncated(root)) { tip.removeAttribute('data-pinned'); return; }
          document.querySelectorAll(OPEN + ':not([data-pinned])').forEach(function (t) { if (t !== tip) hide(t.parentElement); });
          if (tip.showPopover) { try { tip.showPopover(); } catch (e) {} } else tip.hidden = false;
          place(root, tip);
          requestAnimationFrame(function () { tip.setAttribute('data-show', ''); });
        }
        function hide(root, force) {
          clear(root); var tip = tipOf(root); if (!tip || (tip.hasAttribute('data-pinned') && !force)) return;
          tip.removeAttribute('data-show'); tip.removeAttribute('data-pinned');
          if (tip.hidePopover) { try { tip.hidePopover(); } catch (e) {} } else tip.hidden = true;
        }
        function hideAll() { document.querySelectorAll(OPEN).forEach(function (t) { hide(t.parentElement, true); }); }
        function later(root, fn, ms) { clear(root); timers.set(root, setTimeout(fn, ms)); }
        document.addEventListener('pointerover', function (e) {
          var root = rootOf(e.target); if (!root || e.pointerType === 'touch' || root.contains(e.relatedTarget)) return;
          var tip = tipOf(root);
          if (tip && tip.hasAttribute('data-show')) { clear(root); return; }
          later(root, function () { show(root); }, +root.dataset.delay || 0);
        });
        document.addEventListener('pointerout', function (e) {
          var root = rootOf(e.target); if (!root || e.pointerType === 'touch' || root.contains(e.relatedTarget)) return;
          later(root, function () { if (!root.matches(':focus-visible') && !root.querySelector(':focus-visible')) hide(root); }, 100);
        });
        document.addEventListener('focusin', function (e) {
          var root = rootOf(e.target); if (!root || e.target.closest('[role=tooltip]')) return;
          if (e.target.matches(':focus-visible')) show(root);
        });
        document.addEventListener('focusout', function (e) {
          var root = rootOf(e.target); if (root && !root.contains(e.relatedTarget)) hide(root);
        });
        document.addEventListener('pointerdown', function (e) {
          var root = rootOf(e.target), inTip = e.target.closest && e.target.closest('[role=tooltip]');
          document.querySelectorAll(OPEN).forEach(function (t) { if (t.parentElement !== root) hide(t.parentElement, true); });
          if (!root || inTip) return;
          var tip = tipOf(root), persist = root.hasAttribute('data-persist');
          if (persist && tip.hasAttribute('data-pinned')) { hide(root, true); return; }
          if (persist || e.pointerType === 'touch') { tip.setAttribute('data-pinned', ''); show(root); }
          else hide(root);
        });
        document.addEventListener('keydown', function (e) {
          if (e.key !== 'Escape' || !document.querySelector(OPEN)) return;
          e.preventDefault(); e.stopPropagation(); hideAll();
        }, true);
        function reflow() {
          document.querySelectorAll(OPEN).forEach(function (t) {
            var root = t.parentElement, r = root.getBoundingClientRect();
            if (!root.isConnected || r.bottom < 0 || r.top > innerHeight) hide(root, true); else place(root, t);
          });
        }
        addEventListener('scroll', reflow, { passive: true, capture: true });
        addEventListener('resize', reflow, { passive: true });
        document.addEventListener('turbo:before-cache', hideAll);
        ShopifyUI.onLoad(init);
      })();
    JS

    attr_reader :tip_id

    # text:             plain tooltip text (or use the `tip` slot for rich content)
    # position:         :top, :bottom, :left, :right — preferred side; flips when there's no room
    # delay:            hover delay in ms before showing (focus shows at once)
    # width:            :default (200px max) or :wide (320px max); never wider than the screen minus 16px
    # shortcut:         keyboard hint shown after the text, e.g. "⌘B" or %w[⌘ B]
    # underline:        dotted underline under a text trigger (Shopify's "this has a definition" style)
    # truncate:         clips the trigger text with "…" and shows the tooltip only when it's actually clipped;
    #                   `text:` defaults to the trigger text
    # disabled_trigger: the trigger is a disabled control — the wrapper takes hover and keyboard focus for it,
    #                   so the tooltip can explain why it's disabled
    # persist_on_click: a click pins the tooltip open until Esc, an outside click or a second click
    # open:             shown (and pinned) on page load, e.g. an onboarding hint
    # block:            true to make the wrapper full width (e.g. around a full-width field)
    # disabled:         true renders the trigger without a tooltip
    def initialize(text: nil, position: :top, delay: 300, width: :default, shortcut: nil, underline: false,
                   truncate: false, disabled_trigger: false, persist_on_click: false, open: false,
                   block: false, disabled: false, id: nil, **html_attributes)
      @text = text
      @position = POSITIONS.include?(position.to_s) ? position.to_s : "top"
      @delay = delay.to_i.clamp(0, 5000)
      @width = WIDTHS.fetch(width&.to_sym, WIDTHS[:default])
      @shortcut = Array(shortcut).map(&:to_s).reject(&:blank?)
      @underline = underline
      @truncate = truncate
      @disabled_trigger = disabled_trigger
      @persist = persist_on_click
      @open = open
      @block = block
      @disabled = disabled
      @html_attributes = html_attributes
      @tip_id = id || "sui-tooltip-#{SecureRandom.hex(4)}"
    end

    def call
      trigger = trigger_tag
      return trigger if @disabled || tip_content.blank?

      root = if @block then BLOCK_ROOT elsif @truncate then TRUNCATE_ROOT else ROOT end
      css = [ root, (DISABLED_TRIGGER if @disabled_trigger), @html_attributes[:class] ].flatten.compact.join(" ")
      data = { sui_tooltip: "", position: @position, delay: @delay, truncate: (true if @truncate),
               disabled_trigger: (true if @disabled_trigger), persist: (true if @persist), open: (true if @open) }
      data = data.compact.transform_values { |v| v == true ? "" : v }.merge(@html_attributes[:data] || {})
      safe_join([
        tag.span(**@html_attributes, class: css, data: data) { safe_join([ trigger, bubble ]) },
        Runtime.script(self, :tooltip, SCRIPT)
      ])
    end

    private

    def tip_content
      return tip.to_s if tip?

      @text.presence || (@truncate ? strip_tags(content.to_s).squish : "")
    end

    def trigger_tag
      return content unless @underline || @truncate

      tag.span(content, class: [ (TRUNCATE if @truncate), (UNDERLINE if @underline) ].compact.join(" "),
               data: { sui_truncate: ("" if @truncate) })
    end

    def bubble
      tag.span(id: @tip_id, role: "tooltip", popover: "manual", class: [ BUBBLE, @width ].flatten.join(" ")) do
        tag.span(class: BODY.join(" ")) do
          safe_join([ (tip? ? tip : tip_content), shortcut_tag,
                      tag.span(class: ARROW, data: { arrow: "" }, aria: { hidden: true }) ].compact)
        end
      end
    end

    def shortcut_tag
      return if @shortcut.empty?

      tag.span(safe_join(@shortcut.map { |k| tag.kbd(k, class: KBD) }), class: SHORTCUT)
    end
  end
end
