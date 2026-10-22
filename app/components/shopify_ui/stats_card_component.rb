# frozen_string_literal: true

module ShopifyUI
  # Shopify admin stats / metrics.
  #   variant: :strip -> one rounded card with inline metric columns + underline sparkline
  #                      (top of Orders / Products / Customers). Optional `range` slot on the left.
  #   variant: :grid  -> one card per metric with a larger sparkline (Home / Analytics).
  #                      A single metric renders as a lone card.
  #   variant: :chart -> Shopify Home metric cards: value + trend badge, 56px smooth area chart with a
  #                      hover / focus tooltip (guide line + dot), dashed comparison line. Up to 6 columns
  #                      (2 on phones, 3 on tablets). Optional caption: "Oct 1 – Oct 22" under each label.
  #
  # Each metric is a hash:
  #   label:, value:, trend: 12.5 (percent; sign decides direction), trend_inverse: true
  #   (down is good, e.g. returns), sparkline: [numbers], comparison: [numbers] (previous period,
  #   dashed), help: "tooltip text", href:, loading: true,
  #   sparkline_labels: ["Oct 1", ...] (chart tooltip text; without it the tooltip shows the value only)
  class StatsCardComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :range

    VARIANTS = %i[strip grid chart].freeze

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
      4 => "tw:grid-cols-1 tw:sm:grid-cols-2 tw:lg:grid-cols-4",
      5 => "tw:grid-cols-2 tw:md:grid-cols-3 tw:xl:grid-cols-5",
      6 => "tw:grid-cols-2 tw:md:grid-cols-3 tw:xl:grid-cols-6"
    }.freeze
    # :chart cards are compact, so even 2–4 columns stay 2-up on phones.
    CHART_COLUMNS = {
      1 => "tw:grid-cols-1",
      2 => "tw:grid-cols-2",
      3 => "tw:grid-cols-2 tw:md:grid-cols-3",
      4 => "tw:grid-cols-2 tw:lg:grid-cols-4"
    }.freeze
    GRID = "tw:grid tw:gap-4 tw:max-sm:gap-3"
    GRID_CARD = "tw:flex tw:flex-col tw:gap-2 tw:p-4 tw:max-sm:p-3.5"
    GRID_LABEL = "tw:text-[13px] tw:font-semibold tw:text-ink tw:min-w-0"
    GRID_VALUE = "tw:flex tw:flex-wrap tw:items-baseline tw:gap-x-2 tw:gap-y-0.5 tw:text-[20px] tw:max-sm:text-[18px] tw:font-semibold tw:leading-tight tw:text-ink tw:tabular-nums tw:break-all"
    GRID_SPARK = { width: 240, height: 48 }.freeze

    # --- chart ---
    CHART_GRID = "tw:grid tw:gap-3"
    CHART_CARD = "tw:flex tw:min-w-0 tw:flex-col tw:p-3.5 tw:max-sm:p-3"
    CHART_LABEL = "tw:min-w-0 tw:truncate tw:text-[13px] tw:font-semibold tw:text-ink"
    CHART_CAPTION = "tw:mt-0.5 tw:truncate tw:text-[12px] tw:text-muted"
    CHART_ROW_CAPTION = "tw:mb-2 tw:text-[12px] tw:text-muted"
    CHART_VALUE_ROW = "tw:mt-1.5 tw:flex tw:min-w-0 tw:flex-wrap tw:items-center tw:justify-between tw:gap-x-2 tw:gap-y-0.5"
    CHART_VALUE = "tw:text-[20px] tw:max-sm:text-[17px] tw:font-semibold tw:leading-tight tw:tabular-nums tw:text-ink"
    CHART_EMPTY_VALUE = "tw:text-[20px] tw:max-sm:text-[17px] tw:font-semibold tw:leading-tight tw:text-muted"
    CHART_PLOT = "tw:relative tw:mt-3 tw:h-14 tw:w-full tw:outline-none tw:focus-visible:rounded tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link"
    CHART_SVG = "tw:absolute tw:inset-0 tw:block tw:size-full tw:overflow-visible"
    CHART_LINE = "tw:fill-none tw:stroke-viz-blue"
    CHART_COMPARE = "tw:fill-none tw:stroke-border-hover"
    CHART_FILL = "tw:text-viz-blue"
    CHART_OVERLAY = "tw:absolute tw:inset-0 tw:flex"
    CHART_COLUMN = "tw:h-full tw:flex-1"
    CHART_GUIDE = "tw:pointer-events-none tw:absolute tw:inset-y-0 tw:hidden tw:w-px tw:bg-border-hover"
    CHART_DOT = "tw:pointer-events-none tw:absolute tw:hidden tw:size-2 tw:-translate-x-1/2 tw:-translate-y-1/2 tw:rounded-full tw:bg-viz-blue tw:ring-2 tw:ring-surface"
    CHART_TIP = %w[
      tw:pointer-events-none tw:absolute tw:bottom-full tw:z-20 tw:mb-1 tw:hidden tw:whitespace-nowrap tw:rounded-lg
      tw:border tw:border-border-secondary tw:bg-surface tw:px-2 tw:py-1 tw:text-[12px] tw:font-medium tw:text-ink
      tw:tabular-nums tw:shadow-card
    ].freeze
    CHART_VIEW = { width: 240, height: 56 }.freeze
    CHART_PAD = 8.0 # % of height kept free above and below the line

    CHART_SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiStatsChart) return; window.__suiStatsChart = true;
        function init(plot) {
          if (plot.__suiInit) return; plot.__suiInit = true;
          var pts = JSON.parse(plot.getAttribute('data-sui-stats-chart')), current = -1,
              guide = plot.querySelector('[data-sui-guide]'), dot = plot.querySelector('[data-sui-dot]'),
              tip = plot.querySelector('[data-sui-tip]');
          function show(i) {
            var p = pts[i]; if (!p) return; current = i;
            guide.style.left = dot.style.left = p[0] + '%'; dot.style.top = p[1] + '%';
            guide.style.display = dot.style.display = tip.style.display = 'block';
            tip.textContent = p[2];
            var w = plot.clientWidth, tw = tip.offsetWidth, x = p[0] / 100 * w;
            tip.style.left = Math.max(0, Math.min(w - tw, x - tw / 2)) + 'px';
          }
          function hide() { current = -1; guide.style.display = dot.style.display = tip.style.display = 'none'; }
          plot.querySelectorAll('[data-sui-column]').forEach(function (c, i) { c.addEventListener('mouseenter', function () { show(i); }); });
          plot.addEventListener('mouseleave', function () { if (document.activeElement !== plot) hide(); });
          plot.addEventListener('focus', function () { show(current < 0 ? pts.length - 1 : current); });
          plot.addEventListener('blur', hide);
          plot.addEventListener('keydown', function (e) {
            var n = pts.length, i = current < 0 ? n - 1 : current;
            if (e.key === 'ArrowLeft') i = Math.max(0, i - 1); else if (e.key === 'ArrowRight') i = Math.min(n - 1, i + 1);
            else if (e.key === 'Escape') { hide(); return; } else return;
            e.preventDefault(); show(i);
          });
        }
        ShopifyUI.onLoad(function () { document.querySelectorAll('[data-sui-stats-chart]').forEach(init); });
      })();
    JS

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

    LINE_COLOR = "var(--sui-viz-blue)"
    COMPARE_COLOR = "var(--sui-faint)"

    def initialize(metrics:, variant: :strip, columns: nil, caption: nil, caption_position: :label, **html_attributes)
      @metrics = Array(metrics).map { |m| m.to_h.symbolize_keys }
      @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :strip
      max_columns = @variant == :strip ? 4 : 6
      @columns = (columns || @metrics.size.clamp(1, max_columns)).to_i.clamp(1, max_columns)
      @columns = 4 if @variant == :grid && @columns > 4 && columns.nil?
      @caption = caption
      @caption_position = caption_position&.to_sym == :row ? :row : :label
      @html_attributes = html_attributes
    end

    private

    def strip?
      @variant == :strip
    end

    def chart?
      @variant == :chart
    end

    def row_caption?
      chart? && @caption.present? && @caption_position == :row
    end

    def wrapper_attributes
      base = if strip? then CARD
             elsif chart? then [ CHART_GRID, (CHART_COLUMNS[@columns] || GRID_COLUMNS[@columns]) ].join(" ")
             else [ GRID, GRID_COLUMNS[@columns] ].join(" ")
             end
      @html_attributes.merge(class: [ base, @html_attributes[:class] ].compact.join(" "))
    end

    def metric_body(metric)
      return chart_body(metric) if chart?

      label = label_tag(metric)
      value = value_tag(metric)
      spark = sparkline(metric, strip? ? STRIP_SPARK : GRID_SPARK)
      strip? ? safe_join([ tag.div(label, class: STRIP_LABEL), value, spark ]) : safe_join([ tag.div(label, class: GRID_LABEL), value, spark ])
    end

    def metric_wrapper(metric, &block)
      classes = strip? ? STRIP_METRIC : [ CARD, (chart? ? CHART_CARD : GRID_CARD) ].join(" ")
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

    # --- chart variant ---

    def chart_body(metric)
      head = [ tag.div(label_tag(metric), class: CHART_LABEL) ]
      head << tag.div(@caption, class: CHART_CAPTION) if @caption.present? && !row_caption?
      safe_join([ *head, chart_value_row(metric), chart_plot(metric) ])
    end

    def chart_value_row(metric)
      if metric[:loading]
        return tag.div(tag.span(class: "#{SKELETON} tw:h-6 tw:w-20", aria: { hidden: true }) +
                       tag.span("Loading", class: "tw:sr-only"), class: CHART_VALUE_ROW)
      end

      value = metric[:value].presence
      tag.div(safe_join([ tag.span(value || "—", class: value ? CHART_VALUE : CHART_EMPTY_VALUE), trend_tag(metric) ].compact),
              class: CHART_VALUE_ROW)
    end

    def chart_plot(metric)
      return tag.div(tag.span(class: "#{SKELETON} tw:block tw:size-full", aria: { hidden: true }), class: CHART_PLOT) if metric[:loading]

      data = Array(metric[:sparkline]).map(&:to_f)
      compare = Array(metric[:comparison]).map(&:to_f)
      w, h = CHART_VIEW.values_at(:width, :height)
      @chart_index = (@chart_index || 0) + 1
      gradient = "sui-stats-#{object_id}-#{@chart_index}"

      if data.size < 2
        y = h * (1 - CHART_PAD / 100)
        flat = tag.line(x1: 0, y1: y, x2: w, y2: y, "stroke-width": 2, "stroke-linecap": "round",
                        "vector-effect": "non-scaling-stroke", class: CHART_LINE)
        svg = tag.svg(flat, viewBox: "0 0 #{w} #{h}", preserveAspectRatio: "none", class: CHART_SVG,
                      role: "img", aria: { label: chart_aria(metric) })
        return tag.div(svg, class: CHART_PLOT)
      end

      min, max = (data + compare).minmax
      pts = chart_points(data, min, max)
      parts = []
      parts << tag.defs(tag.linearGradient(
        safe_join([ tag.stop(offset: "0%", "stop-color": "currentColor", "stop-opacity": 0.2),
                    tag.stop(offset: "100%", "stop-color": "currentColor", "stop-opacity": 0) ]),
        id: gradient, x1: 0, y1: 0, x2: 0, y2: 1, class: CHART_FILL))
      line = smooth_path(pts.map { |x, y| [ x * w / 100, y * h / 100 ] })
      parts << tag.path(d: "#{line} L#{w},#{h} L0,#{h} Z", fill: "url(##{gradient})", stroke: "none")
      if compare.size > 1
        cpts = chart_points(compare, min, max).map { |x, y| [ x * w / 100, y * h / 100 ] }
        parts << tag.path(d: smooth_path(cpts), "stroke-width": 1.5, "stroke-dasharray": "3 3",
                          "vector-effect": "non-scaling-stroke", class: CHART_COMPARE)
      end
      parts << tag.path(d: line, "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round",
                        "vector-effect": "non-scaling-stroke", class: CHART_LINE)

      labels = Array(metric[:sparkline_labels])
      tips = pts.each_with_index.map do |(x, y), i|
        value = helpers.number_with_delimiter(data[i] % 1 == 0 ? data[i].to_i : data[i].round(2))
        [ x.round(3), y.round(3), labels[i].present? ? "#{labels[i]} · #{value}" : value.to_s ]
      end

      tag.div(safe_join([
        tag.svg(safe_join(parts), viewBox: "0 0 #{w} #{h}", preserveAspectRatio: "none", class: CHART_SVG,
                role: "img", aria: { label: chart_aria(metric) }),
        tag.div(class: CHART_GUIDE, data: { sui_guide: "" }),
        tag.span(class: CHART_DOT, data: { sui_dot: "" }),
        tag.div(safe_join(data.size.times.map { tag.div(class: CHART_COLUMN, data: { sui_column: "" }) }),
                class: CHART_OVERLAY, aria: { hidden: true }),
        tag.div(class: CHART_TIP.join(" "), data: { sui_tip: "" }, aria: { hidden: true })
      ]), class: CHART_PLOT, tabindex: 0, data: { sui_stats_chart: tips.to_json },
          aria: { label: "#{metric[:label]} chart. Use the left and right arrow keys to read each point." })
    end

    # [[x%, y%]] inside the plot box (top-left origin).
    def chart_points(values, min, max)
      span = max - min
      values.each_with_index.map do |v, i|
        x = values.size == 1 ? 50.0 : i * 100.0 / (values.size - 1)
        y = span.zero? ? 100 - CHART_PAD : CHART_PAD + (100 - 2 * CHART_PAD) * (1 - (v - min) / span)
        [ x, y ]
      end
    end

    # Catmull-Rom spline through the points, as cubic Béziers.
    def smooth_path(points)
      d = [ "M#{points[0][0].round(2)},#{points[0][1].round(2)}" ]
      points.each_cons(2).with_index do |(p1, p2), i|
        p0 = i.zero? ? p1 : points[i - 1]
        p3 = points[i + 2] || p2
        c1 = [ p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6 ]
        c2 = [ p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6 ]
        d << "C#{c1.map { |n| n.round(2) }.join(',')} #{c2.map { |n| n.round(2) }.join(',')} #{p2[0].round(2)},#{p2[1].round(2)}"
      end
      d.join(" ")
    end

    def chart_aria(metric)
      parts = [ metric[:label], metric[:value].presence || "no data" ]
      unless metric[:trend].nil?
        t = metric[:trend].to_f
        pct = "#{t.abs.round(1).to_s.sub(/\.0\z/, '')}%"
        parts << (t.zero? ? "no change vs previous period" : "#{t.positive? ? 'up' : 'down'} #{pct} vs previous period")
      end
      parts.join(", ")
    end
  end
end
