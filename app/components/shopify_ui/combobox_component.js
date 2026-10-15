(function () {
  if (window.__suiCombobox) return; window.__suiCombobox = true;
  function parts(el) {
    var root = el.closest('[data-sui-combobox]');
    return { root: root, input: root.querySelector('[data-input]'), list: root.querySelector('[role=listbox]'), box: root.querySelector('[data-box]'),
             multiple: root.hasAttribute('data-multiple'), tags: root.querySelector('[data-tags]'), hidden: root.querySelector('[data-hidden-value]') };
  }
  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
  function opts(p) { return Array.prototype.slice.call(p.list.querySelectorAll('[role=option]')); }
  function visible(p) { return opts(p).filter(function (o) { return !o.hasAttribute('data-hidden') && o.getAttribute('aria-disabled') !== 'true'; }); }
  function setActive(p, o) {
    opts(p).forEach(function (x) { x.removeAttribute('data-active'); });
    if (o) { o.setAttribute('data-active', ''); p.input.setAttribute('aria-activedescendant', o.id); o.scrollIntoView({ block: 'nearest' }); }
    else p.input.removeAttribute('aria-activedescendant');
  }
  function place(p) {
    var r = p.box.getBoundingClientRect(), l = p.list;
    l.style.width = Math.min(r.width, innerWidth - 16) + 'px'; l.style.right = l.style.bottom = 'auto';
    l.style.left = Math.max(8, Math.min(r.left, innerWidth - l.offsetWidth - 8)) + 'px';
    var below = innerHeight - r.bottom - 8, above = r.top - 8;
    l.style.top = (l.offsetHeight > below && above > below ? Math.max(8, r.top - 4 - l.offsetHeight) : r.bottom + 4) + 'px';
  }
  function open(p) {
    if (p.input.disabled) return;
    var min = parseInt(p.root.getAttribute('data-min-chars') || '0', 10);
    if (p.input.value.trim().length < min) { close(p); return; }
    if (!p.list.matches(':popover-open')) p.list.showPopover();
    p.input.setAttribute('aria-expanded', 'true'); place(p);
  }
  function close(p) { if (p.list.matches(':popover-open')) p.list.hidePopover(); p.input.setAttribute('aria-expanded', 'false'); setActive(p, null); }
  function highlight(o, q) {
    var label = o.getAttribute('data-label'), t = o.querySelector('[data-text]'), i = q ? label.toLowerCase().indexOf(q) : -1;
    t.innerHTML = i < 0 ? esc(label) : esc(label.slice(0, i)) + '<mark>' + esc(label.slice(i, i + q.length)) + '</mark>' + esc(label.slice(i + q.length));
  }
  function filter(p) {
    var q = p.input.value.trim().toLowerCase(), remote = p.root.getAttribute('data-url');
    if (!p.multiple && p.root.__chosenLabel === p.input.value) q = '';
    if (!remote) opts(p).forEach(function (o) {
      if (o.hasAttribute('data-create')) return;
      var hit = !q || o.getAttribute('data-search').indexOf(q) !== -1;
      o.toggleAttribute('data-hidden', !hit); highlight(o, q);
    });
    p.list.querySelectorAll('[data-group]').forEach(function (g) {
      var any = false, n = g.nextElementSibling;
      while (n && !n.hasAttribute('data-group')) { if (n.matches('[role=option]') && !n.hasAttribute('data-hidden')) any = true; n = n.nextElementSibling; }
      g.toggleAttribute('data-hidden', !any);
    });
    var create = p.list.querySelector('[data-create]');
    if (create) {
      var exact = opts(p).some(function (o) { return !o.hasAttribute('data-create') && o.getAttribute('data-label').toLowerCase() === q; });
      create.toggleAttribute('data-hidden', !q || exact);
      create.setAttribute('data-value', p.input.value.trim()); create.setAttribute('data-label', p.input.value.trim());
      create.querySelector('[data-text]').textContent = 'Add “' + p.input.value.trim() + '”';
    }
    var empty = p.list.querySelector('[data-empty]');
    empty.toggleAttribute('data-visible', visible(p).length === 0 && !p.root.hasAttribute('data-loading'));
    setActive(p, visible(p)[0] || null);
    if (p.list.matches(':popover-open')) place(p);
  }
  function fetchRemote(p) {
    var url = p.root.getAttribute('data-url'), q = p.input.value.trim();
    clearTimeout(p.root.__t);
    p.root.__t = setTimeout(function () {
      var seq = (p.root.__seq || 0) + 1; p.root.__seq = seq; p.root.setAttribute('data-loading', '');
      fetch(url + (url.indexOf('?') === -1 ? '?' : '&') + 'q=' + encodeURIComponent(q), { headers: { Accept: 'application/json' } })
        .then(function (r) { return r.json(); })
        .then(function (items) {
          if (seq !== p.root.__seq) return;
          var tpl = p.root.querySelector('template[data-option]'), chosen = values(p);
          opts(p).forEach(function (o) { if (!o.hasAttribute('data-create')) o.remove(); });
          items.forEach(function (it, i) {
            var o = tpl.content.firstElementChild.cloneNode(true), v = String(it.value != null ? it.value : it.label);
            o.id = p.input.id + '-r-' + i; o.setAttribute('data-value', v); o.setAttribute('data-label', it.label);
            o.setAttribute('aria-selected', chosen.indexOf(v) !== -1 ? 'true' : 'false');
            var d = o.querySelector('[data-desc]'); if (it.description) d.textContent = it.description; else d.remove();
            if (it.image) { var img = document.createElement('img'); img.src = it.image; img.alt = ''; img.loading = 'lazy';
              img.className = 'tw:size-6 tw:shrink-0 tw:rounded-[6px] tw:border tw:border-border tw:object-contain'; o.querySelector('[data-media]').appendChild(img); }
            highlight(o, q.toLowerCase()); p.list.insertBefore(o, p.list.querySelector('[data-empty]'));
          });
        })
        .catch(function () {})
        .then(function () { if (seq === p.root.__seq) { p.root.removeAttribute('data-loading'); filter(p); } });
    }, 200);
  }
  function values(p) {
    if (p.multiple) return Array.prototype.map.call(p.tags.querySelectorAll('[data-sui-tag]'), function (t) { return t.getAttribute('data-value'); });
    return p.hidden.value ? [p.hidden.value] : [];
  }
  function choose(p, o) {
    if (!o || o.getAttribute('aria-disabled') === 'true') return;
    var v = o.getAttribute('data-value'), label = o.getAttribute('data-label'), created = o.hasAttribute('data-create');
    if (p.multiple) {
      var existing = p.tags.querySelector('[data-sui-tag][data-value="' + CSS.escape(v) + '"]');
      if (existing) { existing.remove(); o.setAttribute('aria-selected', 'false'); }
      else {
        var html = p.root.querySelector('template[data-tag]').innerHTML.split('__VALUE__').join(esc(v)).split('__LABEL__').join(esc(label));
        p.tags.insertAdjacentHTML('beforeend', html); o.setAttribute('aria-selected', 'true');
      }
      p.input.value = ''; filter(p); p.input.focus();
    } else {
      opts(p).forEach(function (x) { x.setAttribute('aria-selected', x === o ? 'true' : 'false'); });
      p.hidden.value = v; p.input.value = label; p.root.__chosenLabel = label; close(p);
    }
    if (created) p.root.dispatchEvent(new CustomEvent('sui:combobox-create', { bubbles: true, detail: { value: v } }));
    p.root.dispatchEvent(new CustomEvent('sui:combobox-change', { bubbles: true, detail: { values: values(p) } }));
    (p.hidden || p.input).dispatchEvent(new Event('change', { bubbles: true }));
  }
  document.addEventListener('input', function (e) {
    if (!e.target.matches || !e.target.matches('[data-sui-combobox] [data-input]')) return;
    var p = parts(e.target);
    if (!p.multiple && p.input.value === '') { p.hidden.value = ''; p.root.__chosenLabel = ''; opts(p).forEach(function (x) { x.setAttribute('aria-selected', 'false'); }); }
    open(p); if (p.root.getAttribute('data-url')) fetchRemote(p); filter(p);
  });
  document.addEventListener('focusin', function (e) {
    if (!e.target.matches || !e.target.matches('[data-sui-combobox] [data-input]')) return;
    var p = parts(e.target); if (p.root.getAttribute('data-url') && !p.root.__loaded) { p.root.__loaded = true; fetchRemote(p); } filter(p); open(p);
  });
  document.addEventListener('focusout', function (e) {
    if (!e.target.matches || !e.target.matches('[data-sui-combobox] [data-input]')) return;
    var p = parts(e.target);
    setTimeout(function () {
      if (p.root.contains(document.activeElement) || p.list.contains(document.activeElement)) return;
      close(p);
      if (!p.multiple && p.input.value !== (p.root.__chosenLabel || '')) p.input.value = p.root.__chosenLabel || '';
    }, 120);
  });
  document.addEventListener('mousedown', function (e) {
    var o = e.target.closest('[data-sui-combobox] [role=option]');
    if (o) { e.preventDefault(); choose(parts(o), o); return; }
    var box = e.target.closest('[data-sui-combobox] [data-box]');
    if (box && e.target !== parts(box).input) { e.preventDefault(); var p = parts(box); p.input.focus(); if (p.list.matches(':popover-open')) close(p); else open(p); }
  });
  document.addEventListener('mousemove', function (e) {
    var o = e.target.closest('[data-sui-combobox] [role=option]:not([aria-disabled=true])'); if (o && !o.hasAttribute('data-active')) setActive(parts(o), o);
  });
  document.addEventListener('keydown', function (e) {
    if (!e.target.matches || !e.target.matches('[data-sui-combobox] [data-input]')) return;
    var p = parts(e.target), list = visible(p), cur = list.indexOf(p.list.querySelector('[data-active]'));
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      if (!p.list.matches(':popover-open')) { open(p); filter(p); return; }
      setActive(p, list[e.key === 'ArrowDown' ? Math.min(cur + 1, list.length - 1) : Math.max(cur - 1, 0)]);
    } else if (e.key === 'Enter' && p.list.matches(':popover-open') && list[cur]) { e.preventDefault(); choose(p, list[cur]); }
    else if (e.key === 'Escape') { if (p.list.matches(':popover-open')) { e.preventDefault(); close(p); } }
    else if (e.key === 'Tab') close(p);
    else if (e.key === 'Backspace' && p.multiple && !p.input.value) {
      var tags = p.tags.querySelectorAll('[data-sui-tag]'), last = tags[tags.length - 1];
      if (last) { var v = last.getAttribute('data-value'); last.remove();
        opts(p).forEach(function (o) { if (o.getAttribute('data-value') === v) o.setAttribute('aria-selected', 'false'); });
        p.root.dispatchEvent(new CustomEvent('sui:combobox-change', { bubbles: true, detail: { values: values(p) } })); }
    }
  });
  document.addEventListener('sui:tag-remove', function (e) {
    var root = e.target.closest && e.target.closest('[data-sui-combobox]'); if (!root) return;
    var p = parts(root), v = e.detail.value;
    setTimeout(function () {
      opts(p).forEach(function (o) { if (o.getAttribute('data-value') === v) o.setAttribute('aria-selected', 'false'); });
      p.root.dispatchEvent(new CustomEvent('sui:combobox-change', { bubbles: true, detail: { values: values(p) } }));
    }, 0);
  });
  function reposition() { document.querySelectorAll('[data-sui-combobox] [role=listbox]:popover-open').forEach(function (l) { place(parts(l)); }); }
  window.addEventListener('resize', reposition); window.addEventListener('scroll', reposition, true);
  function init() {
    document.querySelectorAll('[data-sui-combobox]').forEach(function (r) { var p = parts(r); if (!p.multiple) r.__chosenLabel = p.input.value; });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
