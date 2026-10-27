# frozen_string_literal: true

module ShopifyUI
  # Request log viewer (Shopify Dev Dashboard "Logs"): a table of log rows; clicking a row opens a
  # details panel on the right and the table narrows to make room. On phones the panel opens full screen.
  #
  #   <%= render(ShopifyUI::LogsComponent.new(logs: [
  #         { id: "1", status: :success, type: "GraphQL request", details: "query · order",
  #           shop: "example.myshopify.com", time: "Oct 26, 16:09:19",
  #           title: "query", subtitle: "order",
  #           fields: [ [ [ "Type", "GraphQL request" ], [ "Request ID", "02fe…", { copy: true } ] ],
  #                     [ [ "Shop", "example.myshopify.com", { href: "https://…" } ] ] ],
  #           more: [ [ "User agent", "…" ] ],
  #           body: "query($id: ID!) { … }", body_label: "Operation body" }
  #       ])) %>
  #
  # fields: groups of [label, value, options]; groups are separated by a gap. options: copy:, href:.
  # status: :success or :error. Optional toolbar slot renders above the table (filters, date range).
  class LogsComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :toolbar

    COLUMNS = [ { label: "" }, { label: "Type" }, { label: "Details" }, { label: "Shop" }, { label: "Time" } ].freeze

    ROOT = %w[
      tw:group tw:font-sans tw:text-ink
      tw:lg:grid tw:lg:grid-cols-[minmax(0,1fr)_0px] tw:lg:gap-0 tw:lg:items-start
      tw:lg:transition-[grid-template-columns,gap] tw:lg:duration-200 tw:lg:ease-out tw:motion-reduce:transition-none
      tw:lg:data-open:grid-cols-[minmax(0,1fr)_400px] tw:lg:data-open:gap-4
    ].freeze

    MAIN = "tw:flex tw:min-w-0 tw:flex-col tw:gap-3"

    ROW = %w[
      tw:cursor-pointer tw:outline-none
      tw:focus-visible:bg-surface-hover tw:focus-visible:shadow-[inset_2px_0_0_var(--sui-link)]
      tw:aria-selected:bg-surface-sunken tw:aria-selected:hover:bg-surface-sunken
    ].freeze

    # Phones: the table is replaced by a stacked list (two lines per log, 48px+ touch targets).
    TABLE_WRAPPER = "tw:max-sm:hidden"
    LIST_CARD = "tw:sm:hidden tw:m-0 tw:list-none tw:overflow-hidden tw:rounded-surface tw:bg-surface tw:p-0 tw:shadow-card"
    LIST_ROW = %w[
      tw:flex tw:min-h-12 tw:items-start tw:gap-3 tw:border-b tw:border-border-secondary tw:last:border-b-0
      tw:px-4 tw:py-3 tw:cursor-pointer tw:outline-none tw:active:bg-surface-sunken
      tw:focus-visible:bg-surface-hover tw:focus-visible:shadow-[inset_2px_0_0_var(--sui-link)]
      tw:aria-selected:bg-surface-sunken
    ].freeze
    LIST_TEXT = "tw:flex tw:min-w-0 tw:flex-1 tw:flex-col tw:gap-0.5"
    LIST_PRIMARY = "tw:truncate tw:text-[13px] tw:leading-5 tw:text-ink"
    LIST_SECONDARY = "tw:truncate tw:font-mono tw:text-[12px] tw:leading-4 tw:text-muted"
    LIST_EMPTY = "tw:px-4 tw:py-10 tw:text-center tw:text-[13px] tw:text-muted"
    LIST_ICON = "tw:mt-0.5 tw:block tw:size-4 tw:shrink-0"

    MONO = "tw:font-mono tw:text-[12px]"
    TIME = "tw:font-mono tw:text-[12px] tw:text-muted tw:underline tw:decoration-dotted tw:decoration-border-hover tw:underline-offset-2"
    STATUS_ICON = "tw:block tw:size-4"

    # Desktop: a grid column that animates from 0 to 400px (content keeps its width, so nothing reflows
    # mid-animation). Phones: a full-screen sheet shown only while open.
    PANEL = %w[
      tw:min-w-0 tw:overflow-hidden
      tw:max-lg:hidden tw:max-lg:group-data-open:block tw:max-lg:fixed tw:max-lg:inset-0 tw:max-lg:z-50 tw:max-lg:bg-surface
      tw:lg:sticky tw:lg:top-4
    ].freeze
    PANEL_INNER = %w[
      tw:flex tw:h-full tw:flex-col tw:bg-surface tw:max-lg:overflow-y-auto
      tw:lg:w-[400px] tw:lg:max-h-[calc(100dvh-32px)] tw:lg:overflow-y-auto tw:lg:rounded-surface tw:lg:shadow-card
    ].freeze

    # Sticky so the title and × stay visible while a long body scrolls.
    HEADER = "tw:sticky tw:top-0 tw:z-10 tw:flex tw:items-start tw:justify-between tw:gap-3 tw:bg-surface tw:px-4 tw:pt-4 tw:pb-3"
    TITLE = "tw:m-0 tw:flex tw:items-baseline tw:gap-2 tw:text-[14px] tw:font-semibold tw:leading-5"
    SUBTITLE = "tw:font-mono tw:text-[12px] tw:font-regular tw:text-muted"
    CLOSE = %w[
      tw:inline-flex tw:size-7 tw:max-lg:size-10 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:hover:bg-fill-transparent-hover tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
    ].freeze

    BODY = "tw:flex tw:flex-col tw:gap-4 tw:px-4 tw:pb-4"
    LIST = "tw:m-0 tw:grid tw:grid-cols-[112px_minmax(0,1fr)] tw:gap-x-3 tw:gap-y-1.5 tw:text-[12px] tw:leading-4"
    LABEL = "tw:m-0 tw:text-muted"
    VALUE = "tw:m-0 tw:flex tw:min-w-0 tw:items-start tw:gap-1.5 tw:font-mono tw:text-ink tw:break-all"
    LINK = "tw:text-link tw:no-underline tw:hover:underline"
    COPY = %w[
      tw:-my-1 tw:inline-flex tw:size-6 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:hover:bg-fill-transparent-hover tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
    ].freeze

    MORE = "tw:group/more tw:text-[12px]"
    MORE_SUMMARY = %w[
      tw:flex tw:w-fit tw:cursor-pointer tw:list-none tw:items-center tw:gap-1 tw:font-medium tw:text-ink
      tw:[&::-webkit-details-marker]:hidden
    ].freeze
    MORE_CHEVRON = "tw:size-3.5 tw:-rotate-90 tw:transition-transform tw:group-open/more:rotate-0"

    CODE = "tw:overflow-hidden tw:rounded-[12px] tw:bg-surface-secondary"
    CODE_HEADER = "tw:flex tw:items-center tw:justify-between tw:gap-2 tw:px-3 tw:py-2 tw:text-[12px] tw:font-medium"
    CODE_BODY = "tw:m-0 tw:max-h-[360px] tw:overflow-auto tw:px-3 tw:pb-3 tw:font-mono tw:text-[12px] tw:leading-5 tw:whitespace-pre tw:text-ink"

    def initialize(logs:, empty: "No logs found", **html_attributes)
      @logs = logs
      @empty = empty
      @html_attributes = html_attributes
      @logs_id = "sui-logs-#{SecureRandom.hex(4)}"
    end

    private

    def root_attributes
      @html_attributes.merge(
        id: @logs_id,
        class: [ ROOT, @html_attributes[:class] ].flatten.compact.join(" "),
        data: { sui_logs: "" }.merge(@html_attributes[:data] || {}),
        onclick: click_script,
        onkeydown: key_script
      )
    end

    def row_attributes(log, classes = ROW)
      { data: { log_row: log[:id] }, tabindex: 0, class: classes.join(" "), aria: { controls: "#{@logs_id}-panel" } }
    end

    def classes(list)
      list.is_a?(Array) ? list.join(" ") : list
    end

    def success?(log)
      log.fetch(:status, :success).to_sym != :error
    end

    def status_icon(log, css)
      if success?(log)
        tag.svg(safe_join([ tag.circle(cx: 10, cy: 10, r: 7), tag.path(d: "m7 10.2 2 2 4-4.4") ]),
                class: "#{css} tw:text-good-icon", viewBox: "0 0 20 20", fill: "none", stroke: "currentColor",
                "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round", role: "img", aria: { label: "Success" })
      else
        tag.svg(safe_join([ tag.circle(cx: 10, cy: 10, r: 7), tag.path(d: "M10 6.5v4M10 13.5v.01") ]),
                class: "#{css} tw:text-danger-icon", viewBox: "0 0 20 20", fill: "none", stroke: "currentColor",
                "stroke-width": 1.6, "stroke-linecap": "round", role: "img", aria: { label: "Error" })
      end
    end

    def field_parts(field)
      label, value, options = field
      [ label, value, options || {} ]
    end

    # One delegated handler: row -> open its details; close button -> close; copy button -> clipboard.
    # Rows exist twice (desktop table + phone list), so selection matches on the log id.
    # Below lg the panel is a full-screen sheet: the page behind it stops scrolling and focus moves
    # to ×; closing gives focus back to the row.
    def click_script
      "var t = event.target, root = this, sheet = matchMedia('(max-width: 1023.98px)').matches;" \
        "var copy = t.closest('[data-log-copy]');" \
        "if (copy) { navigator.clipboard && navigator.clipboard.writeText(copy.dataset.logCopy); return; }" \
        "var mark = function (id) { root.querySelectorAll('[data-log-row]').forEach(function (r) {" \
        "  r.dataset.logRow === id ? r.setAttribute('aria-selected', 'true') : r.removeAttribute('aria-selected'); }); };" \
        "if (t.closest('[data-log-close]')) { var last = root.dataset.openRow;" \
        "  root.removeAttribute('data-open'); delete root.dataset.openRow; mark(null);" \
        "  root.querySelector('[data-log-panel-body]').replaceChildren();" \
        "  document.documentElement.style.overflow = '';" \
        "  var back = Array.prototype.find.call(root.querySelectorAll('[data-log-row]'), function (r) {" \
        "    return r.dataset.logRow === last && r.offsetParent; }); back && back.focus(); return; }" \
        "var row = t.closest('[data-log-row]'); if (!row || !root.contains(row)) return;" \
        "var tpl = root.querySelector('template[data-log=\"' + row.dataset.logRow + '\"]'); if (!tpl) return;" \
        "var body = root.querySelector('[data-log-panel-body]');" \
        "body.replaceChildren(tpl.content.cloneNode(true)); body.scrollTop = 0;" \
        "mark(row.dataset.logRow); root.dataset.openRow = row.dataset.logRow; root.setAttribute('data-open', '');" \
        "if (sheet) { document.documentElement.style.overflow = 'hidden'; body.querySelector('[data-log-close]').focus(); }"
    end

    # Enter/Space on a focused row opens it; Escape closes the panel.
    def key_script
      "var row = event.target.closest('[data-log-row]');" \
        "if (row && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); row.click(); return; }" \
        "if (event.key === 'Escape' && this.hasAttribute('data-open')) {" \
        "  this.querySelector('[data-log-close]').click(); }"
    end
  end
end
