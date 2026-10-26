# frozen_string_literal: true

require "json"

module ShopifyUI
  # Shopify admin toast (Polaris / App Bridge Toast): short dark message at the bottom of the screen.
  #
  # Covers: default and error tones, optional action ("Undo", "View"), dismiss button, custom duration
  # (default 5s, 10s when there is an action, or sticky with duration: 0), stacking (newest at the
  # bottom, max 3), pause on hover / focus, swipe-down to dismiss on touch, and screen-reader
  # announcements. Desktop: centred near the bottom. Phones: full width with safe-area padding.
  #
  # From Rails (e.g. flash):  render ShopifyUI::ToastComponent.new(message: "Product saved")
  # From JavaScript:          ShopifyUI.toast("Product saved", { error: false, action: { label: "Undo", onAction: fn } })
  class ToastComponent < ViewComponent::Base
    strip_trailing_whitespace

    CLASSES = {
      region: "tw:pointer-events-none tw:fixed tw:inset-x-0 tw:bottom-0 tw:z-[1000] tw:flex tw:flex-col tw:items-center tw:gap-2 tw:px-4 tw:pb-[max(20px,env(safe-area-inset-bottom))] tw:max-sm:px-2 tw:max-sm:pb-[max(8px,env(safe-area-inset-bottom))] tw:font-sans",
      toast: "tw:pointer-events-auto tw:flex tw:max-w-[min(500px,100%)] tw:items-center tw:gap-3 tw:rounded-[12px] tw:py-2 tw:pl-3.5 tw:pr-2 tw:text-[13px] tw:font-medium tw:leading-5 tw:shadow-toast tw:transition-[opacity,translate] tw:duration-200 tw:ease-out tw:motion-reduce:transition-none tw:max-sm:w-full tw:max-sm:py-2.5",
      hidden: "tw:opacity-0 tw:translate-y-3",
      default: "tw:bg-accent tw:text-on-accent",
      error: "tw:bg-danger-fill tw:text-white",
      icon: "tw:size-5 tw:shrink-0 tw:-ml-0.5",
      message: "tw:min-w-0 tw:flex-1 tw:break-words",
      action: "tw:shrink-0 tw:rounded-control tw:border-0 tw:bg-transparent tw:px-1.5 tw:py-1 tw:font-sans tw:text-[13px] tw:font-semibold tw:text-inherit tw:underline tw:underline-offset-2 tw:cursor-pointer tw:hover:bg-[rgba(255,255,255,.12)] tw:focus-visible:outline-2 tw:focus-visible:outline-white tw:max-sm:py-2",
      close: "tw:inline-flex tw:size-7 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-control tw:border-0 tw:bg-transparent tw:p-0 tw:text-inherit tw:opacity-75 tw:cursor-pointer tw:hover:opacity-100 tw:hover:bg-[rgba(255,255,255,.12)] tw:focus-visible:outline-2 tw:focus-visible:outline-white tw:max-sm:size-9"
    }.freeze

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.ShopifyUI.toast) return;
        var C = CLASSES_JSON, MAX = 3;
        function region() {
          var r = document.getElementById('sui-toast-region');
          if (!r) { r = document.createElement('div'); r.id = 'sui-toast-region'; r.className = C.region;
            r.setAttribute('role', 'region'); r.setAttribute('aria-label', 'Notifications'); document.body.appendChild(r); }
          return r;
        }
        function svg(d, cls) {
          var s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
          s.setAttribute('viewBox', '0 0 20 20'); s.setAttribute('fill', 'none'); s.setAttribute('stroke', 'currentColor');
          s.setAttribute('stroke-width', '1.7'); s.setAttribute('stroke-linecap', 'round'); s.setAttribute('aria-hidden', 'true');
          if (cls) s.setAttribute('class', cls); else { s.setAttribute('width', '18'); s.setAttribute('height', '18'); }
          d.forEach(function (p) { var e = document.createElementNS('http://www.w3.org/2000/svg', 'path'); e.setAttribute('d', p); s.appendChild(e); });
          return s;
        }
        function dismiss(t) {
          if (t.__gone) return; t.__gone = true; clearTimeout(t.__timer);
          t.className = t.className + ' ' + C.hidden;
          setTimeout(function () { t.remove(); }, matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 200);
          if (t.__onDismiss) t.__onDismiss();
        }
        function arm(t) { clearTimeout(t.__timer); if (t.__duration > 0) t.__timer = setTimeout(function () { dismiss(t); }, t.__remaining); t.__started = Date.now(); }
        function pause(t) { if (t.__duration > 0 && t.__timer) { clearTimeout(t.__timer); t.__timer = null; t.__remaining -= Date.now() - t.__started; } }
        function toast(message, o) {
          o = o || {};
          var r = region(), t = document.createElement('div');
          t.className = [C.toast, o.error ? C.error : C['default'], C.hidden].join(' ');
          t.setAttribute('role', o.error ? 'alert' : 'status'); t.setAttribute('aria-live', o.error ? 'assertive' : 'polite');
          if (o.error) t.appendChild(svg(['M10 6.5v4', 'M10 13.5h.01', 'M10 2.5a7.5 7.5 0 1 0 0 15 7.5 7.5 0 0 0 0-15Z'], C.icon));
          var m = document.createElement('span'); m.className = C.message; m.textContent = message; t.appendChild(m);
          if (o.action && o.action.label) {
            var a = document.createElement(o.action.href ? 'a' : 'button'); a.className = C.action; a.textContent = o.action.label;
            if (o.action.href) a.href = o.action.href; else a.type = 'button';
            a.addEventListener('click', function (e) { if (o.action.onAction) o.action.onAction(e); dismiss(t); });
            t.appendChild(a);
          }
          if (o.dismissible !== false) {
            var x = document.createElement('button'); x.type = 'button'; x.className = C.close; x.setAttribute('aria-label', 'Dismiss notification');
            x.appendChild(svg(['m5.5 5.5 9 9', 'm14.5 5.5-9 9'])); x.addEventListener('click', function () { dismiss(t); }); t.appendChild(x);
          }
          t.__duration = o.duration != null ? o.duration : (o.action ? 10000 : 5000); t.__remaining = t.__duration; t.__onDismiss = o.onDismiss;
          ['mouseenter', 'focusin'].forEach(function (ev) { t.addEventListener(ev, function () { pause(t); }); });
          ['mouseleave', 'focusout'].forEach(function (ev) { t.addEventListener(ev, function () { if (!t.matches(':hover, :focus-within')) arm(t); }); });
          var y0 = null;
          t.addEventListener('touchstart', function (e) { y0 = e.touches[0].clientY; pause(t); }, { passive: true });
          t.addEventListener('touchmove', function (e) { if (y0 != null) { var dy = Math.max(0, e.touches[0].clientY - y0); t.style.translate = '0 ' + dy + 'px'; t.style.opacity = String(Math.max(0, 1 - dy / 80)); } }, { passive: true });
          t.addEventListener('touchend', function (e) { var dy = e.changedTouches[0].clientY - y0; y0 = null; t.style.translate = ''; t.style.opacity = ''; if (dy > 40) dismiss(t); else arm(t); });
          r.appendChild(t);
          var live = Array.prototype.filter.call(r.children, function (c) { return !c.__gone; });
          while (live.length > MAX) dismiss(live.shift());
          requestAnimationFrame(function () { requestAnimationFrame(function () { t.className = t.className.replace(' ' + C.hidden, ''); }); });
          arm(t);
          return { dismiss: function () { dismiss(t); } };
        }
        window.ShopifyUI = window.ShopifyUI || {}; window.ShopifyUI.toast = toast;
        function init() {
          document.querySelectorAll('script[data-sui-toast]').forEach(function (s) {
            if (s.__done) return; s.__done = true; var o = JSON.parse(s.textContent); toast(o.message, o);
          });
        }
        ShopifyUI.onLoad(init);
      })();
    JS

    # action: { label:, href: }  (JS onAction callbacks are only available from ShopifyUI.toast)
    # duration: milliseconds; 0 keeps it until dismissed.
    def initialize(message:, error: false, action: nil, duration: nil, dismissible: true)
      @options = { message: message, error: error, dismissible: dismissible,
                   action: action&.to_h&.symbolize_keys&.slice(:label, :href), duration: duration }.compact
    end

    def call
      safe_join([
        tag.script(raw(ERB::Util.json_escape(@options.to_json)), type: "application/json", data: { sui_toast: "" }),
        Runtime.script(self, :toast, self.class.script)
      ])
    end

    # The toast engine, for layouts that call ShopifyUI.toast(...) without rendering a server toast first:
    #   <%= ShopifyUI::Runtime.script(self, :toast, ShopifyUI::ToastComponent.script) %>
    def self.script
      SCRIPT.sub("CLASSES_JSON", CLASSES.to_json)
    end
  end
end
