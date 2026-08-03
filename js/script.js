const ES = {
  nv1: 'Funciones',
  nv2: 'Privacidad',
  nv3: 'Descargar',
  nv4: 'Apoyar',
  pill: 'Ya está el modo Focus',
  h1a: 'Un toque al día.',
  h1b: 'Mira cómo se llena el año.',
  lede: 'Un registro de hábitos para Android que no da la lata. Marca con un toque, mira un año entero de un vistazo y abre una sesión de concentración cuando un hábito lo pida. Nada sale de tu móvil.',
  cta1: 'Descargar',
  cta2: 'Ver el código',
  c1: 'descargas totales',
  c2: 'estrellas en GitHub',
  c3: 'idiomas y subiendo',
  tag1: 'Funciones',
  h2a: 'Pensada para los días',
  h2b: 'que no te apetece.',
  sub1: 'Tres tipos de hábito, temporizador de concentración, cuatro widgets para la pantalla de inicio y un año que se lee de un vistazo. Todo sin conexión.',
  f1t: 'Cada día, de un vistazo',
  f1b: 'Rachas, calendario del mes y una rejilla con el año entero. Mantén pulsado un día para escribir lo que pasó —una nota, un plan o un logro— y aparece como un punto de color.',
  d1: 'Nota',
  d2: 'Planificada',
  d3: 'Completada',
  f2t: 'Con temporizador de concentración',
  f2b: 'Elige un hábito y una duración, o simplemente empieza. Rondas pomodoro, tres esferas, seis escenas y sonido. Los pasos de tu hábito se convierten en la lista de la sesión.',
  k4: '25 min',
  k5: '4 rondas',
  k6: '6 escenas',
  f3t: 'No solo sí o no',
  f3b: 'Cuenta vasos de agua o páginas leídas, divide un hábito en pasos, o sigue uno que quieras evitar: ahí cada día limpio suma a tu favor.',
  k1: '8 vasos',
  k2: '20 páginas',
  k3: '3 pasos',
  f4t: 'Dos apps en una',
  f4b: 'Cambia entre Clásico y Minimal con un toque: tarjetas y color, o líneas finas y calma. Los mismos datos, vestidos a tu gusto.',
  sw1: 'Clásico',
  sw2: 'Minimal',
  tag2: 'Tus datos',
  h3a: 'Tus hábitos no son',
  h3b: 'asunto de nadie más.',
  p1t: 'Sin cuenta',
  p1b: 'La abres y empiezas. No hay nada que registrar.',
  p2t: 'Sin red',
  p2b: 'Funciona en un avión. No se sube nada, nunca.',
  p3t: 'Sin anuncios',
  p3b: 'Ni banners, ni ofertas, ni muro de pago.',
  p4t: 'Tus copias',
  p4b: 'Exporta cuando quieras, a la carpeta que elijas.',
  st1: 'Me cansé de que las apps<br />de hábitos me pidieran cuenta.',
  st2: 'Así que hice la que yo quería: silenciosa, rápida, sin conexión y gratis. Sin rachas secuestradas tras una suscripción, sin notificaciones suplicando que vuelvas, sin un panel vendiéndome mis propios datos.',
  st3: 'Es código abierto con licencia GPLv3 y la traduce gente que la usa. Si le falta algo que necesitas, el registro de incidencias está ahí mismo.',
  cta1b: 'Descargar Streak',
  tag3: 'Descargar',
  h4: 'Gratis, de código abierto, y así seguirá.',
  tag4: 'Apoyar',
  h5: 'Gratis siempre. Viva gracias a ti.',
  sub2: 'No hay versión de pago ni nada que comprar dentro de la app. Si Streak te sirve, cualquiera de estas tres cosas la mantiene en marcha.',
  s1t: 'Invítame a un café',
  s1b: 'Un pago único, sin suscripción. Ayuda a que siga sacando versiones en mi tiempo libre.',
  s2t: 'Dale una estrella al repo',
  s2b: 'No cuesta nada y es como la mayoría de la gente acaba encontrando la app.',
  s3t: 'Abre una incidencia o un PR',
  s3b: 'Informa de un fallo, pide una función, traduce una cadena o corrige una errata.',
  fn2: 'Traducir',
  fn3: 'Reportar un fallo',
  fc: 'Hecha por',
};

const EN = {};
document.querySelectorAll('[data-i18n]').forEach((el) => {
  EN[el.dataset.i18n] = el.innerHTML;
});

const store = (key, value) => {
  try {
    if (value === undefined) return localStorage.getItem(key);
    localStorage.setItem(key, value);
  } catch {
    return null;
  }
  return value;
};

function paint(code) {
  const dict = code === 'es' ? ES : EN;
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const text = dict[el.dataset.i18n];
    if (!text) return;
    const svg = el.querySelector('svg');
    el.innerHTML = text;
    if (svg) el.appendChild(svg);
  });
  document.documentElement.lang = code;
  document.querySelectorAll('#lang span').forEach((el) => {
    el.classList.toggle('is-on', el.dataset.lang === code);
  });
  store('streak-lang', code);
}

let lang = store('streak-lang') || (navigator.language || '').slice(0, 2).toLowerCase();
if (lang !== 'es') lang = 'en';
paint(lang);

document.getElementById('lang').addEventListener('click', () => {
  lang = lang === 'es' ? 'en' : 'es';
  paint(lang);
});

const bar = document.querySelector('.bar');
const onScroll = () => bar.classList.toggle('is-small', window.scrollY > 24);
addEventListener('scroll', onScroll, { passive: true });
onScroll();

const calm = matchMedia('(prefers-reduced-motion: reduce)').matches;

document.querySelectorAll('a[href^="#"]').forEach((link) => {
  link.addEventListener('click', (event) => {
    const target = document.querySelector(link.getAttribute('href'));
    if (!target) return;
    event.preventDefault();
    target.scrollIntoView({ behavior: calm ? 'auto' : 'smooth', block: 'start' });
  });
});

const io = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    entry.target.classList.add('in');
    io.unobserve(entry.target);
  });
}, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });

document.querySelectorAll('.reveal').forEach((el) => io.observe(el));

document.querySelectorAll('.hero .reveal, .sec > .reveal, .bento, .rail').forEach((group) => {
  const stagger = group.classList.contains('bento') || group.classList.contains('rail')
    ? [...group.children]
    : [group];
  stagger.forEach((el, i) => {
    el.style.transitionDelay = `${i * 90}ms`;
  });
});

function tickTo(nodes, from, to) {
  if (!nodes.length || !to) return;
  const start = performance.now();
  const step = (now) => {
    const t = calm ? 1 : Math.min(1, (now - start) / 1400);
    const eased = 1 - (1 - t) ** 3;
    const value = Math.round(from + (to - from) * eased).toLocaleString();
    nodes.forEach((node) => { node.textContent = value; });
    if (t < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

function counter(name) {
  const nodes = [...document.querySelectorAll(`[data-count="${name}"]`)];
  const saved = Number(store(`streak-${name}`)) || 0;
  nodes.forEach((node) => { node.textContent = saved ? saved.toLocaleString() : '—'; });
  return (value) => {
    if (typeof value !== 'number' || value === saved) return;
    store(`streak-${name}`, value);
    tickTo(nodes, saved, value);
  };
}

const setStars = counter('stars');
const setDownloads = counter('downloads');

fetch('https://api.github.com/repos/InlitX/streak')
  .then((res) => (res.ok ? res.json() : null))
  .then((repo) => setStars(repo && repo.stargazers_count))
  .catch(() => {});

fetch('https://api.github.com/repos/InlitX/streak/releases?per_page=100')
  .then((res) => (res.ok ? res.json() : null))
  .then((releases) => {
    if (!Array.isArray(releases)) return;
    let total = 0;
    releases.forEach((release) => {
      (release.assets || []).forEach((asset) => { total += asset.download_count || 0; });
    });
    setDownloads(total);
  })
  .catch(() => {});

const heat = document.getElementById('heat');
const COLS = 30;
const ROWS = 7;
const cells = [];

for (let i = 0; i < COLS * ROWS; i += 1) {
  const cell = document.createElement('i');
  heat.appendChild(cell);
  cells.push(cell);
}

const level = () => 1 + Math.floor(Math.random() * 4);

const paintCell = (cell, value) => {
  if (value <= 0) {
    cell.style.background = 'rgba(255,255,255,.05)';
    cell.style.boxShadow = 'none';
    return;
  }
  cell.style.background = `rgba(139,92,246,${(0.22 + value * 0.19).toFixed(2)})`;
  cell.style.boxShadow = value >= 4 ? `0 0 ${6 + value * 2}px rgba(139,92,246,.45)` : 'none';
};

cells.forEach((cell) => paintCell(cell, Math.random() > 0.42 ? level() : 0));

if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
  setInterval(() => {
    for (let i = 0; i < 3; i += 1) {
      paintCell(cells[Math.floor(Math.random() * cells.length)], level());
    }
    paintCell(cells[Math.floor(Math.random() * cells.length)], Math.random() > 0.5 ? 0 : 1);
  }, 420);
}
