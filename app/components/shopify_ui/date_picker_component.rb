# frozen_string_literal: true

module ShopifyUI
  class DatePickerComponent < ViewComponent::Base
    strip_trailing_whitespace

    POPOVER = %w[
      tw:m-0 tw:max-w-[calc(100vw-16px)] tw:overflow-hidden tw:rounded-[12px] tw:border-0
      tw:bg-surface tw:p-0 tw:font-sans tw:text-ink
      tw:shadow-popover
    ].freeze

    INLINE = %w[
      tw:relative tw:inline-block tw:max-w-full tw:overflow-hidden tw:rounded-surface
      tw:bg-surface tw:font-sans tw:text-ink tw:shadow-card
    ].freeze

    BODY = "tw:flex tw:flex-col tw:sm:flex-row"

    PRESETS = %w[
      tw:relative tw:flex tw:gap-0.5 tw:overflow-x-auto tw:border-b tw:border-border tw:p-2
      tw:sm:w-44 tw:sm:flex-col tw:sm:overflow-y-auto tw:sm:border-r tw:sm:border-b-0
    ].freeze

    PRESET = %w[
      tw:shrink-0 tw:cursor-pointer tw:rounded-[8px] tw:border-0 tw:bg-transparent tw:px-2 tw:py-1.5
      tw:text-left tw:font-sans tw:text-[13px] tw:text-ink tw:whitespace-nowrap
      tw:hover:bg-surface-hover tw:aria-pressed:bg-surface-sunken tw:aria-pressed:font-medium
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    MAIN = "tw:flex tw:flex-col tw:gap-4 tw:p-4"
    INPUTS = "tw:grid tw:grid-cols-[1fr_auto_1fr] tw:items-end tw:gap-2"
    FIELD = "tw:flex tw:min-w-0 tw:flex-col tw:gap-1"
    FIELD_LABEL = "tw:text-[13px] tw:text-ink"
    ARROW = "tw:flex tw:h-8 tw:items-center tw:text-muted"

    INPUT = %w[
      tw:m-0 tw:box-border tw:h-[30px] tw:w-full tw:min-w-0 tw:rounded-control tw:border tw:border-transparent tw:bg-surface tw:shadow-input
      tw:px-3 tw:font-sans tw:text-[13px] tw:text-ink tw:tabular-nums
      tw:focus-visible:outline-none tw:focus-visible:shadow-input-focus
      tw:max-sm:text-[16px]
    ].freeze

    FOOTER = "tw:flex tw:justify-end tw:gap-2 tw:border-t tw:border-border tw:px-4 tw:py-3"

    CALENDAR = {
      months: "tw:flex tw:gap-6",
      month: "tw:w-[252px] tw:max-w-full",
      header: "tw:mb-1 tw:flex tw:h-8 tw:items-center tw:justify-between",
      title: "tw:text-[13px] tw:font-semibold tw:text-ink",
      nav: "tw:inline-flex tw:size-8 tw:cursor-pointer tw:items-center tw:justify-center tw:rounded-full " \
           "tw:border-0 tw:bg-transparent tw:text-ink tw:hover:bg-fill-tertiary " \
           "tw:focus-visible:outline-2 tw:focus-visible:outline-link",
      spacer: "tw:size-8",
      weekdays: "tw:grid tw:grid-cols-7 tw:text-center tw:text-[12px] tw:leading-8 tw:text-muted",
      days: "tw:grid tw:grid-cols-7",
      cell: "tw:flex tw:h-9 tw:items-center tw:justify-center",
      cell_in_range: "tw:bg-surface-sunken",
      cell_start: "tw:bg-linear-to-r tw:from-transparent tw:from-50% tw:to-surface-sunken tw:to-50%",
      cell_end: "tw:bg-linear-to-l tw:from-transparent tw:from-50% tw:to-surface-sunken tw:to-50%",
      day: "tw:inline-flex tw:size-9 tw:cursor-pointer tw:items-center tw:justify-center tw:rounded-full " \
           "tw:border-0 tw:font-sans tw:text-[13px] tw:tabular-nums " \
           "tw:focus-visible:outline-2 tw:focus-visible:outline-link",
      day_default: "tw:bg-transparent tw:text-ink tw:hover:bg-fill-tertiary " \
                   "tw:disabled:cursor-not-allowed tw:disabled:text-disabled tw:disabled:hover:bg-transparent",
      day_selected: "tw:bg-accent tw:font-semibold tw:text-on-accent tw:hover:bg-accent-hover",
      day_today: "tw:font-semibold tw:underline tw:underline-offset-4"
    }.freeze

    CALENDAR_ICON = "M4 6a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6ZM4 8.5h12M7.5 2.5v3M12.5 2.5v3"

    def initialize(url: nil, mode: :range, start_date: nil, end_date: nil, start_name: :since, end_name: :until,
                   presets: true, min: nil, max: nil, inline: false, label: "Select dates", params: {},
                   variant: :secondary, size: :medium, **html_attributes)
      @url = url
      @range = mode != :single
      @start_date = to_date(start_date)
      @end_date = @range ? to_date(end_date) : @start_date
      @start_name = start_name
      @end_name = end_name
      @presets = presets
      @min = to_date(min)
      @max = to_date(max)
      @inline = inline
      @label = label
      @params = params
      @variant = variant
      @size = size
      @html_attributes = html_attributes
      @popover_id = "sui-date-#{SecureRandom.hex(4)}"
    end

    private

    def range?
      @range
    end

    def inline?
      @inline
    end

    def preset_list
      return [] unless range? && @presets
      return @presets if @presets.is_a?(Array)

      today = Date.current
      [
        [ "Today", today, today ],
        [ "Yesterday", today - 1, today - 1 ],
        [ "Last 7 days", today - 7, today - 1 ],
        [ "Last 30 days", today - 30, today - 1 ],
        [ "Last 90 days", today - 90, today - 1 ],
        [ "Last 365 days", today - 365, today - 1 ],
        [ "Last month", today.prev_month.beginning_of_month, today.prev_month.end_of_month ],
        [ "Last 12 months", (today << 12).beginning_of_month, today.prev_month.end_of_month ],
        [ "Last year", today.prev_year.beginning_of_year, today.prev_year.end_of_year ],
        [ "Week to date", today.beginning_of_week(:sunday), today ],
        [ "Month to date", today.beginning_of_month, today ],
        [ "Quarter to date", today.beginning_of_quarter, today ],
        [ "Year to date", today.beginning_of_year, today ]
      ]
    end

    def preset_selected?(preset)
      preset[1] == @start_date && preset[2] == @end_date
    end

    def trigger_label
      return @label unless @start_date
      return format_date(@start_date) unless range? && @end_date

      preset = preset_list.find { |item| preset_selected?(item) }
      return preset[0] if preset
      return format_date(@start_date) if @start_date == @end_date
      return "#{@start_date.strftime('%b %-d')} – #{format_date(@end_date)}" if @start_date.year == @end_date.year

      "#{format_date(@start_date)} – #{format_date(@end_date)}"
    end

    def format_date(date)
      date.strftime("%b %-d, %Y")
    end

    def iso(date)
      date&.iso8601
    end

    def root_attributes
      @html_attributes.merge(
        data: { mode: range? ? "range" : "single", min: iso(@min), max: iso(@max), classes: CALENDAR.to_json },
        class: [ (inline? ? INLINE : "tw:inline-block"), @html_attributes[:class] ].flatten.compact.join(" ")
      )
    end

    def popover_attributes
      { id: @popover_id, popover: "auto", class: POPOVER.join(" ") }
    end

    def calendar_icon
      tag.svg(tag.path(d: CALENDAR_ICON), viewBox: "0 0 20 20", width: 16, height: 16, fill: "none",
              stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round",
              class: "tw:-ml-0.5 tw:shrink-0", "aria-hidden": true)
    end

    def to_date(value)
      return value if value.is_a?(Date)

      Date.iso8601(value.to_s) if value.present?
    rescue Date::Error
      nil
    end
  end
end
