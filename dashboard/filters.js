// Oppretter objekt som lagrer aktive filtre (valgte filtre + søketekst)
let activeFilters = {
  themes: new Set(),
  methods: new Set(),
  language: new Set(),
  data: new Set(),
  search: ""
};

// Oppretter konstantliste med filterkategorier
const FILTER_FIELDS = ["themes", "methods", "language", "data"];

// Oppretter lister som lagrer filtre i valgt rekkefølge
const filterSelectionOrder = {
  themes: [],
  methods: [],
  language: [],
  data: []
};

// Oppretter variabler for å overvåke status til popup og siste telleverdi
let currentFilterPopup = null;
let currentFilterPopupAnchor = null;
let outsideClickHandler = null;
let escapeKeyHandler = null;
let lastRenderedCount = null;

// Lager hjelpere for å konvertere felt til tekst og lister
const asText = v => Array.isArray(v) ? v.join(" ") : (v == null ? "" : String(v));
const toArray = v => Array.isArray(v) ? v : (v == null ? [] : [v]);
const MAX_CODE_SNIPPETS = 3;
const MAX_CODE_LINE_CHARS = 220;

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/\'/g, "&#39;");
}

function escapeRegExp(text) {
  return String(text).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function highlightMatch(text, query) {
  const safe = escapeHtml(text);
  if (!query) return safe;
  const re = new RegExp(escapeRegExp(query), "ig");
  return safe.replace(re, match => `<mark class="code-match">${match}</mark>`);
}

function truncateAroundMatch(line, query) {
  if (line.length <= MAX_CODE_LINE_CHARS) return line;
  const lower = line.toLowerCase();
  const q = query.toLowerCase();
  const idx = lower.indexOf(q);
  if (idx === -1) {
    return `${line.slice(0, MAX_CODE_LINE_CHARS - 3)}...`;
  }
  const half = Math.floor((MAX_CODE_LINE_CHARS - 3) / 2);
  let start = Math.max(0, idx - half);
  let end = Math.min(line.length, start + MAX_CODE_LINE_CHARS - 3);
  if (end - start < MAX_CODE_LINE_CHARS - 3) {
    start = Math.max(0, end - (MAX_CODE_LINE_CHARS - 3));
  }
  let out = line.slice(start, end);
  if (start > 0) out = `...${out}`;
  if (end < line.length) out = `${out}...`;
  return out;
}

function parseCodeFiles(project) {
  if (project._codeFiles) return project._codeFiles;
  const codeText = asText(project.code);
  if (!codeText) {
    project._codeFiles = [];
    return project._codeFiles;
  }
  const files = [];
  let current = null;
  for (const line of codeText.split(/\r?\n/)) {
    const match = line.match(/^# file: (.+)$/);
    if (match) {
      current = { file: match[1], lines: [] };
      files.push(current);
      continue;
    }
    if (current) current.lines.push(line);
  }
  project._codeFiles = files;
  return files;
}

function getCodeMatches(project, query) {
  const q = String(query || "").toLowerCase();
  if (!q) return { count: 0, snippets: [] };
  if (project._codeMatchCache && project._codeMatchCache.q === q) {
    return project._codeMatchCache;
  }
  const files = parseCodeFiles(project);
  let count = 0;
  const snippets = [];
  for (const f of files) {
    for (let i = 0; i < f.lines.length; i++) {
      const line = String(f.lines[i] || "");
      if (!line) continue;
      if (line.toLowerCase().includes(q)) {
        count += 1;
        if (snippets.length < MAX_CODE_SNIPPETS) {
          snippets.push({
            file: f.file,
            line: i + 1,
            text: truncateAroundMatch(line, q)
          });
        }
      }
    }
  }
  const result = { q, count, snippets };
  project._codeMatchCache = result;
  return result;
}

// Lager funksjon som lukker popup og fjerner lyttere
function closeFilterPopup() {
  if (!currentFilterPopup) return;
  currentFilterPopup.remove();
  currentFilterPopup = null;
  currentFilterPopupAnchor = null;
  if (outsideClickHandler) {
    document.removeEventListener("click", outsideClickHandler, true);
    outsideClickHandler = null;
  }
  if (escapeKeyHandler) {
    document.removeEventListener("keydown", escapeKeyHandler);
    escapeKeyHandler = null;
  }
}

// Lager funksjon som åpner eller lukker popup ved nytt klikk
function toggleFilterPopup(anchor, field, label, filters, data) {
  if (currentFilterPopup && currentFilterPopupAnchor === anchor) {
    closeFilterPopup();
    return;
  }
  openFilterPopup(anchor, field, label, filters, data);
}

// Lager funksjon som bygger popup og plasserer den ved knappen
function openFilterPopup(anchor, field, label, filters, data) {
  closeFilterPopup();

  const popup = document.createElement("div");
  popup.className = "filter-popup";

  const title = document.createElement("div");
  title.className = "filter-popup-title";
  title.textContent = `${label}: flere filtre`;
  popup.appendChild(title);

  const btnContainer = document.createElement("div");
  btnContainer.className = "filter-popup-btns";

  filters.forEach(value => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "filter-btn";
    btn.textContent = value;
    if (activeFilters[field].has(value)) btn.classList.add("active");
    btn.onclick = ev => {
      ev.preventDefault();
      ev.stopPropagation();
      if (activeFilters[field].has(value)) {
        activeFilters[field].delete(value);
        filterSelectionOrder[field] = filterSelectionOrder[field].filter(v => v !== value);
      } else {
        activeFilters[field].add(value);
        filterSelectionOrder[field] = filterSelectionOrder[field].filter(v => v !== value);
        filterSelectionOrder[field].push(value);
      }
      closeFilterPopup();
      updateFilters(data);
      renderProjects(data);
    };
    btnContainer.appendChild(btn);
  });

  popup.appendChild(btnContainer);
  document.body.appendChild(popup);
  popup.addEventListener("click", ev => ev.stopPropagation());

  // Plasserer popup under knappen
  const rect = anchor.getBoundingClientRect();
  const popupRect = popup.getBoundingClientRect();
  let top = rect.bottom + 8;
  if (top + popupRect.height > window.innerHeight - 16) {
    top = Math.max(16, rect.top - popupRect.height - 8);
  }
  let left = rect.left;
  if (left + popupRect.width > window.innerWidth - 16) {
    left = Math.max(16, window.innerWidth - popupRect.width - 16);
  }

  // Setter popup-posisjon
  popup.style.top = `${top}px`;
  popup.style.left = `${left}px`;

  // Lagre kobling til popup og tilhørende knapp
  currentFilterPopup = popup;
  currentFilterPopupAnchor = anchor;

  // Oppretter lytter for å lukke popup med klikk utenfor
  outsideClickHandler = event => {
    if (!currentFilterPopup) return;
    if (currentFilterPopup.contains(event.target)) return;
    if (event.target === currentFilterPopupAnchor) return;
    closeFilterPopup();
  };
  document.addEventListener("click", outsideClickHandler, true);

  // Oppretter lytter for å lukke popup med esc
  escapeKeyHandler = event => {
    if (event.key === "Escape") {
      closeFilterPopup();
    }
  };
  document.addEventListener("keydown", escapeKeyHandler);
}

// Lager funksjon som sjekker hvert prosjekt: passer det med søket og valgte filtre?
function matchesFilters(project) {
  const searchText = activeFilters.search.toLowerCase();
  const title = asText(project.title).toLowerCase();
  const description = asText(project.description).toLowerCase();
  const authors = toArray(project.authors).map(a => a.toLowerCase());

  // Sjekker om søketeksten matcher relevante felter
  let searchMatch =
    title.includes(searchText) ||
    description.includes(searchText) ||
    authors.some(a => a.includes(searchText)) ||
    toArray(project.themes).some(t => String(t).toLowerCase().includes(searchText)) ||
    toArray(project.methods).some(m => String(m).toLowerCase().includes(searchText)) ||
    toArray(project.data).some(d => String(d).toLowerCase().includes(searchText)) ||
    asText(project.language).toLowerCase().includes(searchText);

  if (!searchMatch && searchText) {
    searchMatch = getCodeMatches(project, searchText).count > 0;
  }

  // Returnerer treff for prosjekter med alle valgte søke- og filterverdier
  return searchMatch && FILTER_FIELDS.every(field => {
    const selected = activeFilters[field];
    if (!selected.size) return true;
    const values = toArray(project[field]);
    return [...selected].every(f => values.includes(f));
  });
}

// Lager funksjon som bygger og rendrer liste med prosjektkort etter aktive filtre
function renderProjects(data) {
  const container = document.getElementById("projects");
  container.innerHTML = "";
  const filtered = data.filter(matchesFilters);

  // Oppdaterer telleren for antall prosjekter
  const counter = document.getElementById("project-counter");
  if (counter) {
    counter.textContent = `${filtered.length} resultat${filtered.length === 1 ? '' : 'er'}`;
    if (lastRenderedCount !== filtered.length) {
      // Restarter puls-animasjonen når trefflisten endres
      counter.classList.remove("counter-pulse");
      // eslint-disable-next-line no-unused-expressions
      counter.offsetWidth;
      counter.classList.add("counter-pulse");
      lastRenderedCount = filtered.length;
    }
  }
  // Sjekker filtrerte prosjekter og oppretter elementer (resultatkort) i UI
  for (const project of filtered) {
    const card = document.createElement("div");
    card.className = "project-card";
    const codeMatches = getCodeMatches(project, activeFilters.search);
    const codeMatchHtml = (activeFilters.search && codeMatches.count) ? `
      <div class="code-matches">
        <div class="code-match-count">${codeMatches.count} treff i kode</div>
        ${codeMatches.snippets.map(s => `
          <div class="code-snippet">
            <div class="code-snippet-meta">${s.file}:${s.line}</div>
            <code>${highlightMatch(s.text, activeFilters.search)}</code>
          </div>
        `).join("")}
      </div>
    ` : "";

    card.innerHTML = `
      <h3>${project.title}</h3>
      <p><strong>Forfatter:</strong> ${toArray(project.authors).join(", ")}</p>
      <p><strong>Programmeringsspråk:</strong> ${toArray(project.language)}</p>
      <p><strong>Data:</strong> ${toArray(project.data).join(", ")}</p>
      <p><strong>Metode:</strong> ${toArray(project.methods).join(", ")}</p>
      <p><strong>Tema:</strong> ${toArray(project.themes).join(", ")}</p>
      <p>${project.description || ""}</p>
      ${codeMatchHtml}
      <p><a href="https://github.com/SVA-OsloMet/kodebib/tree/main/projects/${project.folder}" target="_blank">Finn filer</a></p>
    `;
    container.appendChild(card);
  }
}

// Lager funksjon som tegner alle filtergrupper (språk, data, metode, tema)
function updateFilters(data) {
  closeFilterPopup();
  const filtersContainer = document.getElementById("filters");
  filtersContainer.innerHTML = "";
  renderFilters(data, "language", "Språk");
  renderFilters(data, "data", "Data");
  renderFilters(data, "methods", "Metode");
  renderFilters(data, "themes", "Tema");
}

// Lager funksjon som bygger én filtergruppe i UI-et
function renderFilters(data, field, label) {
  const filtersContainer = document.getElementById("filters");
  const group = document.createElement("div");
  group.className = "filter-group";
  group.innerHTML = `<h4>${label}</h4>`;

  // Sjekker aktive filtre og fjerner utilgjengelige: bare relevante filtre vises
  const filteredData = data.filter(project => {
    return FILTER_FIELDS.every(f => {
      const selected = activeFilters[f];
      if (!selected.size) return true;
      const values = toArray(project[f]);
      return [...selected].every(val => values.includes(val));
    });
  });

  // Teller hvor ofte hvert filtervalg forekommer i resultatlisten
  const counts = {};
  for (const p of filteredData) {
    for (const v of toArray(p[field])) {
      if (v) counts[v] = (counts[v] || 0) + 1;
    }
  }

  // Sorterer filtervalg etter antall treff først; fallback til alfabetisk
  const allFilters = Object.keys(counts).sort((a, b) =>
    counts[b] - counts[a] || a.localeCompare(b)
  );
  const selectedOrdered = filterSelectionOrder[field]
    .filter(value => activeFilters[field].has(value));
  filterSelectionOrder[field] = selectedOrdered.slice();
  const selectedInCounts = selectedOrdered.filter(value => counts[value]);
  const selectedNotInCounts = selectedOrdered.filter(value => !counts[value]);
  const orderedSelected = [...selectedInCounts, ...selectedNotInCounts];
  const remainingFilters = allFilters.filter(value => !activeFilters[field].has(value));
  const maxPerLine = 4;
  const visibleLimit = Math.max(maxPerLine, orderedSelected.length);
  const visibleValues = [];
  const seen = new Set();

  // Sorterer valgte filtre rekkefølgen de er valgt i
  for (const value of orderedSelected) {
    if (seen.has(value)) continue;
    visibleValues.push(value);
    seen.add(value);
  }
  // Fyller listen med resterende filtre til maksgrensen
  for (const value of remainingFilters) {
    if (visibleValues.length >= visibleLimit) break;
    if (seen.has(value)) continue;
    visibleValues.push(value);
    seen.add(value);
  }

  // Oppretter container for filterknappene
  const btnContainer = document.createElement("div");
  btnContainer.className = "filter-btn-container";

  // Viser bare de første filtrene som skal være synlig
  visibleValues.forEach(value => {
    const btn = document.createElement("button");
    btn.className = "filter-btn";
    btn.textContent = value;
    if (activeFilters[field].has(value)) btn.classList.add("active");
    btn.onclick = () => {
      if (activeFilters[field].has(value)) {
        activeFilters[field].delete(value);
        filterSelectionOrder[field] = filterSelectionOrder[field].filter(v => v !== value);
      } else {
        activeFilters[field].add(value);
        filterSelectionOrder[field] = filterSelectionOrder[field].filter(v => v !== value);
        filterSelectionOrder[field].push(value);
      }
      updateFilters(data);
      renderProjects(data);
    };
    btnContainer.appendChild(btn);
  });
  group.appendChild(btnContainer);

  // Viser "og x flere" når flere uvalgte filtre finnes
  const hiddenFilters = remainingFilters.filter(value => !visibleValues.includes(value));
  let more;
  if (hiddenFilters.length) {
    more = document.createElement("button");
    more.type = "button";
    more.className = "filter-text-more";
    more.textContent = `og ${hiddenFilters.length} flere filtre`;
    more.onclick = ev => {
      ev.preventDefault();
      ev.stopPropagation();
      toggleFilterPopup(more, field, label, hiddenFilters, data);
    };
  } else {
    more = document.createElement("div");
    more.className = "filter-text-more placeholder";
    more.innerHTML = "&nbsp;";
  }
  group.appendChild(more);

  filtersContainer.appendChild(group);
}

// Hent prosjektdata og initialiser grensesnittet
fetch("dashboard/projects.json")
  .then(res => res.json())
  .then(data => {
    renderProjects(data);
    updateFilters(data);
    document.getElementById("search-box").addEventListener("input", e => {
      activeFilters.search = e.target.value;
      renderProjects(data);
    });
  });
