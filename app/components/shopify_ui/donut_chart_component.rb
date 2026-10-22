# frozen_string_literal: true

module ShopifyUI
  # Shopify Analytics donut chart (Polaris Viz DonutChart): a thin ring of rounded segments with small gaps,
  # the total in the centre and a legend with value + percentage per segment. Plain SVG, no JavaScript.
  #
  #   segments:     [{ label:, value:, tone: }] — tone :success | :critical | :warning | :info | :magic | :primary | :neutral
  #                 (zero/negative segments are dropped)
  #   center_value: text in the ring (default: total of all segments)
  #   center_label: muted text under it (default: "Total")
  #   size:         :small (120px) | :medium (160px, default) | :large (200px) — one size smaller on phones
  #   legend:       :right (default, moves under the ring on phones) | :bottom | false
  #   show_percent: true — muted percentage next to each legend value
  #   empty:        text shown when there are no segments
  #   empty_when_zero: false (default) draws a zero total as the grey track with every segment at 0 / 0% in the
  #                 legend; true shows `empty` instead
  #   label:        aria-label prefix for the chart
  class DonutChartComponent < ViewComponent::Base
    strip_trailing_whitespace

    RADIUS = 52
    STROKE = 8
    GAP = 1.5
    CIRCUMFERENCE = 2 * Math::PI * RADIUS

    TONES = {
      success: { stroke: "tw:stroke-viz-green", dot: "tw:bg-viz-green" },
      critical: { stroke: "tw:stroke-viz-red", dot: "tw:bg-viz-red" },
      warning: { stroke: "tw:stroke-warn-strong", dot: "tw:bg-warn-strong" },
      info: { stroke: "tw:stroke-viz-blue", dot: "tw:bg-viz-blue" },
      magic: { stroke: "tw:stroke-viz-purple", dot: "tw:bg-viz-purple" },
      primary: { stroke: "tw:stroke-viz-black", dot: "tw:bg-viz-black" },
      neutral: { stroke: "tw:stroke-neutral", dot: "tw:bg-neutral" }
    }.freeze

    SIZES = {
      small: "tw:size-[120px]",
      medium: "tw:size-[160px] tw:max-sm:size-[120px]",
      large: "tw:size-[200px] tw:max-sm:size-[160px]"
    }.freeze

    CENTER_VALUE_SIZES = {
      small: "tw:text-[16px]",
      medium: "tw:text-[20px] tw:max-sm:text-[16px]",
      large: "tw:text-[24px] tw:max-sm:text-[20px]"
    }.freeze

    LAYOUTS = {
      right: "tw:flex tw:flex-col tw:items-center tw:gap-5 tw:sm:flex-row tw:sm:items-center tw:sm:gap-6",
      bottom: "tw:flex tw:flex-col tw:items-center tw:gap-4",
      none: "tw:flex tw:justify-center"
    }.freeze

    WRAPPER = "tw:font-sans"
    RING = "tw:relative tw:shrink-0"
    SVG = "tw:block tw:size-full tw:-rotate-90"
    TRACK = "tw:stroke-fill-tertiary"
    SEGMENT = "tw:transition-opacity tw:duration-100 tw:hover:opacity-80"
    CENTER = "tw:pointer-events-none tw:absolute tw:inset-0 tw:flex tw:flex-col tw:items-center tw:justify-center tw:text-center"
    CENTER_VALUE = "tw:font-semibold tw:leading-tight tw:tabular-nums tw:text-ink"
    CENTER_LABEL = "tw:text-[12px] tw:leading-4 tw:text-muted"

    LEGEND = "tw:m-0 tw:flex tw:w-full tw:min-w-0 tw:flex-1 tw:list-none tw:flex-col tw:gap-2 tw:p-0"
    LEGEND_ROW = "tw:flex tw:items-center tw:gap-2 tw:text-[13px]"
    DOT = "tw:size-2 tw:shrink-0 tw:rounded-full"
    LEGEND_LABEL = "tw:min-w-0 tw:flex-1 tw:truncate tw:text-ink"
    LEGEND_VALUE = "tw:font-medium tw:tabular-nums tw:text-ink"
    LEGEND_PERCENT = "tw:w-12 tw:text-right tw:tabular-nums tw:text-muted"

    EMPTY = "tw:flex tw:items-center tw:justify-center tw:rounded-lg tw:bg-surface-secondary tw:px-4 tw:py-10 " \
            "tw:text-center tw:text-[13px] tw:text-muted"

    Segment = Struct.new(:label, :value, :tone, :percent, :length, :offset, keyword_init: true)

    def initialize(segments: [], center_value: nil, center_label: "Total", size: :medium, legend: :right,
                   show_percent: true, empty: "No data", empty_when_zero: false, label: "Chart", **html_attributes)
      @raw_segments = Array(segments)
      @center_value = center_value
      @center_label = center_label
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @legend = legend ? (legend.to_sym == :bottom ? :bottom : :right) : :none
      @show_percent = show_percent
      @empty = empty
      @empty_when_zero = empty_when_zero
      @label = label
      @html_attributes = html_attributes
    end

    def before_render
      @segments = build_segments
    end

    private

    def build_segments
      all = @raw_segments.map { |s| s.to_h.transform_keys(&:to_sym) }
      kept = all.select { |s| s[:value].to_f.positive? }
      @total = kept.sum { |s| s[:value].to_f }
      return zero_segments(all) if @total.zero?

      gap = kept.size > 1 ? GAP + STROKE : 0 # round caps add STROKE/2 at each end
      start = 0.0
      kept.map do |s|
        arc = CIRCUMFERENCE * s[:value].to_f / @total
        segment = Segment.new(
          label: s[:label].to_s, value: s[:value], percent: s[:value].to_f * 100 / @total,
          tone: TONES.key?(s[:tone]&.to_sym) ? s[:tone].to_sym : :neutral,
          length: [ arc - gap, 0.01 ].max, offset: -(start + (gap / 2))
        )
        start += arc
        segment
      end
    end

    # Zero total: no arcs (only the grey track), but every segment stays in the legend at 0 / 0%.
    def zero_segments(all)
      return [] if @empty_when_zero

      all.map do |s|
        Segment.new(label: s[:label].to_s, value: 0, percent: 0.0, length: 0, offset: 0,
                    tone: TONES.key?(s[:tone]&.to_sym) ? s[:tone].to_sym : :neutral)
      end
    end

    def zero?
      @total.zero?
    end

    def empty?
      @segments.empty?
    end

    def wrapper_attributes
      @html_attributes.merge(class: [ WRAPPER, LAYOUTS[@legend], @html_attributes[:class] ].compact.join(" "))
    end

    def ring_classes
      [ RING, SIZES[@size] ].join(" ")
    end

    def center_value_classes
      [ CENTER_VALUE, CENTER_VALUE_SIZES[@size] ].join(" ")
    end

    def center_value_text
      @center_value || format_number(@total)
    end

    def chart_label
      parts = @segments.map { |s| "#{s.label} #{format_number(s.value)} (#{format_percent(s.percent)})" }
      "#{@label}: #{parts.join(', ')}"
    end

    def segment_title(segment)
      "#{segment.label}: #{format_number(segment.value)} (#{format_percent(segment.percent)})"
    end

    def dasharray(segment)
      "#{segment.length.round(3)} #{CIRCUMFERENCE.round(3)}"
    end

    def format_number(value)
      value.is_a?(Numeric) ? helpers.number_with_delimiter(value.to_f % 1 == 0 ? value.to_i : value) : value.to_s
    end

    def format_percent(percent)
      "#{percent.round(1).to_s.delete_suffix('.0')}%"
    end
  end
end
