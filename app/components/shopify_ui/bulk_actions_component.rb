# frozen_string_literal: true

module ShopifyUI
  # Shopify admin bulk actions (Polaris IndexTable BulkActions).
  #
  # Appears when rows are selected and shows: a select checkbox (checked / indeterminate, click to clear),
  # "N selected", "Select all 414 orders" across pages, promoted actions as buttons, and the rest in a
  # "…" menu (destructive items in red).
  #   variant: :inline   -> replaces the table's column-header row (use Table#with_bulk_actions).
  #   variant: :floating -> pill bar floating at the bottom of the screen (any list / grid).
  # Phones: only the first promoted action stays as a button, everything else moves into the menu;
  # the floating bar goes full width above the home indicator.
  #
  # Actions: { id:, label:, destructive:, url:, method: } — with url the selected ids are submitted
  # (ids[] / select_all) as a form with the CSRF token; every click also fires `sui:bulk-action`
  # with { action, ids, allSelected }.
  class BulkActionsComponent < ViewComponent::Base
    strip_trailing_whitespace

    VARIANTS = %i[inline floating].freeze

    ROOT = {
      inline: "tw:absolute tw:inset-x-0 tw:top-0 tw:z-10 tw:flex tw:min-h-9 tw:items-center tw:gap-2 tw:bg-surface-secondary tw:pl-3 tw:pr-2 tw:border-b tw:border-border tw:max-sm:min-h-12",
      floating: "tw:fixed tw:bottom-[max(20px,env(safe-area-inset-bottom))] tw:left-1/2 tw:z-[900] tw:flex tw:max-w-[calc(100vw-32px)] tw:-translate-x-1/2 tw:items-center tw:gap-2 tw:rounded-full tw:bg-surface tw:py-1.5 tw:pl-3.5 tw:pr-1.5 tw:shadow-[0_8px_20px_-4px_rgba(26,26,26,.28),0_0_0_1px_rgba(0,0,0,.08)] tw:max-sm:inset-x-2 tw:max-sm:bottom-[max(8px,env(safe-area-inset-bottom))] tw:max-sm:max-w-none tw:max-sm:translate-x-0 tw:max-sm:rounded-[16px] tw:max-sm:py-2"
    }.freeze
    HIDDEN = "tw:hidden"
    ROOT_BASE = "tw:font-sans tw:text-[13px] tw:text-ink tw:data-hidden:hidden"

    CHECK_WRAP = "tw:relative tw:inline-flex tw:size-4 tw:shrink-0"
    CHECK = %w[
      tw:peer tw:m-0 tw:size-4 tw:cursor-pointer tw:appearance-none tw:rounded-[4px] tw:border tw:border-input-border tw:bg-surface
      tw:checked:border-accent tw:checked:bg-accent tw:indeterminate:border-accent tw:indeterminate:bg-accent
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:size-5
    ].freeze
    CHECK_ICON = "tw:pointer-events-none tw:absolute tw:inset-0 tw:hidden tw:size-4 tw:text-on-accent tw:peer-checked:block tw:max-sm:size-5"
    DASH_ICON = "tw:pointer-events-none tw:absolute tw:inset-0 tw:hidden tw:size-4 tw:text-on-accent tw:peer-indeterminate:block tw:max-sm:size-5"

    COUNT = "tw:shrink-0 tw:whitespace-nowrap tw:text-[12.5px] tw:font-semibold tw:tabular-nums tw:max-sm:text-[14px]"
    SELECT_ALL = "tw:shrink-0 tw:whitespace-nowrap tw:border-0 tw:bg-transparent tw:p-0 tw:font-sans tw:text-[12.5px] tw:font-medium tw:text-link tw:cursor-pointer tw:hover:underline tw:focus-visible:outline-2 tw:focus-visible:outline-link tw:rounded tw:data-hidden:hidden tw:max-md:hidden"
    ACTIONS = "tw:ml-auto tw:flex tw:shrink-0 tw:items-center tw:gap-1.5"
    DESKTOP = "tw:max-md:hidden"
    MOBILE = "tw:md:hidden"
    CLEAR = %w[
      tw:inline-flex tw:size-7 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:bg-transparent tw:p-0
      tw:text-muted tw:cursor-pointer tw:hover:bg-fill-tertiary tw:hover:text-ink tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:max-sm:size-9
    ].freeze

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiBulk) return; window.__suiBulk = true;
        function scope(bar) { return document.getElementById(bar.getAttribute('data-for')) || bar.parentElement; }
        function boxes(bar) { return Array.prototype.slice.call(scope(bar).querySelectorAll('tbody input[type=checkbox]:not(:disabled), [data-sui-selectable] input[type=checkbox]:not(:disabled)')); }
        function update(bar) {
          var all = boxes(bar), on = all.filter(function (b) { return b.checked; }), n = on.length;
          if (!n) bar.removeAttribute('data-all');
          var total = parseInt(bar.getAttribute('data-total') || '0', 10), everything = bar.hasAttribute('data-all');
          bar.toggleAttribute('data-hidden', n === 0);
          var head = scope(bar).querySelector('thead'); if (head && bar.getAttribute('data-variant') === 'inline') bar.style.minHeight = head.offsetHeight + 'px';
          var cb = bar.querySelector('[data-bulk-check]'); cb.checked = n > 0 && n === all.length; cb.indeterminate = n > 0 && n < all.length;
          bar.querySelector('[data-bulk-count]').textContent = everything ? bar.getAttribute('data-all-label') : n + ' selected';
          var link = bar.querySelector('[data-bulk-select-all]');
          if (link) { link.toggleAttribute('data-hidden', !(n === all.length && total > n) && !everything);
            link.textContent = everything ? 'Undo' : bar.getAttribute('data-select-all-label'); }
          var hidden = bar.querySelector('[data-bulk-all-input]'); if (hidden) hidden.disabled = !everything;
          var headCheck = scope(bar).querySelector('thead input[type=checkbox]');
          if (headCheck) { headCheck.checked = n > 0 && n === all.length; headCheck.indeterminate = n > 0 && n < all.length; }
        }
        function bars() { return Array.prototype.slice.call(document.querySelectorAll('[data-sui-bulk]')); }
        document.addEventListener('change', function (e) {
          if (!e.target.matches || !e.target.matches('input[type=checkbox]')) return;
          bars().forEach(function (bar) { if (scope(bar).contains(e.target) && !bar.contains(e.target)) update(bar); });
        });
        document.addEventListener('click', function (e) {
          var bar = e.target.closest('[data-sui-bulk]');
          if (!bar) {
            var item = e.target.closest('[data-bulk-action]'); if (!item) return;
            bar = document.getElementById(item.closest('[data-bulk-owner]').getAttribute('data-bulk-owner'));
          }
          if (e.target.closest('[data-bulk-check], [data-bulk-clear]')) {
            boxes(bar).forEach(function (b) { b.checked = false; }); bar.removeAttribute('data-all'); update(bar);
            var first = scope(bar).querySelector('thead input[type=checkbox], tbody input[type=checkbox]'); if (first) first.focus(); return;
          }
          if (e.target.closest('[data-bulk-select-all]')) { bar.toggleAttribute('data-all'); update(bar); return; }
          var btn = e.target.closest('[data-bulk-action]'); if (!btn) return;
          var ids = boxes(bar).filter(function (b) { return b.checked; }).map(function (b) { return b.value; });
          var detail = { action: btn.getAttribute('data-bulk-action'), ids: ids, allSelected: bar.hasAttribute('data-all') };
          var ev = new CustomEvent('sui:bulk-action', { bubbles: true, cancelable: true, detail: detail });
          if (!bar.dispatchEvent(ev)) return;
          var url = btn.getAttribute('data-url'); if (!url) return;
          var f = document.createElement('form'); f.method = 'post'; f.action = url; f.hidden = true;
          function add(n, v) { var i = document.createElement('input'); i.type = 'hidden'; i.name = n; i.value = v; f.appendChild(i); }
          var m = btn.getAttribute('data-method') || 'post'; if (m !== 'post') add('_method', m);
          var t = document.querySelector('meta[name=csrf-token]'); if (t) add(document.querySelector('meta[name=csrf-param]') ? document.querySelector('meta[name=csrf-param]').content : 'authenticity_token', t.content);
          if (detail.allSelected) add('select_all', 'true'); else ids.forEach(function (id) { add(bar.getAttribute('data-param') || 'ids[]', id); });
          document.body.appendChild(f); f.submit();
        });
        function init() { bars().forEach(update); }
        ShopifyUI.onLoad(init);
      })();
    JS

    # promoted_actions: shown as buttons; actions: in the "…" menu.
    # for: id of the element containing the checkboxes (defaults to the parent element).
    # total: number of records across all pages, enables "Select all N <resource>".
    def initialize(promoted_actions: [], actions: [], variant: :inline, for: nil, total: nil,
                   resource_name: { singular: "item", plural: "items" }, param: "ids[]", id: nil, **html_attributes)
      @promoted = Array(promoted_actions).map { |a| normalize(a) }
      @actions = Array(actions).map { |a| normalize(a) }
      @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :inline
      @for = binding.local_variable_get(:for)
      @total = total
      @resource = resource_name.to_h.symbolize_keys
      @param = param
      @id = id || "sui-bulk-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    private

    def normalize(action)
      a = action.to_h.symbolize_keys
      a.merge(id: (a[:id] || a[:label].to_s.parameterize).to_s)
    end

    def root_attributes
      @html_attributes.merge(
        id: @id, role: "region", aria: { label: "Bulk actions" },
        class: [ ROOT_BASE, ROOT[@variant], @html_attributes[:class] ].compact.join(" "),
        data: { sui_bulk: "", hidden: "", variant: @variant, for: @for, total: @total, param: @param,
                select_all_label: ("Select all #{@total}+ #{@resource[:plural]}".sub("+", "") if @total),
                all_label: ("All #{@total} #{@resource[:plural]} selected" if @total) }
      )
    end

    def check_tag
      tag.span(safe_join([
        tag.input(type: "checkbox", class: CHECK.join(" "), aria: { label: "Deselect all" }, data: { bulk_check: "" }),
        tag.svg(tag.path(d: "M4.5 8.5 7 11l4.5-6"), viewBox: "0 0 16 16", fill: "none", stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round", class: CHECK_ICON, aria: { hidden: true }),
        tag.svg(tag.path(d: "M4.5 8h7"), viewBox: "0 0 16 16", fill: "none", stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", class: DASH_ICON, aria: { hidden: true })
      ]), class: CHECK_WRAP)
    end

    def action_attrs(a)
      { data: { bulk_action: a[:id], url: a[:url], method: a[:method] } }
    end

    def button_tag(a)
      render(ButtonComponent.new(size: :slim, **action_attrs(a),
                                 class: ("tw:text-danger tw:hover:text-danger" if a[:destructive]))) { a[:label] }
    end

    def menu_tag(list)
      return if list.empty?

      tag.div(data: { bulk_owner: @id }, class: "tw:contents") do
        render(DropdownMenuComponent.new(icon_label: "More actions", align: :end)) do |m|
          list.each { |a| m.with_action(destructive: a[:destructive] || false, **action_attrs(a)) { a[:label] } }
        end
      end
    end

    def clear_tag
      return unless @variant == :floating

      tag.button(tag.svg(tag.path(d: "m5.5 5.5 9 9m0-9-9 9"), viewBox: "0 0 20 20", width: 18, height: 18, fill: "none",
                         stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", aria: { hidden: true }),
                 type: "button", class: CLEAR.join(" "), aria: { label: "Clear selection" }, data: { bulk_clear: "" })
    end
  end
end
