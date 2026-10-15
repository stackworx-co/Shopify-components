# frozen_string_literal: true

module ShopifyUI
  # Shared client runtime for the components.
  #
  # ONLOAD defines ShopifyUI.onLoad(fn): runs fn once the DOM is ready, and again after every Turbo
  # visit / frame load / stream render and whenever new elements are added to the page (AJAX,
  # Turbo Streams). Runs are batched per animation frame, and every init is idempotent.
  #
  # Runtime.script(component, key, js) prints each component's <script> only once per response,
  # so ten text fields on a page ship the text-field script once.
  module Runtime
    ONLOAD = <<~JS.squish.freeze
      (function () {
        var S = window.ShopifyUI = window.ShopifyUI || {};
        if (S.onLoad) return;
        var fns = [], queued = false;
        function runAll() { queued = false; fns.forEach(function (fn) { try { fn(); } catch (e) { console.error(e); } }); }
        function queue() { if (!queued) { queued = true; requestAnimationFrame(runAll); } }
        S.onLoad = function (fn) {
          fns.push(fn);
          if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', fn, { once: true }); else fn();
        };
        ['turbo:load', 'turbo:frame-load', 'turbo:render', 'turbo:after-stream-render'].forEach(function (ev) { document.addEventListener(ev, queue); });
        function observe() {
          new MutationObserver(function (records) {
            for (var i = 0; i < records.length; i++) {
              var added = records[i].addedNodes;
              for (var j = 0; j < added.length; j++) if (added[j].nodeType === 1 && added[j].tagName !== 'SCRIPT') { queue(); return; }
            }
          }).observe(document.documentElement, { childList: true, subtree: true });
        }
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', observe, { once: true }); else observe();
      })();
    JS

    # Wraps a component script with the shared runtime.
    def self.wrap(js)
      "#{ONLOAD}#{js}".freeze
    end

    # Emits <script> for `key` only the first time in this response. Works from components and plain views.
    def self.script(component, key, js = nil, &block)
      controller = (component.respond_to?(:helpers) ? component.helpers.controller : component.controller) rescue nil
      if controller
        emitted = controller.instance_variable_get(:@__sui_scripts) || controller.instance_variable_set(:@__sui_scripts, Set.new)
        return "".html_safe if emitted.include?(key)

        emitted << key
      end
      body = block ? component.capture(&block) : js
      block ? body : component.tag.script(body.html_safe)
    end
  end
end
