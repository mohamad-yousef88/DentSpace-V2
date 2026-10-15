/**
 * DentSpace Admin — Client-side enhancement.
 * • Count-up animations
 * • Toast notifications
 * • Mobile sidebar drawer
 * • Confirm modal interceptor
 * • Loading states on form submit
 * Respects prefers-reduced-motion.
 */
(function () {
  'use strict';

  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  // ═══════════════════════════════════════════════════════
  // 1. Count-up
  // ═══════════════════════════════════════════════════════
  function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3); }

  function countUp(el, target, duration) {
    if (prefersReducedMotion) { el.textContent = target.toLocaleString('en-US'); return; }
    const start = performance.now();
    function tick(now) {
      const p = Math.min((now - start) / duration, 1);
      el.textContent = Math.round(target * easeOutCubic(p)).toLocaleString('en-US');
      if (p < 1) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  function initCountUps() {
    document.querySelectorAll('[data-count-to]').forEach(function (el) {
      const target = parseInt(el.dataset.countTo, 10);
      if (isNaN(target)) return;
      const dur = parseInt(el.dataset.countDuration, 10) || 1000;
      countUp(el, target, dur);
    });
  }

  // ═══════════════════════════════════════════════════════
  // 2. Toasts
  // ═══════════════════════════════════════════════════════
  const TOAST_ICONS = {
    success: '<path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>',
    error:   '<path d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>',
    info:    '<path d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>',
  };
  const TOAST_COLORS = {
    success: 'border-s-success text-success',
    error:   'border-s-danger text-danger',
    info:    'border-s-info text-info',
  };

  window.showToast = function (message, kind, duration) {
    kind = kind || 'info';
    duration = duration || 4500;
    const container = document.getElementById('toast-container');
    if (!container) return;

    const el = document.createElement('div');
    el.className = 'toast ' + (TOAST_COLORS[kind] || TOAST_COLORS.info);
    el.setAttribute('role', 'status');
    el.innerHTML =
      '<svg class="w-5 h-5 shrink-0 mt-0.5" fill="none" stroke="currentColor" ' +
      'viewBox="0 0 24 24" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
      (TOAST_ICONS[kind] || TOAST_ICONS.info) + '</svg>' +
      '<span class="text-sm text-content flex-1"></span>' +
      '<button type="button" class="shrink-0 -me-1 w-6 h-6 rounded-lg flex items-center justify-center ' +
      'text-content-tertiary hover:text-content hover:bg-surface-variant transition-colors" ' +
      'aria-label="Close">' +
      '<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" ' +
      'stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6L6 18M6 6l12 12"/></svg>' +
      '</button>';
    el.querySelector('span').textContent = message;

    const remove = function () {
      el.classList.add('leaving');
      el.addEventListener('animationend', function () { el.remove(); }, { once: true });
    };

    el.querySelector('button').addEventListener('click', remove);
    container.appendChild(el);

    if (duration > 0) setTimeout(remove, duration);
  };

  function initServerToasts() {
    const data = document.getElementById('flash-data');
    if (!data) return;
    try {
      const messages = JSON.parse(data.textContent || '[]');
      messages.forEach(function (m, i) {
        setTimeout(function () { window.showToast(m.message, m.kind || 'info'); }, i * 120);
      });
    } catch (e) {}
  }

  // ═══════════════════════════════════════════════════════
  // 3. Mobile sidebar
  // ═══════════════════════════════════════════════════════
  function initMobileSidebar() {
    const drawer   = document.getElementById('mobile-drawer');
    const overlay  = document.getElementById('mobile-drawer-overlay');
    if (!drawer || !overlay) return;

    const open = function () {
      overlay.classList.remove('hidden');
      drawer.classList.remove('-translate-x-full', 'translate-x-full');
      document.body.style.overflow = 'hidden';
    };
    const close = function () {
      const isRtl = document.documentElement.dir === 'rtl';
      drawer.classList.add(isRtl ? 'translate-x-full' : '-translate-x-full');
      overlay.classList.add('hidden');
      document.body.style.overflow = '';
    };

    document.querySelectorAll('[data-mobile-menu-open]').forEach(function (b) {
      b.addEventListener('click', open);
    });
    document.querySelectorAll('[data-mobile-menu-close]').forEach(function (b) {
      b.addEventListener('click', close);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !overlay.classList.contains('hidden')) close();
    });
  }

  // ═══════════════════════════════════════════════════════
  // 4. Confirm modal — data-confirm attribute
  // ═══════════════════════════════════════════════════════
  function initConfirmModal() {
    const modal = document.getElementById('confirm-modal');
    if (!modal) return;

    let pendingForm = null;

    const closeModal = function () { modal.close(); pendingForm = null; };

    modal.querySelectorAll('[data-confirm-cancel]').forEach(function (b) {
      b.addEventListener('click', closeModal);
    });
    modal.addEventListener('cancel', function (e) { e.preventDefault(); closeModal(); });

    modal.querySelector('[data-confirm-ok]').addEventListener('click', function () {
      if (pendingForm) {
        pendingForm.dataset.confirmed = '1';
        pendingForm.submit();
      }
      closeModal();
    });

    document.addEventListener('submit', function (e) {
      const form = e.target;
      if (!(form instanceof HTMLFormElement)) return;
      const msg = form.dataset.confirm;
      if (!msg) return;
      if (form.dataset.confirmed === '1') return;

      e.preventDefault();
      pendingForm = form;

      modal.querySelector('[data-confirm-title]').textContent =
        form.dataset.confirmTitle || (document.documentElement.lang === 'ar' ? 'تأكيد' : 'Confirm');
      modal.querySelector('[data-confirm-message]').textContent = msg;

      const okBtn = modal.querySelector('[data-confirm-ok]');
      okBtn.textContent = form.dataset.confirmOk ||
        (document.documentElement.lang === 'ar' ? 'تأكيد' : 'Confirm');
      okBtn.className = 'btn ' + (form.dataset.confirmDanger === '1' ? 'btn-danger' : 'btn-primary');

      modal.showModal();
    });
  }

  // ═══════════════════════════════════════════════════════
  // 5. Loading states on submit
  // ═══════════════════════════════════════════════════════
  function initLoadingStates() {
    document.addEventListener('submit', function (e) {
      const form = e.target;
      if (!(form instanceof HTMLFormElement)) return;
      if (form.dataset.confirm && form.dataset.confirmed !== '1') return;

      const btn = form.querySelector('button[type="submit"]:not([disabled])');
      if (!btn) return;

      // Defer to allow form to actually submit
      setTimeout(function () {
        btn.classList.add('is-loading');
        btn.disabled = true;
      }, 10);
    });
  }

  // ═══════════════════════════════════════════════════════
  // 6. Page title highlight from sidebar
  // ═══════════════════════════════════════════════════════
  function initPageTitle() {
    const el = document.getElementById('page-title');
    if (el && !el.textContent.trim()) {
      el.textContent = document.title.split(' · ')[0];
    }
  }

  // ═══════════════════════════════════════════════════════
  // Bootstrap
  // ═══════════════════════════════════════════════════════
  function init() {
    initCountUps();
    initServerToasts();
    initMobileSidebar();
    initConfirmModal();
    initLoadingStates();
    initPageTitle();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();