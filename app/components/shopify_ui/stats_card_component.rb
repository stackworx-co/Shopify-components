# frozen_string_literal: true

module ShopifyUI
  # Shopify admin stats / metrics.
  #   variant: :strip -> one rounded card with inline metric columns + underline sparkline
  #                      (top of Orders / Products / Customers). Optional `range` slot on the left.
  #   variant: :grid  -> one card per metric with a larger sparkline (Home / Analytics).
  #                      A single metric renders as a lone card.
  #
  # Each metric is a hash:
  #   label:, value:, trend: 12.5 (percent; sign decides direction), trend_inverse: true
  #   (down is good, e.g. returns), sparkline: [numbers], comparison: [numbers] (previous period,
  #   dashed), help: "tooltip text", href:, loading: true
  class StatsCardComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :range

    VARIANTS = %i[strip grid].freeze

    CARD = "tw:relative tw:rounded-surface tw:border tw:border-border tw:bg-surface tw:shadow-card tw:min-w-0"

    # --- strip ---
    STRIP = %w[
      tw:relative tw:flex tw:items-stretch tw:overflow-x-auto tw:overscroll-x-contain tw:snap-x tw:snap-mandatory
      tw:px-4 tw:py-3.5 tw:max-sm:px-3 tw:max-sm:py-3 tw:[scrollbar-width:thin]
    ].freeze
    STRIP_RANGE = %w[
      tw:flex tw:shrink-0 tw:snap-start tw:items-center tw:gap-1.5 tw:whitespace-nowrap
      tw:text-[12.5px] tw:font-semibold tw:text-ink
      tw:mr-6 tw:pr-6 tw:border-r tw:border-border tw:max-sm:mr-4 tw:max-sm:pr-4
    ].freeze
    STRIP_METRIC = "tw:shrink-0 tw:snap-start tw:pr-7 tw:last:pr-0 tw:max-sm:pr-5 tw:min-w-[96px]"
    STRIP_LABEL = "tw:mb-1 tw:text-[13px] tw:font-semibold tw:text-ink tw:whitespace-nowrap"
    STRIP_VALUE = "tw:mb-1.5 tw:flex tw:items-baseline tw:gap-1.5 tw:whitespace-nowrap tw:text-[14px] tw:text-ink tw:tabular-nums"
    STRIP_SPARK = { width: 72, height: 4 }.freeze

    # --- grid ---
    GRID_COLUMNS = {
      1 => "tw:grid-cols-1",
      2 => "tw:grid-cols-1 tw:sm:grid-cols-2",
      3 => "tw:grid-cols-1 tw:sm:grid-cols-2 tw:lg:grid-cols-3",
      4 => "tw:grid-cols-1 tw:sm:grid-cols-2 tw:lg:grid-cols-4"
    }.freeze
    GRID = "tw:grid tw:gap-4 tw:max-sm:gap-3"
    GRID_CARD = "tw:flex tw:flex-col tw:gap-2 tw:p-4 tw:max-sm:p-3.5"
    GRID_LABEL = "tw:text-[13px] tw:font-semibold tw:text-ink tw:min-w-0"
    GRID_VALUE = "tw:flex tw:flex-wrap tw:items-baseline tw:gap-x-2 tw:gap-y-0.5 tw:text-[20px] tw:max-sm:text-[18px] tw:font-semibold tw:leading-tight tw:text-ink tw:tabular-nums tw:break-all"
    GRID_SPARK = { width: 240, height: 48 }.freeze

    LINK = "tw:block tw:rounded-lg tw:text-inherit tw:no-underline tw:hover:no-underline tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link"
    GRID_LINK_HOVER = "tw:transition-colors tw:hover:bg-surface-hover"

    HELP = %w[
      tw:group tw:relative tw:inline-block tw:cursor-help tw:underline tw:decoration-dotted
      tw:decoration-faint tw:underline-offset-4 tw:outline-none
      tw:focus-visible:rounded tw:focus-visible:outline-2 tw:focus-visible:outline-link
    ].freeze
    # Fixed so scrolling / clipping containers (the strip scrolls sideways) can't cut it off;
    # TOOLTIP_SCRIPT places it under the label. Hidden tooltips take no space.
    TOOLTIP = %w[
      tw:pointer-events-none tw:fixed tw:z-[1000] tw:w-max tw:max-w-[240px]
      tw:max-sm:max-w-[calc(100vw-48px)] tw:whitespace-normal tw:rounded-lg tw:border tw:border-border-secondary
      tw:bg-surface tw:px-2.5 tw:py-1.5 tw:text-[12px] tw:font-normal tw:text-ink tw:shadow-card
      tw:hidden tw:group-hover:block tw:group-focus:block
    ].freeze

    TOOLTIP_SCRIPT = <<~JS.squish.freeze
      (function () {
        if (window.__suiStatsTip) return; window.__suiStatsTip = true;
        function place(e) {
          var h = e.target.closest && e.target.closest('[data-sui-help]'); if (!h) return;
          var t = h.querySelector('[role=tooltip]'), r = h.getBoundingClientRect();
          requestAnimationFrame(function () {
            t.style.top = (r.bottom + 6) + 'px';
            t.style.left = Math.max(8, Math.min(r.left, innerWidth - t.offsetWidth - 8)) + 'px';
          });
        }
        document.addEventListener('mouseover', place); document.addEventListener('focusin', place);
      })();
    JS

    TREND = "tw:inline-flex tw:items-center tw:gap-0.5 tw:text-[12px] tw:font-medium tw:whitespace-nowrap"
    TREND_TONES = { good: "tw:text-good", bad: "tw:text-danger", neutral: "tw:text-muted" }.freeze
    TREND_ICONS = { up: "M5 13 13 5M7 5h6v6", down: "M5 7l8 8M13 9v6H7" }.freeze

    SKELETON = "tw:inline-block tw:rounded tw:bg-surface-sunken tw:animate-pulse"

    LINE_COLOR = "var(--color-link)"
    COMPARE_COLOR = "var(--color-faint)"

    def initialize(metrics:, variant: :strip, columns: nil, **html_attributes)
      @metrics = Array(metrics).map { |m| m.to_h.symbolize_keys }
      @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :strip
      @columns = (columns || @metrics.size.clamp(1, 4)).to_i.clamp(1, 4)
      @html_attributes = html_attributes
    end

    private

    def strip?
      @variant == :strip
    end

    def wrapper_attributes
      base = strip? ? CARD : [ GRID, GRID_COLUMNS[@columns] ].join(" ")
      @html_attributes.merge(class: [ base, @html_attributes[:class] ].compact.join(" "))
    end

    def metric_body(metric)
      label = label_tag(metric)
      value = value_tag(metric)
      spark = sparkline(metric, strip? ? STRIP_SPARK : GRID_SPARK)
      strip? ? safe_join([ tag.div(label, class: STRIP_LABEL), value, spark ]) : safe_join([ tag.div(label, class: GRID_LABEL), value, spark ])
    end

    def metric_wrapper(metric, &block)
      classes = strip? ? STRIP_METRIC : [ CARD, GRID_CARD ].join(" ")
      body = capture(&block)
      if metric[:href].present?
        link_classes = [ LINK, (strip? ? "tw:-m-1 tw:p-1 tw:hover:bg-surface-hover" : nil) ].compact.join(" ")
        if strip?
          tag.div(tag.a(body, href: metric[:href], class: link_classes), class: classes)
        else
          tag.a(body, href: metric[:href], class: [ classes, LINK, GRID_LINK_HOVER ].join(" "))
        end
      else
        tag.div(body, class: classes)
      end
    end

    def label_tag(metric)
      return metric[:label] if metric[:help].blank?

      tag.span(safe_join([ metric[:label], tag.span(metric[:help], class: TOOLTIP.join(" "), role: "tooltip") ]),
               class: HELP.join(" "), tabindex: 0, data: { sui_help: "" })
    end

    def value_tag(metric)
      css = strip? ? STRIP_VALUE : GRID_VALUE
      if metric[:loading]
        size = strip? ? "tw:h-3.5 tw:w-12" : "tw:h-6 tw:w-24"
        return tag.div(tag.span(class: "#{SKELETON} #{size}", aria: { hidden: true }) +
                       tag.span("Loading", class: "tw:sr-only"), class: css)
      end

      tag.div(safe_join([ tag.span(metric[:value].presence || "—"), trend_tag(metric) ].compact), class: css)
    end

    def trend_tag(metric)
      return if metric[:trend].nil?

      trend = metric[:trend].to_f
      direction = trend.positive? ? :up : (trend.negative? ? :down : nil)
      tone = if direction.nil? then :neutral
             elsif (direction == :up) ^ metric[:trend_inverse].present? then :good
             else :bad
             end
      text = "#{trend.abs.round(1).to_s.sub(/\.0\z/, '')}%"
      sr = direction ? "#{direction == :up ? 'Up' : 'Down'} #{text}" : "No change"
      icon = if direction
               tag.svg(tag.path(d: TREND_ICONS[direction]), viewBox: "0 0 18 18", width: 12, height: 12,
                       fill: "none", stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round",
                       "stroke-linejoin": "round", aria: { hidden: true }, focusable: "false")
             end
      tag.span(safe_join([ icon, tag.span(direction ? text : "—", aria: { hidden: true }), tag.span(sr, class: "tw:sr-only") ].compact),
               class: "#{TREND} #{TREND_TONES[tone]}")
    end

    def sparkline(metric, size)
      w, h = size.values_at(:width, :height)
      data = Array(metric[:sparkline]).map(&:to_f)
      compare = Array(metric[:comparison]).map(&:to_f)
      all = data + compare
      lines = []

      if metric[:loading]
        return tag.span(class: "#{SKELETON} tw:block #{strip? ? 'tw:h-1 tw:w-[72px]' : 'tw:h-12 tw:w-full'}", aria: { hidden: true })
      elsif data.size < 2
        # No data yet: flat dotted underline, as in the admin.
        lines << tag.line(x1: 1, y1: h / 2.0, x2: w - 1, y2: h / 2.0, stroke: LINE_COLOR, "stroke-width": 2,
                          "stroke-linecap": "round", "stroke-dasharray": "2 3", "vector-effect": "non-scaling-stroke")
      else
        min, max = all.minmax
        lines << polyline(compare, min, max, w, h, COMPARE_COLOR, dashed: true) if compare.size > 1
        lines << polyline(data, min, max, w, h, LINE_COLOR)
      end

      sizing = strip? ? { width: w, height: h, class: "tw:block tw:overflow-visible" } :
                        { class: "tw:block tw:h-12 tw:w-full tw:overflow-visible", preserveAspectRatio: "none" }
      tag.svg(safe_join(lines), viewBox: "0 0 #{w} #{h}", aria: { hidden: true }, focusable: "false", **sizing)
    end

    def polyline(values, min, max, w, h, color, dashed: false)
      span = (max - min).zero? ? 1 : (max - min)
      pad = 1.5
      step = (w - pad * 2) / (values.size - 1).to_f
      points = values.each_with_index.map do |v, i|
        x = pad + i * step
        y = (max - min).zero? ? h / 2.0 : pad + (h - pad * 2) * (1 - (v - min) / span)
        "#{x.round(2)},#{y.round(2)}"
      end
      tag.polyline(points: points.join(" "), fill: "none", stroke: color, "stroke-width": strip? ? 2 : 1.75,
                   "stroke-linecap": "round", "stroke-linejoin": "round", "vector-effect": "non-scaling-stroke",
                   "stroke-dasharray": (dashed ? "3 3" : nil))
    end
  end
end
