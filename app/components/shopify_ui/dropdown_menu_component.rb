# frozen_string_literal: true

module ShopifyUI
  class DropdownMenuComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_many :items, types: {
      action: { renders: ->(**options, &block) { action_item(**options, &block) }, as: :action },
      heading: { renders: ->(title) { tag.p(title, class: HEADING) }, as: :heading },
      divider: { renders: -> { tag.hr(class: DIVIDER) }, as: :divider }
    }

    MENU = %w[
      tw:m-0 tw:min-w-[min(180px,calc(100vw-16px))] tw:max-w-[min(320px,calc(100vw-16px))] tw:max-h-[min(420px,calc(100dvh-16px))] tw:overflow-y-auto tw:overscroll-contain
      tw:rounded-[12px] tw:border-0 tw:bg-surface tw:p-1.5 tw:font-sans tw:text-ink
      tw:shadow-[0_4px_6px_-2px_rgba(26,26,26,.2),0_0_0_1px_rgba(0,0,0,.08)]
    ].freeze

    ITEM = %w[
      tw:flex tw:w-full tw:items-start tw:gap-2 tw:rounded-[8px] tw:border-0 tw:bg-transparent
      tw:px-2 tw:py-1.5 tw:text-left tw:font-sans tw:text-[13px] tw:leading-5 tw:no-underline
      tw:cursor-pointer tw:hover:no-underline tw:max-sm:py-2.5 tw:max-sm:text-[15px]
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    ITEM_TONES = {
      default: "tw:text-ink tw:hover:bg-surface-hover tw:hover:text-ink tw:active:bg-surface-sunken",
      destructive: "tw:text-danger tw:hover:bg-danger-light tw:hover:text-danger",
      disabled: "tw:text-disabled tw:cursor-not-allowed tw:pointer-events-none"
    }.freeze

    ICON = "tw:inline-flex tw:size-5 tw:shrink-0 tw:items-center tw:justify-center"
    HELP_TEXT = "tw:block tw:text-[12px] tw:text-muted"
    HEADING = "tw:m-0 tw:px-2 tw:pt-2 tw:pb-1 tw:text-[12px] tw:font-medium tw:text-muted"
    DIVIDER = "tw:-mx-1.5 tw:my-1.5 tw:border-0 tw:border-t tw:border-border"

    ICON_TRIGGER = %w[
      tw:inline-flex tw:size-8 tw:items-center tw:justify-center tw:rounded-full tw:border-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:transition-colors tw:duration-100
      tw:hover:bg-fill-tertiary tw:hover:text-ink tw:active:bg-fill-tertiary-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    CHEVRON = "tw:size-4 tw:shrink-0 tw:-mr-1"

    def initialize(label: nil, icon: nil, icon_label: "More actions", variant: :secondary, size: :medium,
                   align: :start, **html_attributes)
      @label = label
      @icon = icon
      @icon_label = icon_label
      @variant = variant
      @size = size
      @align = align == :end ? "end" : "start"
      @html_attributes = html_attributes
      @menu_id = "sui-menu-#{SecureRandom.hex(4)}"
    end

    private

    def action_item(href: nil, icon: nil, help_text: nil, destructive: false, disabled: false, **attributes, &block)
      body = safe_join([
        (tag.span(icon, class: ICON, aria: { hidden: true }) if icon),
        tag.span { safe_join([ capture(&block), (tag.span(help_text, class: HELP_TEXT) if help_text) ]) }
      ].compact)

      options = attributes.merge(class: item_classes(destructive, disabled), role: "menuitem")
      return tag.a(body, **options, href: href, aria: { disabled: disabled || nil }) if href

      tag.button(body, **options, type: "button", disabled: disabled || nil)
    end

    def item_classes(destructive, disabled)
      tone = if disabled then :disabled elsif destructive then :destructive else :default end
      [ ITEM, ITEM_TONES[tone] ].flatten.join(" ")
    end

    def icon_trigger?
      @label.blank?
    end

    def trigger_attributes
      { popovertarget: @menu_id, aria: { haspopup: "menu", label: (@icon_label if icon_trigger?) } }
    end

    def menu_attributes
      @html_attributes.merge(
        id: @menu_id,
        popover: "auto",
        role: "menu",
        class: [ MENU, @html_attributes[:class] ].flatten.compact.join(" "),
        data: { align: @align },
        onbeforetoggle: "if (event.newState === 'open') this.style.visibility = 'hidden'",
        ontoggle: position_script,
        onclick: "if (event.target.closest('a, button')) this.hidePopover()"
      )
    end

    def position_script
      "if (event.newState !== 'open') return;" \
        "var r = document.querySelector('[popovertarget=\"' + this.id + '\"]').getBoundingClientRect();" \
        "var left = this.dataset.align === 'end' ? r.right - this.offsetWidth : r.left;" \
        "this.style.left = Math.max(8, Math.min(left, innerWidth - this.offsetWidth - 8)) + 'px';" \
        "this.style.top = (r.bottom + 4) + 'px';" \
        "this.style.right = this.style.bottom = 'auto';" \
        "this.style.visibility = '';"
    end
  end
end
