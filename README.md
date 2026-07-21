# Streak — web

A self-contained static website for the app. Lives on the **`web` branch**
only, so `main` stays clean.

```
├── index.html      # the page (bilingual EN/ES, no build step)
├── css/
│   └── styles.css  # all styling — dark, violet, heatmap motif
├── js/
│   └── script.js   # heatmap animation, scroll reveals, language toggle
└── assets/         # logo, app screenshots and store badges
```

No framework, no build — just open `index.html`, or host it anywhere static.

## Preview locally

```bash
python -m http.server 8000   # then open http://localhost:8000
```
