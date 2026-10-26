# frozen_string_literal: true

module ShopifyUI
  # Shopify admin pager (Polaris Pagination).
  #   type: :table -> range label on the left, circular prev/next on the right (list/table footers).
  #   type: :page  -> centred, prev/next joined into one segmented control with the label between.
  # Optional tooltips on hover/focus, and keyboard shortcuts (e.g. previous_keys: %w[k], next_keys: %w[j]).
  class PaginationComponent < ViewComponent::Base
    strip_trailing_whitespace

    TYPES = %i[table page].freeze

    WRAPPERS = {
      table: %w[tw:flex tw:items-center tw:justify-between tw:gap-3 tw:min-w-0 tw:px-5 tw:pt-3 tw:max-sm:px-4],
      page: %w[tw:flex tw:items-center tw:justify-center tw:min-w-0 tw:max-w-full]
    }.freeze

    # Grey card footer used when the pager is attached to the bottom of a table.
    FOOTER = %w[
      tw:border-t tw:border-border-secondary tw:bg-surface-secondary
      tw:py-1.5 tw:pt-1.5 tw:px-3 tw:max-sm:px-3 tw:max-sm:py-2
    ].freeze

    LABEL = "tw:min-w-0 tw:truncate tw:text-[12.5px] tw:text-muted tw:tabular-nums"
    PAGE_LABEL = "tw:min-w-0 tw:truncate tw:px-3 tw:text-[13px] tw:text-ink tw:tabular-nums tw:max-sm:px-2"

    CONTROLS = {
      table: "tw:flex tw:shrink-0 tw:items-center tw:gap-1.5 tw:max-sm:gap-2",
      page: "tw:flex tw:min-w-0 tw:items-center"
    }.freeze

    BUTTON = %w[
      tw:relative tw:inline-flex tw:items-center tw:justify-center tw:shrink-0 tw:p-0
      tw:border tw:border-transparent tw:bg-surface tw:text-ink
      tw:appearance-none tw:no-underline tw:transition-colors tw:duration-100
      tw:focus-visible:z-10 tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    SHAPES = {
      table: "tw:size-7 tw:max-sm:size-10 tw:rounded-full tw:shadow-page-button",
      page: {
        previous: "tw:h-7 tw:w-9 tw:max-sm:h-10 tw:max-sm:w-11 tw:rounded-l-full tw:shadow-page-button",
        next: "tw:h-7 tw:w-9 tw:max-sm:h-10 tw:max-sm:w-11 tw:rounded-r-full tw:shadow-page-button"
      },
      # Segmented without a label: buttons touch, so drop the shared middle border.
      joined_next: "tw:-ml-px"
    }.freeze

    ENABLED = %w[
      tw:cursor-pointer tw:hover:z-10 tw:hover:border-border-hover tw:hover:bg-surface-hover tw:active:bg-surface-sunken
    ].freeze

    DISABLED = "tw:cursor-not-allowed tw:text-disabled"
    DISABLED_PAGE = "tw:bg-surface-secondary tw:shadow-none"

    TOOLTIP = %w[
      tw:pointer-events-none tw:absolute tw:bottom-full tw:left-1/2 tw:z-20 tw:mb-1.5 tw:-translate-x-1/2
      tw:whitespace-nowrap tw:rounded-lg tw:bg-surface tw:px-2 tw:py-1 tw:text-[12px] tw:font-medium tw:text-ink
      tw:shadow-popover
      tw:opacity-0 tw:transition-opacity tw:duration-100
      tw:group-hover:opacity-100 tw:group-focus-visible:opacity-100
      tw:max-sm:hidden
    ].freeze

    ICONS = { previous: "M12 4 6 10l6 6", next: "M8 4l6 6-6 6" }.freeze

    # Clicks the matching enabled control when a shortcut key is pressed outside a text field.
    KEYS_SCRIPT = <<~JS.squish.freeze
      if (!window.__suiPaginationKeys) { window.__suiPaginationKeys = true;
        document.addEventListener('keydown', function (event) {
          if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey) return;
          var t = event.target;
          if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return;
          var key = event.key.length === 1 ? event.key.toLowerCase() : event.key;
          document.querySelectorAll('[data-sui-pagination-keys]').forEach(function (el) {
            if (event.defaultPrevented) return;
            if (el.getAttribute('data-sui-pagination-keys').split(' ').indexOf(key) === -1) return;
            if (el.disabled || el.getAttribute('aria-disabled') === 'true') return;
            event.preventDefault(); el.click();
          });
        });
      }
    JS

    # label: e.g. "1–50". previous_url / next_url render links; otherwise pass has_previous / has_next
    # and wire the buttons up via previous_attributes / next_attributes.
    def initialize(type: :table, label: nil, footer: false,
                   previous_url: nil, next_url: nil, has_previous: nil, has_next: nil,
                   previous_label: "Previous", next_label: "Next",
                   previous_tooltip: nil, next_tooltip: nil,
                   previous_keys: [], next_keys: [],
                   previous_attributes: {}, next_attributes: {}, **html_attributes)
      @type = TYPES.include?(type&.to_sym) ? type.to_sym : :table
      @label = label
      @footer = footer && @type == :table
      @controls = {
        previous: build_control(previous_url, has_previous, previous_label, previous_tooltip, previous_keys, previous_attributes),
        next: build_control(next_url, has_next, next_label, next_tooltip, next_keys, next_attributes)
      }
      @html_attributes = html_attributes
    end

    private

    def build_control(url, enabled, aria_label, tooltip, keys, attributes)
      { url: url, enabled: enabled.nil? ? url.present? : enabled, aria_label: aria_label,
        tooltip: tooltip, keys: Array(keys).map { |k| k.to_s.length == 1 ? k.to_s.downcase : k.to_s },
        attributes: attributes }
    end

    def page?
      @type == :page
    end

    def label?
      @label.present?
    end

    def keys?
      @controls.values.any? { |c| c[:keys].any? }
    end

    def wrapper_attributes
      @html_attributes.merge(
        class: [ WRAPPERS[@type], (FOOTER if @footer), @html_attributes[:class] ].flatten.compact.join(" "),
        aria: { label: "Pagination" }.merge(@html_attributes[:aria] || {})
      )
    end

    def label_tag
      tag.span(@label, class: page? ? PAGE_LABEL : LABEL, aria: { live: "polite" }) if label?
    end

    def control(direction)
      control = @controls[direction]
      attrs = control[:attributes].merge(class: control_classes(direction, control),
                                         aria: { label: control[:aria_label] },
                                         data: control_data(control))
      body = safe_join([ icon(direction), tooltip(control) ].compact)

      if control[:url].present?
        if control[:enabled]
          tag.a(body, **attrs, href: control[:url], rel: direction == :previous ? "prev" : "next")
        else
          tag.a(body, **attrs, role: "link", tabindex: -1, aria: attrs[:aria].merge(disabled: true))
        end
      else
        tag.button(body, **attrs, type: "button", disabled: !control[:enabled] || nil)
      end
    end

    def control_classes(direction, control)
      shape = page? ? SHAPES[:page][direction] : SHAPES[:table]
      joined = SHAPES[:joined_next] if page? && direction == :next && !label?
      state = control[:enabled] ? ENABLED : [ DISABLED, (DISABLED_PAGE if page?) ]
      [ BUTTON, shape, joined, state, ("tw:group" if control[:tooltip].present?),
        control[:attributes][:class] ].flatten.compact.join(" ")
    end

    def control_data(control)
      data = control[:attributes][:data] || {}
      control[:keys].any? ? data.merge(sui_pagination_keys: control[:keys].join(" ")) : data
    end

    def tooltip(control)
      return if control[:tooltip].blank?

      tag.span(control[:tooltip], class: TOOLTIP.join(" "), aria: { hidden: true })
    end

    def icon(direction)
      tag.svg(tag.path(d: ICONS[direction]),
              viewBox: "0 0 20 20", width: 15, height: 15, fill: "none", stroke: "currentColor",
              "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round",
              aria: { hidden: true }, focusable: "false")
    end
  end
end
