# frozen_string_literal: true

module ShopifyUI
  # Generic floating panel anchored to a trigger, like Shopify admin's Alerts / notifications popover.
  # Uses the native Popover API: light dismiss, Escape to close, top layer — no JS framework needed.
  #
  #   render(ShopifyUI::PopoverComponent.new(title: "Alerts", placement: :above)) do |p|
  #     p.with_activator(aria: { label: "Alerts" }) { bell_icon }
  #     p.with_header_action(icon: filter_icon, label: "Filter")
  #     p.with_header_action(icon: check_icon) { "Mark all as read" }
  #     "Alerts about your store and account will show here"
  #   end
  class PopoverComponent < ViewComponent::Base
    strip_trailing_whitespace

    # Custom trigger. Without one, `label:` renders a secondary Button with a chevron.
    renders_one :activator, ->(**attributes, &block) {
      classes = [ ICON_TRIGGER, attributes.delete(:class) ].flatten.compact.join(" ")
      tag.button(type: "button", **trigger_attributes.deep_merge(attributes), class: classes, &block)
    }

    # Small buttons on the right side of the title row. Pass content for a text button, or only
    # `icon:` + `label:` for an icon button.
    renders_many :header_actions, ->(icon: nil, label: nil, **attributes, &block) {
      text = block && capture(&block)
      classes = [ text.present? ? HEADER_TEXT_ACTION : HEADER_ICON_ACTION, attributes.delete(:class) ]
      tag.button(type: "button", class: classes.flatten.compact.join(" "),
                 aria: { label: (label if text.blank?) }, title: (label if text.blank?), **attributes) do
        safe_join([ (tag.span(icon, class: ACTION_ICON, aria: { hidden: true }) if icon), text ].compact)
      end
    }

    renders_one :footer

    PANEL = %w[
      tw:m-0 tw:max-w-[calc(100vw-16px)] tw:max-h-[min(560px,calc(100dvh-16px))] tw:overflow-hidden
      tw:flex-col tw:rounded-[12px] tw:border-0 tw:bg-surface tw:p-0 tw:font-sans tw:text-[13px] tw:text-ink
      tw:shadow-[0_8px_16px_-4px_rgba(26,26,26,.22),0_0_0_1px_rgba(0,0,0,.08)]
      tw:open:flex
    ].freeze

    WIDTHS = {
      small: "tw:w-[280px]",
      medium: "tw:w-[380px]",
      large: "tw:w-[480px]",
      auto: "tw:w-max tw:min-w-[180px]"
    }.freeze

    HEADER = "tw:flex tw:shrink-0 tw:items-center tw:gap-2 tw:py-2 tw:pr-2 tw:pl-3"
    TITLE = "tw:m-0 tw:mr-auto tw:truncate tw:text-[14px] tw:font-semibold tw:leading-5 tw:text-ink"
    BODY = "tw:min-h-0 tw:flex-1 tw:overflow-y-auto tw:overscroll-contain"
    BODY_PADDED = "tw:px-3 tw:pb-3"
    BODY_PADDED_NO_HEADER = "tw:p-3"
    FOOTER = "tw:shrink-0 tw:border-t tw:border-border tw:px-3 tw:py-2.5"

    # Empty / placeholder message box, as in the Alerts popover.
    EMPTY = %w[
      tw:rounded-[8px] tw:bg-surface-secondary tw:px-4 tw:py-5 tw:text-center
      tw:text-[13px] tw:leading-5 tw:text-ink-secondary
    ].freeze

    ACTION_BASE = %w[
      tw:inline-flex tw:h-7 tw:shrink-0 tw:items-center tw:justify-center tw:gap-1 tw:rounded-[8px] tw:border-0
      tw:bg-transparent tw:font-sans tw:text-[13px] tw:font-medium tw:text-muted tw:cursor-pointer
      tw:transition-colors tw:duration-100 tw:hover:bg-fill-tertiary tw:hover:text-ink tw:active:bg-fill-tertiary-hover
      tw:disabled:text-disabled tw:disabled:cursor-not-allowed tw:disabled:bg-transparent
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
    ].freeze
    HEADER_ICON_ACTION = [ ACTION_BASE, "tw:w-7" ].flatten.freeze
    HEADER_TEXT_ACTION = [ ACTION_BASE, "tw:px-1.5" ].flatten.freeze
    ACTION_ICON = "tw:inline-flex tw:size-5 tw:items-center tw:justify-center tw:[&>svg]:size-5"

    ICON_TRIGGER = %w[
      tw:inline-flex tw:size-8 tw:items-center tw:justify-center tw:rounded-[8px] tw:border-0
      tw:bg-transparent tw:text-ink-secondary tw:cursor-pointer tw:transition-colors tw:duration-100
      tw:hover:bg-fill-tertiary tw:hover:text-ink tw:active:bg-fill-tertiary-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    CHEVRON = "tw:size-4 tw:shrink-0 tw:-mr-1"

    attr_reader :popover_id

    # placement: :below, :above (each flips when there's no room)
    # align:     :start, :center, :end (relative to the trigger)
    # width:     :small, :medium, :large, :auto
    # padded:    false to let body content (lists, tables) run edge to edge
    # empty:     message shown in the grey placeholder box when no content is given
    def initialize(title: nil, label: nil, variant: :secondary, size: :medium, placement: :below,
                   align: :start, width: :medium, padded: true, empty: nil, id: nil, **html_attributes)
      @title = title
      @label = label
      @variant = variant
      @size = size
      @placement = placement.to_s == "above" ? "above" : "below"
      @align = %w[start center end].include?(align.to_s) ? align.to_s : "start"
      @width = WIDTHS.fetch(width.to_sym, WIDTHS[:medium])
      @padded = padded
      @empty = empty
      @html_attributes = html_attributes
      @popover_id = id || "sui-popover-#{SecureRandom.hex(4)}"
    end

    # Merge into any element to make it toggle this popover.
    def trigger_attributes
      { popovertarget: @popover_id, aria: { haspopup: "dialog" } }
    end

    private

    def header?
      @title.present? || header_actions?
    end

    def body_classes
      padding = if !@padded then nil elsif header? then BODY_PADDED else BODY_PADDED_NO_HEADER end
      [ BODY, padding ].compact.join(" ")
    end

    def panel_attributes
      @html_attributes.merge(
        id: @popover_id,
        popover: "auto",
        role: "dialog",
        aria: { label: @title || @label },
        class: [ PANEL, @width, @html_attributes[:class] ].flatten.compact.join(" "),
        data: { placement: @placement, align: @align },
        ontoggle: position_script,
        onclick: "if (event.target.closest('[data-popover-close]')) this.hidePopover()"
      )
    end

    # Anchors to the trigger, flips vertically when the preferred side doesn't fit and keeps
    # an 8px gutter from the viewport edges.
    def position_script
      "if (event.newState !== 'open') return;" \
        "var t = document.querySelector('[popovertarget=\"' + this.id + '\"]'); if (!t) return;" \
        "var r = t.getBoundingClientRect(), w = this.offsetWidth, h = this.offsetHeight, g = 8, gap = 6;" \
        "var a = this.dataset.align, left = a === 'end' ? r.right - w : a === 'center' ? r.left + (r.width - w) / 2 : r.left;" \
        "var below = innerHeight - r.bottom - gap, above = r.top - gap;" \
        "var up = this.dataset.placement === 'above' ? (above >= h || above > below) : (below < h && above > below);" \
        "var top = up ? r.top - gap - h : r.bottom + gap;" \
        "this.style.left = Math.max(g, Math.min(left, innerWidth - w - g)) + 'px';" \
        "this.style.top = Math.max(g, Math.min(top, innerHeight - h - g)) + 'px';" \
        "this.style.right = this.style.bottom = 'auto';"
    end
  end
end
