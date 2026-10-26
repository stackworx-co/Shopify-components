# frozen_string_literal: true

module ShopifyUI
  class ButtonComponent < ViewComponent::Base
    strip_trailing_whitespace

    BASE = %w[
      tw:box-border tw:inline-flex tw:items-center tw:justify-center tw:gap-1.5 tw:max-w-full
      tw:rounded-full tw:border tw:font-sans tw:text-center tw:leading-none tw:whitespace-nowrap
      tw:max-sm:leading-tight tw:max-sm:whitespace-normal
      tw:select-none tw:appearance-none tw:no-underline tw:hover:no-underline
      tw:transition-colors tw:duration-100
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    # Polaris 2: secondary is a borderless grey fill; :page is the white, softly shadowed
    # button used in page headers; tertiary is transparent until hovered.
    VARIANTS = {
      secondary: %w[
        tw:border-transparent tw:bg-button tw:text-ink tw:font-medium
        tw:hover:bg-button-hover tw:hover:text-ink tw:active:bg-button-active
      ],
      page: %w[
        tw:border-transparent tw:bg-surface tw:text-ink tw:font-medium tw:shadow-page-button
        tw:hover:bg-surface-hover tw:hover:text-ink tw:active:bg-surface-sunken
      ],
      primary: %w[
        tw:border-transparent tw:bg-accent tw:text-on-accent tw:font-medium tw:shadow-button-primary
        tw:hover:bg-accent-hover tw:hover:text-on-accent-hover
      ],
      tertiary: %w[
        tw:border-transparent tw:bg-transparent tw:text-ink tw:font-medium
        tw:hover:bg-fill-transparent-hover tw:hover:text-ink
        tw:active:bg-fill-transparent-active
      ],
      critical: %w[
        tw:border-transparent tw:bg-danger-fill tw:text-white tw:font-medium tw:shadow-button-critical
        tw:hover:bg-danger-fill-hover tw:hover:text-white
      ],
      plain: %w[
        tw:border-transparent tw:bg-transparent tw:text-link tw:font-medium
        tw:hover:text-link-hover tw:hover:underline
      ]
    }.freeze

    TEXT_SIZES = {
      slim: "tw:text-[12px]",
      medium: "tw:text-[12px]",
      large: "tw:text-[13px]"
    }.freeze

    TOUCH_HEIGHTS = {
      slim: "tw:max-sm:min-h-9",
      medium: "tw:max-sm:min-h-10",
      large: "tw:max-sm:min-h-11"
    }.freeze

    BOX_SIZES = {
      slim: %w[tw:h-7 tw:px-3 tw:max-sm:py-1.5],
      medium: %w[tw:h-[30px] tw:px-4 tw:max-sm:py-2],
      large: %w[tw:h-9 tw:px-4 tw:max-sm:py-2.5]
    }.freeze

    BOX_MOBILE = "tw:max-sm:h-auto"

    WIDTHS = {
      true => "tw:w-full",
      mobile: "tw:w-full tw:sm:w-auto"
    }.freeze

    DISABLED = %w[tw:cursor-not-allowed tw:pointer-events-none tw:text-disabled].freeze
    DISABLED_FILL = %w[tw:border-transparent tw:bg-[rgba(0,0,0,.03)] tw:font-medium tw:shadow-none].freeze
    DISABLED_PLAIN = %w[tw:border-transparent].freeze

    def initialize(variant: :secondary, size: :medium, href: nil, type: "button",
                   disabled: false, full_width: false, **html_attributes)
      @variant = pick(variant, VARIANTS, :secondary)
      @size = pick(size, TEXT_SIZES, :medium)
      @href = href
      @type = type
      @disabled = disabled
      @full_width = full_width
      @html_attributes = html_attributes
    end

    private

    def link?
      @href.present?
    end

    def plain?
      @variant == :plain
    end

    def base_attributes
      @html_attributes.merge(class: classes)
    end

    def link_attributes
      return base_attributes.merge(href: @href) unless @disabled

      base_attributes.merge(
        aria: (@html_attributes[:aria] || {}).merge(disabled: true),
        tabindex: -1,
        role: "link"
      )
    end

    def button_attributes
      base_attributes.merge(type: @type, disabled: @disabled || nil)
    end

    def classes
      [ BASE, size_classes, state_classes, WIDTHS[@full_width], @html_attributes[:class] ]
        .flatten.compact.join(" ")
    end

    def size_classes
      box = plain? ? [] : [ BOX_SIZES[@size], BOX_MOBILE ]
      [ TEXT_SIZES[@size], TOUCH_HEIGHTS[@size], *box ]
    end

    def state_classes
      return [ VARIANTS[@variant], "tw:cursor-pointer" ] unless @disabled

      [ DISABLED, plain? ? DISABLED_PLAIN : DISABLED_FILL ]
    end

    def pick(value, options, default)
      key = value&.to_sym
      options.key?(key) ? key : default
    end
  end
end
