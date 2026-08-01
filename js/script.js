(function () {
  'use strict';

  const ICONS = {
    flame: '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>',
    lock: '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
    'wifi-off': '<path d="M12 20h.01"/><path d="M8.5 16.42a5 5 0 0 1 7 0"/><path d="M5 12.86a10 10 0 0 1 5.17-2.69"/><path d="M19 12.86a10 10 0 0 0-2-1.52"/><path d="M2 8.82a15 15 0 0 1 4.18-2.64"/><path d="M22 8.82a15 15 0 0 0-11.29-3.76"/><path d="m2 2 20 20"/>',
    gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/>',
    code: '<polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>',
    user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
    'circle-check': '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    grid: '<rect width="7" height="7" x="3" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="14" rx="1.5"/><rect width="7" height="7" x="3" y="14" rx="1.5"/>',
    shapes: '<path d="M8.3 10a.7.7 0 0 1-.626-1.079L11.4 3a.7.7 0 0 1 1.198-.043L16.3 8.9a.7.7 0 0 1-.572 1.1Z"/><rect x="3" y="14" width="7" height="7" rx="1"/><circle cx="17.5" cy="17.5" r="3.5"/>',
    'list-checks': '<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8"/><path d="M13 12h8"/><path d="M13 18h8"/>',
    palm: '<path d="M13 8c0-2.76-2.46-5-5.5-5S2 5.24 2 8h2l1-1 1 1h4"/><path d="M13 7.14A5.82 5.82 0 0 1 16.5 6c3.04 0 5.5 2.24 5.5 5h-3l-1-1-1 1h-3"/><path d="M5.89 9.71c-2.15 2.15-2.3 5.47-.35 7.43l4.24-4.25.7-.7.71-.71 2.12-2.12c-1.95-1.96-5.27-1.8-7.42.35z"/><path d="M11 15.5c.5 2.5-.17 4.5-1 6.5h4c2-5.5-.5-12-1-14"/>',
    'bar-chart': '<path d="M3 3v16a2 2 0 0 0 2 2h16"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
    bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
    palette: '<circle cx="13.5" cy="6.5" r=".5" fill="currentColor"/><circle cx="17.5" cy="10.5" r=".5" fill="currentColor"/><circle cx="8.5" cy="7.5" r=".5" fill="currentColor"/><circle cx="6.5" cy="12.5" r=".5" fill="currentColor"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>',
    download: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>',
    file: '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/>',
    activity: '<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    star: '<path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.12 2.12 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.12 2.12 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.12 2.12 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.12 2.12 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.12 2.12 0 0 0 1.597-1.16z"/>',
    github: '<path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.4 5.4 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4"/><path d="M9 18c-4.51 2-5-2-7-2"/>',
    package: '<path d="M11 21.73a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73z"/><path d="M3.3 7 12 12l8.7-5"/><path d="M12 22V12"/>',
    tag: '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5" fill="currentColor"/>',
    bug: '<path d="m8 2 1.88 1.88"/><path d="M14.12 3.88 16 2"/><path d="M9 7.13v-1a3.003 3.003 0 1 1 6 0v1"/><path d="M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6"/><path d="M12 20v-9"/><path d="M6.53 9C4.6 8.8 3 7.1 3 5"/><path d="M6 13H2"/><path d="M3 21c0-2.1 1.7-3.9 3.8-4"/><path d="M20.97 5c0 2.1-1.6 3.8-3.5 4"/><path d="M22 13h-4"/><path d="M17.2 17c2.1.1 3.8 1.9 3.8 4"/>',
    lightbulb: '<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/>'
  };
  const SVG_OPEN = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">';
  document.querySelectorAll('[data-icon]').forEach(function (el) {
    const name = el.getAttribute('data-icon');
    if (ICONS[name]) el.innerHTML = SVG_OPEN + ICONS[name] + '</svg>';
  });

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function fillHeat(el, count, density) {
    if (!el) return;
    const frag = document.createDocumentFragment();
    for (let i = 0; i < count; i++) {
      const cell = document.createElement('i');
      if (Math.random() < density) {
        const lv = Math.min(1 + Math.floor(Math.pow(Math.random(), 0.6) * 5), 5);
        cell.className = 'lv' + lv;
      }
      frag.appendChild(cell);
    }
    el.appendChild(frag);
  }

  const miniHeat = document.getElementById('miniHeat');
  const bigHeat = document.getElementById('bigHeat');
  fillHeat(miniHeat, 60, 0.72);
  fillHeat(bigHeat, 28, 0.66);

  const allCells = [].concat(
    Array.from(miniHeat ? miniHeat.children : []),
    Array.from(bigHeat ? bigHeat.children : [])
  );
  if (!reduceMotion && allCells.length) {
    setInterval(function () {
      const cell = allCells[Math.floor(Math.random() * allCells.length)];
      const prev = cell.className;
      cell.style.transition = 'background 0.5s ease, box-shadow 0.5s ease';
      cell.className = 'lv' + (1 + Math.floor(Math.random() * 5));
      setTimeout(function () { cell.className = prev; }, 900);
    }, 420);
  }

  const palette = ['#FF3B30', '#FF9500', '#FFCC00', '#7ED321', '#34C759', '#1ABC9C',
    '#26C6DA', '#5AC8FA', '#007AFF', '#5856D6', '#7C3AED', '#BF5AF2', '#FF6EB4', '#8E8E93'];
  const swatches = document.getElementById('swatches');
  if (swatches) {
    palette.forEach(function (c) {
      const s = document.createElement('i');
      s.style.background = c;
      if (c === '#7C3AED') s.classList.add('sel');
      swatches.appendChild(s);
    });
  }

  const reveals = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window) {
    const io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });
    reveals.forEach(function (el, i) {
      if (el.closest('.bento') || el.closest('.shots')) {
        el.style.transitionDelay = (i % 6) * 60 + 'ms';
      }
      io.observe(el);
    });
  } else {
    reveals.forEach(function (el) { el.classList.add('in'); });
  }

  const nav = document.getElementById('nav');
  const onScroll = function () {
    nav.classList.toggle('is-scrolled', window.scrollY > 12);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  const burger = document.getElementById('burger');
  if (burger) {
    burger.addEventListener('click', function () {
      const open = nav.classList.toggle('is-open');
      burger.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    nav.querySelectorAll('.nav__links a').forEach(function (a) {
      a.addEventListener('click', function () {
        nav.classList.remove('is-open');
        burger.setAttribute('aria-expanded', 'false');
      });
    });
  }

  function hapticPop(el) {
    el.classList.remove('is-pop');
    void el.offsetWidth;
    el.classList.add('is-pop');
  }

  const CHECK_SVG = SVG_OPEN + ICONS.check + '</svg>';

  function buildWeek(el, preset) {
    if (!el) return;
    for (let i = 0; i < 7; i++) {
      const b = document.createElement('b');
      b.innerHTML = CHECK_SVG;
      if (preset && preset.indexOf(i) !== -1) b.classList.add('on');
      b.addEventListener('click', function () {
        b.classList.toggle('on');
        b.classList.remove('pop');
        void b.offsetWidth;
        b.classList.add('pop');
      });
      el.appendChild(b);
    }
  }

  buildWeek(document.getElementById('weekRound'), [0, 1, 2, 4]);
  buildWeek(document.getElementById('weekSquare'), [0, 2, 3]);

  document.querySelectorAll('.check-demo li').forEach(function (li) {
    li.addEventListener('click', function () { li.classList.toggle('is-done'); });
  });

  document.querySelectorAll('.chips').forEach(function (group) {
    const chips = group.querySelectorAll('.chip');
    const demo = document.getElementById('typeDemo');
    const show = function (type) {
      if (!demo) return;
      demo.querySelectorAll('[data-panel]').forEach(function (p) {
        p.hidden = p.getAttribute('data-panel') !== type;
      });
    };
    chips.forEach(function (chip, i) {
      if (i === 0) chip.classList.add('sel');
      chip.addEventListener('click', function () {
        chips.forEach(function (c) { c.classList.remove('sel'); });
        chip.classList.add('sel');
        show(chip.getAttribute('data-type'));
      });
    });
  });

  buildWeek(document.querySelector('[data-panel="normal"]'), [0, 1, 3, 4, 5]);
  buildWeek(document.querySelector('[data-panel="avoid"]'), []);

  (function () {
    const glass = document.querySelector('.glass');
    if (!glass) return;
    const water = document.getElementById('glassWater');
    const label = glass.querySelector('.glass__n');
    const GOAL = 8, TRAVEL = 45.2;
    let n = 0;
    glass.addEventListener('click', function () {
      const full = n >= GOAL;
      glass.classList.toggle('spill', full);
      n = full ? 0 : n + 1;
      water.setAttribute('transform', 'translate(0 ' + (TRAVEL * (1 - n / GOAL)).toFixed(2) + ')');
      label.textContent = n + ' / ' + GOAL;
    });
  })();

  if (swatches) {
    swatches.addEventListener('click', function (e) {
      const t = e.target.closest('i');
      if (!t) return;
      swatches.querySelectorAll('i').forEach(function (i) { i.classList.remove('sel'); });
      t.classList.add('sel');
    });
  }

  document.querySelectorAll('.mini-remind__days i').forEach(function (dot) {
    dot.addEventListener('click', function () { dot.classList.toggle('on'); });
  });

  (function () {
    const t = document.getElementById('remindTime');
    if (!t) return;
    const TIMES = ['06:30', '08:00', '12:00', '18:30', '21:00', '22:45'];
    let i = 1;
    t.addEventListener('click', function () {
      i = (i + 1) % TIMES.length;
      t.textContent = TIMES[i];
      t.classList.remove('bump');
      void t.offsetWidth;
      t.classList.add('bump');
    });
  })();

  (function () {
    const btn = document.getElementById('fileDl');
    const box = document.getElementById('miniFile');
    if (!btn || !box) return;
    let busy = false;
    btn.addEventListener('click', function () {
      if (busy) return;
      busy = true;
      btn.classList.add('go');
      setTimeout(function () { box.classList.add('done'); }, 420);
      setTimeout(function () {
        btn.classList.remove('go');
        box.classList.remove('done');
        busy = false;
      }, 1900);
    });
  })();

  function fmtCount(n) {
    return n >= 1000 ? (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k' : String(n);
  }

  function countUp(el, target) {
    if (!el) return;
    if (reduceMotion || target <= 0) { el.textContent = fmtCount(target); return; }
    const dur = 1100, start = performance.now();
    const ease = function (t) { return 1 - Math.pow(1 - t, 3); };
    (function frame(now) {
      const p = Math.min((now - start) / dur, 1);
      el.textContent = fmtCount(Math.round(ease(p) * target));
      if (p < 1) requestAnimationFrame(frame);
    })(start);
  }

  (function () {
    const el = document.getElementById('starCount');
    const hero = document.getElementById('heroStars');
    if (!el && !hero) return;
    const pill = document.getElementById('starPill');
    fetch('https://api.github.com/repos/InlitX/streak')
      .then(function (r) { return r.ok ? r.json() : Promise.reject(); })
      .then(function (d) {
        const n = d.stargazers_count || 0;
        countUp(el, n);
        countUp(hero, n);
      })
      .catch(function () {
        if (el) el.textContent = 'Star';
        if (pill) pill.classList.add('is-fallback');
      });
  })();

  (function () {
    const el = document.getElementById('dlCount');
    const pill = document.getElementById('heroStats');
    if (!el || !pill) return;

    const CACHE_KEY = 'streak.downloads';
    const MAX_AGE = 6 * 60 * 60 * 1000;

    const show = function (target) {
      if (target <= 0) return;
      pill.hidden = false;
      countUp(el, target);
    };

    let cached = null;
    try { cached = JSON.parse(localStorage.getItem(CACHE_KEY) || 'null'); } catch (e) { cached = null; }
    if (cached && Date.now() - cached.at < MAX_AGE) { show(cached.n); return; }

    fetch('https://api.github.com/repos/InlitX/streak/releases?per_page=100')
      .then(function (r) { return r.ok ? r.json() : Promise.reject(); })
      .then(function (releases) {
        let total = 0;
        releases.forEach(function (rel) {
          (rel.assets || []).forEach(function (a) {
            if (/\.apk$/i.test(a.name)) total += a.download_count || 0;
          });
        });
        try { localStorage.setItem(CACHE_KEY, JSON.stringify({ n: total, at: Date.now() })); } catch (e) {}
        show(total);
      })
      .catch(function () {
        if (cached) show(cached.n);
      });
  })();

  const I18N = {
    en: {
      nav_features: 'Features', nav_screens: 'Screenshots', nav_download: 'Download',
      hero_eyebrow: 'Open source · No ads · No tracking',
      hero_title_1: 'Small steps,', hero_title_2: 'every day.',
      hero_sub: 'Streak is a calm, private habit tracker. Log a habit in a single tap, keep your momentum, and watch your streaks grow — no accounts, no subscriptions, nothing leaves your phone.',
      hero_meta_license: 'licensed', hero_meta_platform: 'Android · Flutter', hero_meta_langs: 'English · Español',
      stat_dl: 'total downloads', stat_stars: 'stars on GitHub',
      float_streak: 'day streak', float_grid: 'This year',
      trust_private: 'Fully private', trust_offline: 'Works offline', trust_free: 'Free forever', trust_open: 'Open source', trust_noacc: 'No accounts',
      feat_kicker: 'Everything, nothing more', feat_title: 'Built to feel calm, not demanding',
      f_onetap_t: 'One-tap logging', f_onetap_d: 'Mark today done from the home screen — daily, weekly or monthly goals with a habit “strength” that tracks your consistency.',
      f_heat_t: 'Activity heatmap', f_heat_d: 'A GitHub-style grid for every habit — week, month or year at a glance.',
      f_types_t: 'Three habit types', f_types_d: 'Build good ones, quit bad ones, or hit an amount.',
      type_normal: 'Normal', type_avoid: 'Avoid', type_amount: 'Amount',
      tag_new: 'New',
      f_check_t: 'Checklists', f_check_d: 'Break a habit into steps — the day is done only when every step is ticked. Perfect for a morning routine.',
      check_1: 'Wash face', check_2: 'Brush teeth', check_3: 'Stretch 5 min',
      f_vac_t: 'Vacation mode', f_vac_d: 'Pause a habit while you’re away. Skipped days don’t count as missed and never break your streak.',
      f_stats_t: 'Statistics', f_stats_d: 'Trends, totals and the times of day you’re most consistent.',
      f_remind_t: 'Smart reminders', f_remind_d: 'Per-habit notifications on exactly the days you choose.',
      f_person_t: 'Make it yours', f_person_d: 'Icons, emoji, a full color picker, light/dark themes and home-screen widgets.',
      f_backup_t: 'Backup & restore', f_backup_d: 'Export everything to a portable JSON file. Your data, in your hands.',
      gal_kicker: 'A look inside', gal_title: 'Calm by design',
      cap_today: 'Today', cap_stats: 'Statistics', cap_insights: 'Insights', cap_person: 'Personalize', cap_free: 'Free & private',
      dl_title: 'Start your first streak', dl_sub: 'Install from F-Droid to get automatic updates, or grab the APK directly.',
      dl_note: 'Not on the Play Store. Android may ask you to allow installs the first time.',
      foot_tag: 'Crafted with care and a lot of free time.', foot_releases: 'Releases', foot_issues: 'Report a bug', foot_feature: 'Request a feature', foot_open: 'Open source · GPLv3'
    },
    es: {
      nav_features: 'Funciones', nav_screens: 'Capturas', nav_download: 'Descargar',
      hero_eyebrow: 'Código abierto · Sin anuncios · Sin rastreo',
      hero_title_1: 'Pequeños pasos,', hero_title_2: 'cada día.',
      hero_sub: 'Streak es un rastreador de hábitos tranquilo y privado. Marca un hábito con un solo toque, mantén tu constancia y ve crecer tus rachas — sin cuentas, sin suscripciones, nada sale de tu teléfono.',
      hero_meta_license: 'con licencia', hero_meta_platform: 'Android · Flutter', hero_meta_langs: 'English · Español',
      stat_dl: 'descargas totales', stat_stars: 'estrellas en GitHub',
      float_streak: 'días de racha', float_grid: 'Este año',
      trust_private: 'Totalmente privado', trust_offline: 'Funciona sin conexión', trust_free: 'Gratis para siempre', trust_open: 'Código abierto', trust_noacc: 'Sin cuentas',
      feat_kicker: 'Todo, nada más', feat_title: 'Hecho para calmar, no para exigir',
      f_onetap_t: 'Registro con un toque', f_onetap_d: 'Marca el día desde la pantalla de inicio — metas diarias, semanales o mensuales y una “fuerza” que refleja tu constancia.',
      f_heat_t: 'Mapa de actividad', f_heat_d: 'Una cuadrícula estilo GitHub para cada hábito — semana, mes o año de un vistazo.',
      f_types_t: 'Tres tipos de hábito', f_types_d: 'Crea buenos, deja los malos o alcanza una cantidad.',
      type_normal: 'Normal', type_avoid: 'Evitar', type_amount: 'Cantidad',
      tag_new: 'Nuevo',
      f_check_t: 'Listas de pasos', f_check_d: 'Divide un hábito en pasos — el día solo cuenta cuando marcas todos. Perfecto para una rutina matutina.',
      check_1: 'Lavarse la cara', check_2: 'Cepillarse los dientes', check_3: 'Estirar 5 min',
      f_vac_t: 'Modo vacaciones', f_vac_d: 'Pausa un hábito mientras estás fuera. Los días omitidos no cuentan como fallos y nunca rompen tu racha.',
      f_stats_t: 'Estadísticas', f_stats_d: 'Tendencias, totales y las horas del día en que eres más constante.',
      f_remind_t: 'Recordatorios', f_remind_d: 'Notificaciones por hábito exactamente los días que elijas.',
      f_person_t: 'Hazlo tuyo', f_person_d: 'Iconos, emojis, un selector de color completo, temas claro/oscuro y widgets de inicio.',
      f_backup_t: 'Copia y restauración', f_backup_d: 'Exporta todo a un archivo JSON portable. Tus datos, en tus manos.',
      gal_kicker: 'Un vistazo dentro', gal_title: 'Tranquilo por diseño',
      cap_today: 'Hoy', cap_stats: 'Estadísticas', cap_insights: 'Análisis', cap_person: 'Personaliza', cap_free: 'Libre y privado',
      dl_title: 'Empieza tu primera racha', dl_sub: 'Instala desde F-Droid para tener actualizaciones automáticas, o descarga el APK directamente.',
      dl_note: 'No está en Play Store. Android puede pedirte permiso para instalar la primera vez.',
      foot_tag: 'Hecho con cariño y mucho tiempo libre.', foot_releases: 'Versiones', foot_issues: 'Reportar un fallo', foot_feature: 'Solicitar función', foot_open: 'Código abierto · GPLv3'
    }
  };

  const nodes = document.querySelectorAll('[data-i18n]');
  function applyLang(lang) {
    const dict = I18N[lang] || I18N.en;
    nodes.forEach(function (n) {
      const key = n.getAttribute('data-i18n');
      if (dict[key] != null) n.textContent = dict[key];
    });
    document.documentElement.lang = lang;
    document.querySelectorAll('.lang__opt').forEach(function (o) {
      o.classList.toggle('is-on', o.getAttribute('data-lang') === lang);
    });
    try { localStorage.setItem('streak-lang', lang); } catch (e) {}
  }

  let current = 'en';
  try {
    const saved = localStorage.getItem('streak-lang');
    if (saved) current = saved;
    else if ((navigator.language || '').toLowerCase().startsWith('es')) current = 'es';
  } catch (e) {}
  applyLang(current);

  const langBtn = document.getElementById('langToggle');
  if (langBtn) {
    langBtn.addEventListener('click', function () {
      current = current === 'en' ? 'es' : 'en';
      applyLang(current);
    });
  }
  document.querySelectorAll('.lang__opt').forEach(function (o) {
    o.addEventListener('click', function (ev) {
      ev.stopPropagation();
      current = o.getAttribute('data-lang');
      applyLang(current);
    });
  });
})();
