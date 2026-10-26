# frozen_string_literal: true

module ShopifyUI
  # Polaris 2 text (s-text / s-heading / s-paragraph). One type scale for every page:
  #
  #   <%= render(ShopifyUI::TextComponent.new(variant: :heading_lg)) { "Customer" } %>
  #   <%= render(ShopifyUI::TextComponent.new(tone: :subdued)) { "Last updated 2 hours ago" } %>
  #   <%= render(ShopifyUI::TextComponent.new(variant: :body_sm, tone: :critical, as: :span)) { "Required" } %>
  #
  # Sizes come from the polaris-2.0.js "admin-next" theme. Like Polaris 2, text gets slightly larger on
  # phones (max-sm) so it stays readable; display-small is the one style that shrinks.
  class TextComponent < ViewComponent::Base
    strip_trailing_whitespace

    # [desktop size/line-height + weight + tracking, phone overrides]
    SCALE = {
      display_lg: "tw:text-[29px] tw:leading-9 tw:font-medium tw:tracking-[-.02em] tw:max-sm:text-[32px] tw:max-sm:leading-[38px]",
      display_md: "tw:text-[26px] tw:leading-8 tw:font-medium tw:tracking-[-.02em]",
      display_sm: "tw:text-[22px] tw:leading-7 tw:font-medium tw:tracking-[-.02em] tw:max-sm:text-[20px] tw:max-sm:leading-[26px]",
      heading_lg: "tw:text-[15px] tw:leading-[22px] tw:font-medium tw:tracking-[-.01em] tw:max-sm:text-[17px] tw:max-sm:leading-6",
      heading_md: "tw:text-[13px] tw:leading-5 tw:font-medium tw:tracking-[-.01em] tw:max-sm:text-[15px] tw:max-sm:leading-[22px]",
      heading_sm: "tw:text-[12px] tw:leading-[18px] tw:font-medium tw:tracking-[-.005em] tw:max-sm:text-[13px] tw:max-sm:leading-5",
      body_lg: "tw:text-[15px] tw:leading-[22px] tw:max-sm:text-[17px] tw:max-sm:leading-6",
      body_md: "tw:text-[13px] tw:leading-5 tw:max-sm:text-[15px] tw:max-sm:leading-[22px]",
      body_sm: "tw:text-[12px] tw:leading-[18px] tw:max-sm:text-[13px] tw:max-sm:leading-5",
      body_xs: "tw:text-[11px] tw:leading-[14px] tw:max-sm:text-[12px] tw:max-sm:leading-4"
    }.freeze

    TAGS = {
      display_lg: :h1, display_md: :h1, display_sm: :h2,
      heading_lg: :h2, heading_md: :h3, heading_sm: :h4,
      body_lg: :p, body_md: :p, body_sm: :p, body_xs: :p
    }.freeze

    TONES = {
      base: "tw:text-ink",
      subdued: "tw:text-muted",
      disabled: "tw:text-disabled",
      success: "tw:text-good",
      info: "tw:text-info",
      caution: "tw:text-warn",
      critical: "tw:text-danger",
      link: "tw:text-link",
      inherit: "tw:text-inherit"
    }.freeze

    WEIGHTS = {
      regular: "tw:font-regular",
      medium: "tw:font-medium",
      semibold: "tw:font-semibold",
      bold: "tw:font-bold"
    }.freeze

    ALIGNS = { start: "tw:text-left", center: "tw:text-center", end: "tw:text-right", justify: "tw:text-justify" }.freeze

    BASE = "tw:m-0 tw:font-sans"
    TRUNCATE = "tw:block tw:min-w-0 tw:truncate"
    BREAK = "tw:break-words tw:[overflow-wrap:anywhere]"
    NUMERIC = "tw:tabular-nums"
    HIDDEN = "tw:sr-only"

    # variant:  one of SCALE; as: tag override (:span, :div, :label, :h1…); tone: TONES; weight: WEIGHTS
    # truncate: one line with an ellipsis; numeric: tabular figures; visually_hidden: screen readers only.
    def initialize(variant: :body_md, as: nil, tone: :base, weight: nil, align: nil, truncate: false,
                   numeric: false, visually_hidden: false, **html_attributes)
      @variant = SCALE.key?(variant&.to_sym) ? variant.to_sym : :body_md
      @as = (as || TAGS[@variant]).to_sym
      @tone = TONES.key?(tone&.to_sym) ? tone.to_sym : :base
      @weight = weight&.to_sym
      @align = align&.to_sym
      @truncate = truncate
      @numeric = numeric
      @visually_hidden = visually_hidden
      @html_attributes = html_attributes
    end

    def call
      content_tag(@as, content, **@html_attributes, class: classes)
    end

    def self.classes(variant, tone: :base, weight: nil)
      [ BASE, SCALE.fetch(variant), TONES.fetch(tone), (WEIGHTS[weight] if weight) ].compact.join(" ")
    end

    private

    def classes
      [
        BASE, SCALE[@variant], TONES[@tone], WEIGHTS[@weight], ALIGNS[@align],
        (@truncate ? TRUNCATE : BREAK), (NUMERIC if @numeric), (HIDDEN if @visually_hidden),
        @html_attributes[:class]
      ].compact.join(" ")
    end
  end
end
