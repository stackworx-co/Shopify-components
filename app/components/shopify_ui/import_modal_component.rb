# frozen_string_literal: true

module ShopifyUI
  # Shopify admin "Import products" modal: a dashed drop zone with an "Upload file" pill, a vendor
  # select (DropdownSelectComponent), and Cancel / Submit in the footer. Built on ModalComponent and
  # wrapped in a multipart <form>, so it submits like any Rails form.
  #
  # The file input covers the whole drop zone (invisible), so click and drag-and-drop both work natively.
  #
  #   <%= render ShopifyUI::ButtonComponent.new(**ShopifyUI::ImportModalComponent.open_attributes("import")) { "Import" } %>
  #   <%= render ShopifyUI::ImportModalComponent.new(id: "import", url: imports_path,
  #         vendors: Vendor.pluck(:name, :id), sample_url: "/sample.csv") %>
  class ImportModalComponent < ViewComponent::Base
    strip_trailing_whitespace

    HEADING = "tw:m-0 tw:text-[14px] tw:font-semibold tw:leading-5 tw:text-ink"
    DESCRIPTION = "tw:m-0 tw:mt-1 tw:text-[13px] tw:leading-5 tw:text-muted"
    SAMPLE_LINK = "tw:text-ink tw:underline tw:hover:text-link"
    DROPZONE = %w[
      tw:relative tw:mt-3 tw:flex tw:min-h-[148px] tw:flex-col tw:items-center tw:justify-center tw:gap-2
      tw:rounded-control tw:border tw:border-dashed tw:border-input-border tw:bg-surface-secondary tw:p-4
      tw:transition-colors tw:duration-100 tw:hover:bg-surface-hover
      tw:has-[input:focus-visible]:outline-2 tw:has-[input:focus-visible]:outline-offset-1 tw:has-[input:focus-visible]:outline-link
      tw:data-dragover:border-link tw:data-dragover:bg-surface-hover
    ].freeze
    FILE_INPUT = "tw:absolute tw:inset-0 tw:size-full tw:cursor-pointer tw:opacity-0"
    UPLOAD_PILL = %w[
      tw:pointer-events-none tw:inline-flex tw:items-center tw:gap-1 tw:rounded-full tw:bg-fill-tertiary
      tw:px-3 tw:py-1.5 tw:text-[13px] tw:font-medium tw:leading-none tw:text-ink
    ].freeze
    FILE_NAME = "tw:pointer-events-none tw:m-0 tw:max-w-full tw:truncate tw:text-[13px] tw:text-muted"
    FIELD = "tw:mt-4"

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiImport) return; window.__suiImport = true;
        function zone(el) { return el.closest && el.closest('[data-sui-dropzone]'); }
        document.addEventListener('change', function (event) {
          var z = zone(event.target); if (!z || event.target.type !== 'file') return;
          var f = event.target.files[0], n = z.querySelector('[data-sui-dropzone-name]');
          n.textContent = f ? f.name : n.getAttribute('data-empty'); z.removeAttribute('data-dragover');
        });
        ['dragenter', 'dragover'].forEach(function (t) { document.addEventListener(t, function (e) { var z = zone(e.target); if (z) z.setAttribute('data-dragover', ''); }); });
        ['dragleave', 'drop'].forEach(function (t) { document.addEventListener(t, function (e) { var z = zone(e.target); if (z) z.removeAttribute('data-dragover'); }); });
        document.addEventListener('close', function (event) {
          var d = event.target; if (!d.matches || !d.matches('dialog[data-sui-import]')) return;
          d.querySelectorAll('[data-sui-dropzone]').forEach(function (z) {
            z.querySelector('input[type=file]').value = '';
            var n = z.querySelector('[data-sui-dropzone-name]'); n.textContent = n.getAttribute('data-empty');
          });
        }, true);
      })();
    JS

    def self.open_attributes(id)
      ModalComponent.open_attributes(id)
    end

    # vendors: same formats as DropdownSelectComponent options (["Nike", ...] or [["Nike", 1], ...]).
    def initialize(id:, url:, vendors:, title: "Import products", heading: "Upload file",
                   description: "Upload any file. Choose a vendor, then submit.",
                   sample_url: nil, sample_label: "Download sample CSV", file_name: "file", accept: nil,
                   upload_label: "Upload file", empty_label: "or drop file to upload",
                   vendor_name: "vendor", vendor_label: "Vendor", vendor_placeholder: "Select a vendor",
                   selected_vendor: nil, vendor_error: nil, method: :post,
                   submit_label: "Submit", cancel_label: "Cancel", **modal_options)
      @id = id
      @url = url
      @vendors = vendors
      @title = title
      @heading = heading
      @description = description
      @sample_url = sample_url
      @sample_label = sample_label
      @file_name = file_name
      @accept = accept
      @upload_label = upload_label
      @empty_label = empty_label
      @vendor_name = vendor_name
      @vendor_label = vendor_label
      @vendor_placeholder = vendor_placeholder
      @selected_vendor = selected_vendor
      @vendor_error = vendor_error
      @method = method
      @submit_label = submit_label
      @cancel_label = cancel_label
      @modal_options = modal_options
    end

    private

    def form_id
      "#{@id}-form"
    end

    def modal
      ModalComponent.new(
        id: @id, title: @title, data: { sui_import: "" }, **@modal_options,
        primary_action: { label: @submit_label, attributes: { type: "submit", form: form_id } },
        secondary_actions: [ { label: @cancel_label, close: true } ]
      )
    end

    def plus_icon
      tag.svg(tag.path(d: "M10 4.5v11M4.5 10h11"), viewBox: "0 0 20 20", width: 16, height: 16, fill: "none",
              stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", aria: { hidden: true })
    end
  end
end
