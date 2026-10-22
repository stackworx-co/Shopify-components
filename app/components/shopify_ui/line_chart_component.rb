# frozen_string_literal: true

require "securerandom"
require "json"

module ShopifyUI
  # Shopify Analytics line chart ("Total sales over time"): light gridlines, Y labels on the left, a few date
  # labels along the bottom, optional dashed comparison series, soft area fill under the first series.
  # Hover / focus shows a guide line, dots and a tooltip card; ← → move between points when focused.
  #
  #   series:         [{ name:, data: [[label, value], ...], tone:, dashed: }]
  #                   tone :highlight (default, blue) | :primary | :success | :critical | :warning | :neutral
  #   height:         plot height in px (default 180)
  #   area:           soft gradient fill under the first series (default true)
  #   y_ticks:        number of gridline steps; the max is rounded to a "nice" number (0, 5, 10, 15…)
  #   x_labels:       :auto (~5 evenly spaced, 3 on phones) or an explicit list of labels to show
  #   value_format:   ->(value) { "..." } (default: number with delimiters)
  #   highlight_last: dot on the latest point of the first series (default true)
  #   empty:          text shown when there are no data points
  #   empty_when_zero: false (default) draws all-zero data as a flat line on a 0–5 axis; true shows `empty` instead
  #   label:          aria-label prefix
  class LineChartComponent < ViewComponent::Base
    strip_trailing_whitespace

    VIEW_WIDTH = 600
    NICE_STEPS = [ 1, 2, 2.5, 5, 10 ].freeze

    TONES = {
      highlight: { stroke: "tw:stroke-info-icon", text: "tw:text-info-icon", dot: "tw:bg-info-icon", border: "tw:border-info-icon" },
      primary: { stroke: "tw:stroke-accent", text: "tw:text-accent", dot: "tw:bg-accent", border: "tw:border-accent" },
      success: { stroke: "tw:stroke-good-icon", text: "tw:text-good-icon", dot: "tw:bg-good-icon", border: "tw:border-good-icon" },
      critical: { stroke: "tw:stroke-danger-icon", text: "tw:text-danger-icon", dot: "tw:bg-danger-icon", border: "tw:border-danger-icon" },
      warning: { stroke: "tw:stroke-warn-icon", text: "tw:text-warn-icon", dot: "tw:bg-warn-icon", border: "tw:border-warn-icon" },
      neutral: { stroke: "tw:stroke-border-hover", text: "tw:text-border-hover", dot: "tw:bg-border-hover", border: "tw:border-border-hover" }
    }.freeze

    WRAPPER = "tw:group/chart tw:relative tw:w-full tw:font-sans tw:outline-none"
    BODY = "tw:flex tw:w-full tw:gap-2"
    Y_AXIS = "tw:relative tw:shrink-0 tw:text-right"
    Y_LABEL = "tw:absolute tw:right-0 tw:-translate-y-1/2 tw:text-[11px] tw:leading-none tw:tabular-nums tw:text-muted"
    PLOT = "tw:relative tw:min-w-0 tw:flex-1"
    SVG = "tw:absolute tw:inset-0 tw:block tw:size-full tw:overflow-visible"
    GRID = "tw:stroke-border-secondary"
    LINE = "tw:fill-none"
    X_AXIS = "tw:relative tw:mt-2 tw:h-4"
    X_LABEL = "tw:absolute tw:top-0 tw:whitespace-nowrap tw:text-[11px] tw:leading-4 tw:text-muted"

    POINT_DOT = %w[
      tw:pointer-events-none tw:absolute tw:size-2.5 tw:-translate-x-1/2 tw:-translate-y-1/2 tw:rounded-full
      tw:ring-2 tw:ring-surface
    ].freeze

    OVERLAY = "tw:absolute tw:inset-0 tw:flex tw:cursor-crosshair"
    COLUMN = "tw:h-full tw:flex-1"
    GUIDE = "tw:pointer-events-none tw:absolute tw:inset-y-0 tw:hidden tw:w-px tw:bg-border-hover"

    TOOLTIP = %w[
      tw:pointer-events-none tw:absolute tw:top-0 tw:z-20 tw:hidden tw:min-w-32 tw:rounded-lg tw:border
      tw:border-border-secondary tw:bg-surface tw:px-2.5 tw:py-2 tw:text-[12px] tw:text-ink tw:shadow-card
    ].freeze
    TOOLTIP_TITLE = "tw:mb-1 tw:font-semibold tw:whitespace-nowrap"
    TOOLTIP_ROW = "tw:flex tw:items-center tw:gap-2 tw:whitespace-nowrap tw:leading-5"
    TOOLTIP_DOT = "tw:size-2 tw:shrink-0 tw:rounded-full"
    TOOLTIP_NAME = "tw:flex-1 tw:text-muted"
    TOOLTIP_VALUE = "tw:font-medium tw:tabular-nums"

    HINT = %w[
      tw:pointer-events-none tw:absolute tw:right-0 tw:-top-5 tw:hidden tw:text-[11px] tw:text-muted
      tw:group-focus-visible/chart:block tw:max-sm:hidden!
    ].freeze

    LEGEND = "tw:m-0 tw:mt-3 tw:flex tw:list-none tw:flex-wrap tw:gap-x-4 tw:gap-y-1 tw:p-0 tw:text-[12px] tw:text-muted"
    LEGEND_ITEM = "tw:inline-flex tw:items-center tw:gap-1.5"
    LEGEND_LINE = "tw:inline-block tw:h-0.5 tw:w-3 tw:rounded-full"
    LEGEND_DASHED = "tw:inline-block tw:w-3 tw:border-t-2 tw:border-dashed"

    EMPTY = "tw:flex tw:items-center tw:justify-center tw:rounded-lg tw:bg-surface-secondary tw:px-4 " \
            "tw:text-center tw:text-[13px] tw:text-muted"

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiLineChart) return; window.__suiLineChart = true;
        function el(tag, cls, text) { var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
        function init(root) {
          if (root.__suiInit) return; root.__suiInit = true;
          var data = JSON.parse(root.getAttribute('data-sui-line-chart'));
          var plot = root.querySelector('[data-sui-plot]'), tip = root.querySelector('[data-sui-tooltip]'),
              guide = root.querySelector('[data-sui-guide]'), dots = root.querySelectorAll('[data-sui-hover-dot]'),
              cols = root.querySelectorAll('[data-sui-column]'), last = root.querySelector('[data-sui-last-dot]');
          var current = -1;
          function show(i) {
            var p = data.points[i]; if (!p) return; current = i;
            guide.style.left = p.x + '%'; guide.style.display = 'block';
            dots.forEach(function (dot, s) {
              var v = p.s[s]; if (!v) { dot.style.display = 'none'; return; }
              dot.style.left = p.x + '%'; dot.style.top = v.y + '%'; dot.style.display = 'block';
            });
            if (last) last.style.display = 'none';
            tip.textContent = '';
            tip.appendChild(el('div', data.cls.title, p.l));
            p.s.forEach(function (v, s) {
              if (!v) return;
              var row = el('div', data.cls.row);
              row.appendChild(el('span', data.cls.dot + ' ' + data.series[s].dot));
              row.appendChild(el('span', data.cls.name, data.series[s].name));
              row.appendChild(el('span', data.cls.value, v.v));
              tip.appendChild(row);
            });
            tip.style.display = 'block';
            var w = plot.clientWidth, tw = tip.offsetWidth, x = p.x / 100 * w, left = x + 12;
            if (left + tw > w) left = x - tw - 12;
            tip.style.left = Math.max(0, left) + 'px';
          }
          function hide() {
            current = -1; guide.style.display = 'none'; tip.style.display = 'none';
            dots.forEach(function (dot) { dot.style.display = 'none'; });
            if (last) last.style.display = '';
          }
          cols.forEach(function (col, i) { col.addEventListener('mouseenter', function () { show(i); }); });
          plot.addEventListener('mouseleave', function () { if (document.activeElement !== root) hide(); });
          root.addEventListener('focus', function () { show(current < 0 ? data.points.length - 1 : current); });
          root.addEventListener('blur', hide);
          root.addEventListener('keydown', function (e) {
            var n = data.points.length, i = current < 0 ? n - 1 : current;
            if (e.key === 'ArrowLeft') i = Math.max(0, i - 1);
            else if (e.key === 'ArrowRight') i = Math.min(n - 1, i + 1);
            else if (e.key === 'Home') i = 0;
            else if (e.key === 'End') i = n - 1;
            else if (e.key === 'Escape') { hide(); return; }
            else return;
            e.preventDefault(); show(i);
          });
        }
        ShopifyUI.onLoad(function () { document.querySelectorAll('[data-sui-line-chart]').forEach(init); });
      })();
    JS

    Series = Struct.new(:name, :data, :tone, :dashed, keyword_init: true)

    def initialize(series: [], height: 180, area: true, y_ticks: 4, x_labels: :auto, value_format: nil,
                   highlight_last: true, empty: "No data", empty_when_zero: false, label: "Chart", **html_attributes)
      @series = Array(series).map do |s|
        s = s.to_h.transform_keys(&:to_sym)
        Series.new(name: s[:name].to_s, data: Array(s[:data]).map { |l, v| [ l.to_s, v.to_f ] },
                   tone: TONES.key?(s[:tone]&.to_sym) ? s[:tone].to_sym : (s[:dashed] ? :neutral : :highlight),
                   dashed: s[:dashed] ? true : false)
      end.reject { |s| s.data.empty? }
      @height = height.to_i.clamp(60, 600)
      @area = area
      @y_ticks = y_ticks.to_i.clamp(1, 10)
      @x_labels = x_labels
      @value_format = value_format
      @highlight_last = highlight_last
      @empty = empty
      @empty_when_zero = empty_when_zero
      @label = label
      @html_attributes = html_attributes
      @uid = "sui-line-#{SecureRandom.hex(4)}"
    end

    private

    def empty?
      @series.empty? || (@empty_when_zero && all_zero?)
    end

    def all_zero?
      @series.all? { |s| s.data.all? { |_, v| v.zero? } }
    end

    # All-zero data can't scale from a max of 0: use a fixed 0–5 axis in steps of 1.
    def tick_count
      all_zero? ? 5 : @y_ticks
    end

    def primary
      @series.first
    end

    def labels
      @labels ||= primary.data.map(&:first)
    end

    def count
      labels.size
    end

    def y_max
      @y_max ||= begin
        peak = @series.flat_map { |s| s.data.map(&:last) }.max.to_f
        peak <= 0 ? 5.0 : nice_step(peak / @y_ticks) * @y_ticks
      end
    end

    def nice_step(raw)
      return 1 if raw <= 0

      magnitude = 10**Math.log10(raw).floor
      NICE_STEPS.map { |n| n * magnitude }.find { |n| n >= raw } || 10 * magnitude
    end

    def y_ticks
      (0..tick_count).map { |i| y_max * i / tick_count }
    end

    # Positions as percentages of the plot box (top-left origin).
    def x_pct(index)
      count == 1 ? 50.0 : index * 100.0 / (count - 1)
    end

    def y_pct(value)
      100 - (value.to_f / y_max * 100)
    end

    def svg_point(index, value)
      "#{(x_pct(index) * VIEW_WIDTH / 100).round(2)},#{(y_pct(value) * @height / 100).round(2)}"
    end

    def line_path(series)
      series.data.each_with_index.map { |(_, v), i| "#{i.zero? ? 'M' : 'L'}#{svg_point(i, v)}" }.join(" ")
    end

    def area_path
      first_x = (x_pct(0) * VIEW_WIDTH / 100).round(2)
      last_x = (x_pct(primary.data.size - 1) * VIEW_WIDTH / 100).round(2)
      "#{line_path(primary)} L#{last_x},#{@height} L#{first_x},#{@height} Z"
    end

    def gradient_id
      "#{@uid}-fill"
    end

    def format_value(value)
      return @value_format.call(value) if @value_format

      helpers.number_with_delimiter(value % 1 == 0 ? value.to_i : value.round(2))
    end

    # [[index, label, hidden_on_phones]] for the X axis.
    def x_axis
      if @x_labels.is_a?(Array)
        wanted = @x_labels.map(&:to_s)
        return labels.each_with_index.select { |l, _| wanted.include?(l) }.map { |l, i| [ i, l, false ] }
      end

      desktop = spread(5)
      phone = spread(3)
      desktop.map { |i| [ i, labels[i], !phone.include?(i) ] }
    end

    def spread(n)
      return (0...count).to_a if count <= n

      (0...n).map { |k| (k * (count - 1).to_f / (n - 1)).round }.uniq
    end

    def x_label_style(index)
      pct = x_pct(index)
      shift = pct <= 0 ? "0" : (pct >= 100 ? "-100%" : "-50%")
      "left: #{pct.round(3)}%; transform: translateX(#{shift})"
    end

    def y_axis_width
      "#{(y_ticks.map { |t| format_value(t).to_s.length }.max * 7) + 4}px"
    end

    def chart_data
      {
        points: labels.each_with_index.map do |l, i|
          { l: l, x: x_pct(i).round(3),
            s: @series.map { |s| (v = s.data[i]&.last) ? { y: y_pct(v).round(3), v: format_value(v).to_s } : nil } }
        end,
        series: @series.map { |s| { name: s.name, dot: TONES[s.tone][:dot] } },
        cls: { title: TOOLTIP_TITLE, row: TOOLTIP_ROW, dot: TOOLTIP_DOT, name: TOOLTIP_NAME, value: TOOLTIP_VALUE }
      }.to_json
    end

    def chart_label
      values = primary.data.map(&:last)
      peak_index = values.index(values.max)
      parts = [ "total #{format_value(values.sum)}", "peak #{format_value(values.max)} on #{labels[peak_index]}",
                "latest #{format_value(values.last)} on #{labels.last}" ]
      "#{@label}: #{parts.join(', ')}"
    end

    def wrapper_attributes
      attrs = @html_attributes.merge(class: [ WRAPPER, @html_attributes[:class] ].compact.join(" "))
      return attrs if empty?

      attrs.merge(tabindex: 0, "data-sui-line-chart": chart_data,
                  "aria-label": "#{@label}. Use the left and right arrow keys to read each point.")
    end

    def legend?
      @series.size > 1
    end
  end
end
