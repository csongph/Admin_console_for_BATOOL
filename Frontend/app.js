/* ============================================================
   BA Tool — Admin Console  |  app.js
   ============================================================ */

'use strict';

function getDefaultApiUrl() {
  const host = window.location.hostname;
  if (host === '127.0.0.1' || host === 'localhost') {
    return `${window.location.protocol}//${host}:8000`;
  }
  return 'http://localhost:8000';
}

const DEFAULT_API_URL = getDefaultApiUrl();
const API_URL = (
  window.BA_API_URL ||
  window.API_URL ||
  localStorage.getItem('ba_api_url') ||
  DEFAULT_API_URL
).replace(/\/$/, '');

// ════════════════════════════════════════════════════════════
//  API + TOKEN REFRESH
// ════════════════════════════════════════════════════════════

function _getToken() {
  return localStorage.getItem('ba_token') || sessionStorage.getItem('ba_token');
}

function _saveToken(token, remember) {
  if (remember) localStorage.setItem('ba_token', token);
  else          sessionStorage.setItem('ba_token', token);
}

async function _refreshToken() {
  const token = _getToken();
  if (!token) return false;
  try {
    const res = await fetch(API_URL + '/api/auth/refresh', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    });
    if (!res.ok) return false;
    const data = await res.json();
    const newToken = data?.data?.access_token;
    if (!newToken) return false;
    const inLocal = !!localStorage.getItem('ba_token');
    _saveToken(newToken, inLocal);
    return true;
  } catch {
    return false;
  }
}

async function apiCall(path, options = {}) {
  const token = _getToken();
  let res;
  try {
    res = await fetch(API_URL + path, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(options.headers || {}),
      },
    });
  } catch (error) {
    throw new Error(`${error.message} (${API_URL + path})`);
  }
  const data = await res.json();

  if (res.status === 401) {
    const refreshed = await _refreshToken();
    if (refreshed) {
      return apiCall(path, options);
    }
    localStorage.removeItem('ba_token');
    localStorage.removeItem('ba_session');
    sessionStorage.removeItem('ba_token');
    sessionStorage.removeItem('ba_session');
    if (typeof doLogout === 'function') doLogout();
    throw new Error('Session expired');
  }

  if (!res.ok) throw new Error(data.detail || data.message || `HTTP ${res.status}`);
  return data;
}

const TOKEN_REFRESH_INTERVAL = 55 * 60 * 1000;
setInterval(async () => {
  if (_getToken()) await _refreshToken();
}, TOKEN_REFRESH_INTERVAL);


// ════════════════════════════════════════════════════════════
//  THEME
// ════════════════════════════════════════════════════════════

(function initTheme() {
  const saved = localStorage.getItem('ba_theme');
  if (saved) document.documentElement.setAttribute('data-theme', saved);
})();

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('ba_theme', theme);
  const settingsCb = document.getElementById('settingsThemeToggle');
  if (settingsCb) settingsCb.checked = (theme === 'light');
}

// ════════════════════════════════════════════════════════════
//  MOBILE SIDEBAR
// ════════════════════════════════════════════════════════════

const sidebar  = document.getElementById('sidebar');
const mainWrap = document.getElementById('mainWrap');

let sidebarOverlay = document.querySelector('.sidebar-overlay');
if (!sidebarOverlay) {
  sidebarOverlay = document.createElement('div');
  sidebarOverlay.className = 'sidebar-overlay';
  document.body.appendChild(sidebarOverlay);
}

function isMobile() { return window.innerWidth <= 768; }
function openMobileSidebar()  { sidebar.classList.add('mobile-open');    sidebarOverlay.classList.add('active');    document.body.style.overflow = 'hidden'; }
function closeMobileSidebar() { sidebar.classList.remove('mobile-open'); sidebarOverlay.classList.remove('active'); document.body.style.overflow = ''; }

sidebarOverlay.addEventListener('click', closeMobileSidebar);

const sidebarToggle = document.getElementById('sidebarToggle');
if (sidebarToggle) {
  sidebarToggle.addEventListener('click', () => {
    if (isMobile()) {
      sidebar.classList.contains('mobile-open') ? closeMobileSidebar() : openMobileSidebar();
    } else {
      const collapsed = sidebar.classList.toggle('collapsed');
      mainWrap.classList.toggle('expanded', collapsed);
    }
  });
}
window.addEventListener('resize', () => { if (!isMobile()) { closeMobileSidebar(); document.body.style.overflow = ''; } });

// ════════════════════════════════════════════════════════════
//  NAVIGATION
// ════════════════════════════════════════════════════════════

function navigate(page) {
  document.querySelectorAll('.page').forEach(p => p.classList.add('hidden'));
  const target = document.getElementById('page-' + page);
  if (target) target.classList.remove('hidden');

  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const activeNav = document.querySelector(`.nav-item[data-page="${page}"]`);
  if (activeNav) activeNav.classList.add('active');

  const bcPage = document.getElementById('bcPage');
  if (bcPage) {
    const labels = { dashboard:'Dashboard', mapping:'Mapping Manager', databases:'Database Registry', sessions:'Session Monitor', logs:'Log Viewer', settings:'Settings', activity:'Update Activity' };
    bcPage.textContent = labels[page] || page;
  }
  if (isMobile()) closeMobileSidebar();
}

document.querySelectorAll('.nav-item[data-page]').forEach(item => {
  item.addEventListener('click', e => { e.preventDefault(); navigate(item.dataset.page); });
});

// ════════════════════════════════════════════════════════════
//  THEME TOGGLE
// ════════════════════════════════════════════════════════════

const themeToggle = document.getElementById('themeToggle');
if (themeToggle) {
  themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    applyTheme(isDark ? 'light' : 'dark');
  });
}

function toggleThemeFromSettings(checkbox) {
  applyTheme(checkbox.checked ? 'light' : 'dark');
}

document.querySelector('.nav-item[data-page="settings"]')?.addEventListener('click', () => {
  const theme = document.documentElement.getAttribute('data-theme') || 'dark';
  const cb = document.getElementById('settingsThemeToggle');
  if (cb) cb.checked = (theme === 'light');
});

// ════════════════════════════════════════════════════════════
//  AVATAR DROPDOWN
// ════════════════════════════════════════════════════════════

function toggleAvatarMenu() { document.getElementById('avatarDropdown')?.classList.toggle('hidden'); }
function closeAvatarMenu()  { document.getElementById('avatarDropdown')?.classList.add('hidden'); }
document.addEventListener('click', e => {
  const wrap = document.getElementById('avatarWrap');
  if (wrap && !wrap.contains(e.target)) closeAvatarMenu();
});

// ════════════════════════════════════════════════════════════
//  TOAST
// ════════════════════════════════════════════════════════════

const toastContainer = document.getElementById('toastContainer');
function showToast(message, type = 'info') {
  if (!toastContainer) return;
  const icons = { success:'✓', error:'✕', warn:'⚠', info:'ℹ' };
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span class="toast-icon">${icons[type]||icons.info}</span><span class="toast-msg">${message}</span>`;
  toastContainer.appendChild(toast);
  setTimeout(() => { toast.classList.add('out'); setTimeout(() => toast.remove(), 220); }, 3000);
}

// ════════════════════════════════════════════════════════════
//  MODAL
// ════════════════════════════════════════════════════════════

function openModal(id)  { const el = document.getElementById(id); if (el) el.classList.remove('hidden'); }
function closeModal(id) { const el = document.getElementById(id); if (el) el.classList.add('hidden'); }

document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.classList.add('hidden'); });
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') { document.querySelectorAll('.modal-overlay:not(.hidden)').forEach(m => m.classList.add('hidden')); closeAvatarMenu(); }
});

// ════════════════════════════════════════════════════════════
//  DASHBOARD
// ════════════════════════════════════════════════════════════

async function refreshDashboard() {
  try {
    const start = Date.now();
    const [health, dbsRes, mappingsRes, sessionsRes, logsRes] = await Promise.allSettled([
      apiCall('/api/health'),
      apiCall('/api/databases'),
      apiCall('/api/mappings'),
      apiCall('/api/sessions'),
      apiCall('/api/logs'),
    ]);
    const ping = Date.now() - start;

    const cards = document.querySelectorAll('.status-card');
    const healthOk = health.status === 'fulfilled' && health.value?.success;
    if (cards[0]) {
      cards[0].querySelector('.sc-val').textContent        = healthOk ? 'Online' : 'Error';
      cards[0].querySelector('.sc-ping').textContent       = `${ping} ms`;
      cards[0].querySelector('.sc-indicator').className    = `sc-indicator ${healthOk ? 'online' : 'offline'}`;
    }

    const statusDot   = document.querySelector('.status-dot');
    const statusLabel = document.querySelector('.status-label');
    if (statusDot)   statusDot.className    = `status-dot ${healthOk ? 'online' : 'offline'}`;
    if (statusLabel) statusLabel.textContent = healthOk ? 'System Online' : 'System Offline';

    const metrics    = document.querySelectorAll('.metric-card');
    const dbList     = dbsRes.status     === 'fulfilled' ? (dbsRes.value?.data     || []) : [];
    const mappingList = mappingsRes.status === 'fulfilled' ? (mappingsRes.value?.data || []) : [];

    if (metrics[0]) { metrics[0].querySelector('.metric-val').textContent = dbList.length || '-'; metrics[0].querySelector('.metric-sub').textContent = dbList.map(d => d.name).join(', ') || '-'; }
    if (metrics[1]) { metrics[1].querySelector('.metric-val').textContent = mappingList.length || '-'; metrics[1].querySelector('.metric-sub').textContent = `${mappingList.length} conversion rules`; }

    const sessionPayload = sessionsRes.status === 'fulfilled' ? (sessionsRes.value?.data || {}) : {};
    const sessionStats   = sessionPayload.stats    || { active: 0, warning: 0, expired: 0 };
    const sessionList    = sessionPayload.sessions || [];
    const today          = new Date().toISOString().slice(0, 10);
    const createdToday   = sessionList.filter(s => s.created?.startsWith(today)).length;
    if (metrics[2]) { metrics[2].querySelector('.metric-val').textContent = sessionStats.active + sessionStats.warning; metrics[2].querySelector('.metric-sub').textContent = `${createdToday} created today`; }

    const logList          = logsRes.status === 'fulfilled' ? (logsRes.value?.data || []) : [];
    const conversionsToday = logList.filter(l => l.message?.includes('Convert') && l.timestamp?.startsWith(today)).length;
    const warningsToday    = logList.filter(l => l.level === 'WARNING' && l.timestamp?.startsWith(today)).length;
    if (metrics[3]) { metrics[3].querySelector('.metric-val').textContent = conversionsToday; metrics[3].querySelector('.metric-sub').textContent = warningsToday ? `⚠ ${warningsToday} warning(s) today` : 'No warnings today'; }

    const coverageList = document.getElementById('dbCoverageList');
    if (coverageList && dbList.length && mappingList.length) {
      const pairCount = {};
      mappingList.forEach(m => { const key = (m.src_db || '').toLowerCase(); pairCount[key] = (pairCount[key] || 0) + 1; });
      const total = Math.max(...Object.values(pairCount), 1);
      coverageList.innerHTML = dbList.map(db => {
        const key = (db.key || db.name || '').toLowerCase();
        const pct = Math.round(((pairCount[key] || 0) / total) * 100);
        return `<div class="db-cov-item"><span class="db-cov-name">${db.name}</span><div class="db-cov-bar"><div class="db-cov-fill" style="width:${pct}%"></div></div><span class="db-cov-pct">${pct}%</span></div>`;
      }).join('');
    }

    const activityFeed = document.getElementById('activityFeed');
    if (activityFeed && logList.length) {
      const recent = [...logList].reverse().slice(0, 8);
      activityFeed.innerHTML = recent.map(l => {
        const level    = (l.level || 'INFO').toUpperCase();
        const dotClass = level === 'WARNING' ? 'warn' : level === 'ERROR' ? 'error' : 'success';
        return `<div class="activity-item"><div class="activity-dot ${dotClass}"></div><div class="activity-body"><div class="activity-msg">${l.message}</div><div class="activity-time">${l.timestamp}</div></div></div>`;
      }).join('');
    }

    showToast('Dashboard refreshed', 'success');
  } catch (e) {
    showToast('Refresh failed: ' + e.message, 'error');
  }
}

// ════════════════════════════════════════════════════════════
//  MAPPING MANAGER
// ════════════════════════════════════════════════════════════

let mappingData = [];
let mappingCurrentPage = 1;
const MAPPING_PAGE_SIZE = 8;
let selectedMappings = new Set();

// ── normMapping: map API response → internal object ──────────────────────────
// DB columns: src_db, source_type, raw_type, logical_type, master_type,
//             dest_db, final_type, confidence, status, updated
function normMapping(m) {
  return {
    id:          m.id,
    srcDb:       m.src_db,
    sourceType:  m.source_type   || '',   // Avro base type e.g. int, long, string
    rawType:     m.raw_type,
    logicalType: m.logical_type,
    masterType:  m.master_type,
    destDb:      m.dest_db,
    finalType:   m.final_type,
    confidence:  m.confidence    ?? 100,
    status:      m.status,
    updated:     m.updated,
  };
}

async function fetchMappings() {
  try {
    const data = await apiCall('/api/mappings');
    mappingData = (data.data || []).map(normMapping);
    const badge = document.querySelector('.nav-item[data-page="mapping"] .nav-badge');
    if (badge) badge.textContent = mappingData.length;
    populateMappingFilters();
    renderMappingTable();
  } catch (e) { showToast('Failed to load mappings: ' + e.message, 'error'); }
}

function populateMappingFilters() {
  const srcDbs  = [...new Set(mappingData.map(m => m.srcDb).filter(Boolean))].sort();
  const destDbs = [...new Set(mappingData.map(m => m.destDb).filter(Boolean))].sort();
  const srcSel  = document.getElementById('filterSrcDb');
  const destSel = document.getElementById('filterDestDb');
  if (srcSel)  { const cur = srcSel.value;  srcSel.innerHTML  = '<option value="">All Source DBs</option>' + srcDbs.map(db  => `<option value="${db}"  ${db===cur?'selected':''}>${db}</option>`).join(''); }
  if (destSel) { const cur = destSel.value; destSel.innerHTML = '<option value="">All Dest DBs</option>'   + destDbs.map(db => `<option value="${db}" ${db===cur?'selected':''}>${db}</option>`).join(''); }
}

function getFilteredMappings() {
  const search = (document.getElementById('mappingSearch')?.value || '').toLowerCase();
  const srcDb  = document.getElementById('filterSrcDb')?.value  || '';
  const destDb = document.getElementById('filterDestDb')?.value || '';
  const status = document.getElementById('filterStatus')?.value || '';
  return mappingData.filter(m =>
    (!search || [m.srcDb,m.sourceType,m.rawType,m.logicalType,m.masterType,m.finalType].some(v => (v||'').toLowerCase().includes(search))) &&
    (!srcDb  || m.srcDb  === srcDb)  &&
    (!destDb || m.destDb === destDb) &&
    (!status || m.status === status)
  );
}

function renderMappingTable() {
  const filtered   = getFilteredMappings();
  const totalPages = Math.max(1, Math.ceil(filtered.length / MAPPING_PAGE_SIZE));
  if (mappingCurrentPage > totalPages) mappingCurrentPage = 1;
  const start = (mappingCurrentPage - 1) * MAPPING_PAGE_SIZE;
  const page  = filtered.slice(start, start + MAPPING_PAGE_SIZE);
  const tbody = document.getElementById('mappingBody');
  if (!tbody) return;
  if (!page.length) {
    tbody.innerHTML = `<tr><td colspan="13" style="text-align:center;padding:32px;color:var(--text3)">No mapping rules found</td></tr>`;
  } else {
    tbody.innerHTML = page.map(m => `
      <tr>
        <td class="th-check"><input type="checkbox" ${selectedMappings.has(m.id)?'checked':''} onchange="toggleSelect(${m.id},this.checked)" /></td>
        <td class="td-name">${m.srcDb}</td>
        <td style="font-family:var(--mono);font-size:11px;color:var(--text3)">${m.sourceType}</td>
        <td>${m.rawType}</td>
        <td>${m.logicalType}</td>
        <td>${m.masterType}</td>
        <td>${m.destDb}</td>
        <td>${m.finalType}</td>
        <td><div class="confidence-bar"><div class="conf-track"><div class="conf-fill" style="width:${m.confidence}%"></div></div><span class="conf-txt">${m.confidence}%</span></div></td>
        <td><span class="badge badge-${m.status}">${m.status}</span></td>
        <td>${m.updated}</td>
        <td>${(_currentRole === 'admin' || _currentRole === 'editor') ? `<div class="row-actions"><button class="row-btn" title="Edit" onclick="editMapping(${m.id})">✎</button>${_currentRole === 'admin' ? `<button class="row-btn danger" title="Delete" onclick="deleteMapping(${m.id})">✕</button>` : ''}</div>` : ''}</td>
      </tr>`).join('');
  }
  const countEl = document.getElementById('mappingCount');
  if (countEl) countEl.textContent = `Showing ${filtered.length} rules`;
  renderMappingPagination(totalPages);
  updateBulkBar();
}

function renderMappingPagination(totalPages) {
  const pag = document.getElementById('mappingPagination');
  if (!pag) return;
  let html = `<button class="page-btn" onclick="goMappingPage(${mappingCurrentPage-1})" ${mappingCurrentPage===1?'disabled':''}>‹</button>`;
  for (let i = 1; i <= totalPages; i++) html += `<button class="page-btn ${i===mappingCurrentPage?'active':''}" onclick="goMappingPage(${i})">${i}</button>`;
  html += `<button class="page-btn" onclick="goMappingPage(${mappingCurrentPage+1})" ${mappingCurrentPage===totalPages?'disabled':''}>›</button>`;
  pag.innerHTML = html;
}

function goMappingPage(p) {
  const filtered   = getFilteredMappings();
  const totalPages = Math.max(1, Math.ceil(filtered.length / MAPPING_PAGE_SIZE));
  if (p < 1 || p > totalPages) return;
  mappingCurrentPage = p;
  renderMappingTable();
}

function filterMappings() { mappingCurrentPage = 1; selectedMappings.clear(); renderMappingTable(); }

function toggleSelect(id, checked)  { checked ? selectedMappings.add(id) : selectedMappings.delete(id); updateBulkBar(); }
function toggleAll(checkbox) {
  const filtered = getFilteredMappings();
  const start    = (mappingCurrentPage - 1) * MAPPING_PAGE_SIZE;
  filtered.slice(start, start + MAPPING_PAGE_SIZE).forEach(m => { checkbox.checked ? selectedMappings.add(m.id) : selectedMappings.delete(m.id); });
  renderMappingTable();
}
function updateBulkBar() {
  const bar     = document.getElementById('tableBulk');
  const countEl = document.getElementById('bulkCount');
  if (!bar) return;
  const count = selectedMappings.size;
  bar.style.display = count > 0 ? 'flex' : 'none';
  if (countEl) countEl.textContent = `${count} selected`;
}

// ════════════════════════════════════════════════════════════
//  SEARCHABLE SELECT  (custom dropdown — no blur/change race)
// ════════════════════════════════════════════════════════════

let _ssOptions = {};
let _ssActive  = null; // id of currently open dropdown

/* Close all open dropdowns */
function _ssCloseAll(exceptId) {
  document.querySelectorAll('.ss-list').forEach(el => {
    if (el.dataset.ssId !== exceptId) {
      el.classList.add('hidden');
    }
  });
  if (_ssActive && _ssActive !== exceptId) _ssActive = null;
}

/* Close on outside click */
document.addEventListener('mousedown', (e) => {
  if (!e.target.closest('.searchable-select-wrap')) {
    _ssCloseAll(null);
    _ssActive = null;
  }
});

/* Build / rebuild the custom list element for a given id */
function _ssBuildList(id) {
  const wrap = document.querySelector(`.searchable-select-wrap[data-ss="${id}"]`);
  if (!wrap) return null;
  let list = wrap.querySelector('.ss-list');
  if (!list) {
    list = document.createElement('ul');
    list.className = 'ss-list hidden';
    list.dataset.ssId = id;
    wrap.appendChild(list);
  }
  return list;
}

function _ssRenderList(id, opts) {
  const list = _ssBuildList(id);
  if (!list) return;
  if (!opts || opts.length === 0) {
    list.innerHTML = '<li class="ss-empty">No results</li>';
    return;
  }
  list.innerHTML = opts.map(o =>
    `<li class="ss-item" data-value="${o.value}">${o.label}</li>`
  ).join('');
  // attach mousedown (not click) so it fires before input blur
  list.querySelectorAll('.ss-item').forEach(li => {
    li.addEventListener('mousedown', (e) => {
      e.preventDefault(); // prevent input from losing focus first
      _ssPick(id, li.dataset.value);
    });
  });
}

function _ssPick(id, value) {
  const opts   = _ssOptions[id] || [];
  const match  = opts.find(o => o.value === value);
  const input  = document.getElementById(id + 'Search');
  const hidden = document.getElementById(id + 'Val');
  if (input)  input.value  = match ? match.label : value;
  if (hidden) hidden.value = value;
  _ssCloseAll(null);
  _ssActive = null;
  clearFieldError(id);
}

/* Public API */

function _ssSetup(id, options) {
  _ssOptions[id] = options;
  // Also populate the legacy hidden <select> (kept for any downstream code)
  const sel = document.getElementById(id);
  if (sel) {
    sel.innerHTML = options.map(o =>
      `<option value="${o.value}">${o.label}</option>`
    ).join('');
  }
  _ssRenderList(id, options);
}

function filterSearchableSelect(id, query) {
  const q    = (query || '').toLowerCase();
  const opts = (_ssOptions[id] || []).filter(o =>
    !q || o.label.toLowerCase().includes(q) || o.value.toLowerCase().includes(q)
  );
  _ssRenderList(id, opts);

  // Show list when user starts typing
  const list = _ssBuildList(id);
  if (list) {
    list.classList.remove('hidden');
    _ssActive = id;
  }

  // If query cleared, also clear the hidden value
  if (!query) {
    const hidden = document.getElementById(id + 'Val');
    if (hidden) hidden.value = '';
  }
}

function openSearchableSelect(id) {
  _ssCloseAll(id);
  const query = (document.getElementById(id + 'Search') || {}).value || '';
  const q     = query.toLowerCase();
  const opts  = (_ssOptions[id] || []).filter(o =>
    !q || o.label.toLowerCase().includes(q) || o.value.toLowerCase().includes(q)
  );
  _ssRenderList(id, opts);
  const list = _ssBuildList(id);
  if (list) {
    list.classList.remove('hidden');
    _ssActive = id;
  }
}

// pickSearchableSelect kept for backward compatibility (called by old onchange)
function pickSearchableSelect(id) {
  const sel = document.getElementById(id);
  if (sel && sel.value) _ssPick(id, sel.value);
}

// commitSearchableSelect — try to match typed text on blur
function commitSearchableSelect(id) {
  setTimeout(() => {
    const list   = _ssBuildList(id);
    if (list) list.classList.add('hidden');
    const input  = document.getElementById(id + 'Search');
    const hidden = document.getElementById(id + 'Val');
    if (!input || !hidden) return;
    if (hidden.value) return; // already picked
    const q = input.value.trim().toLowerCase();
    if (q) {
      const match = (_ssOptions[id] || []).find(o =>
        o.label.toLowerCase() === q || o.value.toLowerCase() === q
      );
      if (match) {
        hidden.value = match.value;
        input.value  = match.label;
        clearFieldError(id);
      }
    }
    if (_ssActive === id) _ssActive = null;
  }, 200);
}

function setSearchableSelectValue(id, value) {
  const opts  = _ssOptions[id] || [];
  const match = opts.find(o => o.value === value);
  const input  = document.getElementById(id + 'Search');
  const hidden = document.getElementById(id + 'Val');
  if (input)  input.value  = match ? match.label : value;
  if (hidden) hidden.value = value;
}

function getSearchableSelectValue(id) {
  const hidden = document.getElementById(id + 'Val');
  return hidden ? hidden.value.trim() : '';
}

// ════════════════════════════════════════════════════════════
//  MAPPING FORM — load dropdown options from API
// ════════════════════════════════════════════════════════════

let _mappingFormOptionsLoaded = false;

async function loadMappingFormOptions(force = false) {
  if (_mappingFormOptionsLoaded && !force) return;
  const loadingEl  = document.getElementById('mFormLoadingState');
  const errorEl    = document.getElementById('mFormErrorState');
  const fieldsEl   = document.getElementById('mFormFields');
  if (loadingEl) loadingEl.classList.remove('hidden');
  if (errorEl)   errorEl.classList.add('hidden');
  if (fieldsEl)  fieldsEl.style.opacity = '0.4';
  try {
    const [dbRes, typeRes] = await Promise.all([
      apiCall('/api/database-records/enabled?limit=200'),
      apiCall('/api/datatype-standard/list?limit=200'),
    ]);
    const dbOptions   = (dbRes.data   || []).map(d => ({ value: d.key,           label: d.key }));
    const typeOptions = (typeRes.data || []).map(t => ({ value: t.standard_type, label: t.standard_type }));
    _ssSetup('mSrcDb',      dbOptions);
    _ssSetup('mDestDb',     dbOptions);
    _ssSetup('mMasterType', typeOptions);
    _mappingFormOptionsLoaded = true;
  } catch (e) {
    if (errorEl) {
      errorEl.classList.remove('hidden');
      const errText = document.getElementById('mFormErrorText');
      if (errText) errText.textContent = 'Failed to load options: ' + e.message;
    }
  } finally {
    if (loadingEl) loadingEl.classList.add('hidden');
    if (fieldsEl)  fieldsEl.style.opacity = '';
  }
}

// ── Validation helpers ────────────────────────────────────────────────────────

function setFieldError(id, msg) {
  const input = document.getElementById(id) || document.getElementById(id + 'Search');
  const errEl = document.getElementById(id + 'Err');
  if (input) input.classList.add('input-error');
  if (errEl) { errEl.textContent = msg || ''; errEl.classList.remove('hidden'); }
}

function clearFieldError(id) {
  const input = document.getElementById(id) || document.getElementById(id + 'Search');
  const errEl = document.getElementById(id + 'Err');
  if (input) { input.classList.remove('input-error'); input.classList.add('input-ok'); }
  if (errEl) errEl.classList.add('hidden');
}

function validateMappingField(id) {
  const el  = document.getElementById(id);
  const val = el ? el.value.trim() : '';
  if (!val) setFieldError(id, 'This field is required');
  else      clearFieldError(id);
  return !!val;
}

// ── _validateMappingForm: ตรวจครบทุก field รวม source_type ──────────────────
function _validateMappingForm() {
  let ok = true;
  const srcDb  = getSearchableSelectValue('mSrcDb');
  const destDb = getSearchableSelectValue('mDestDb');
  const master = getSearchableSelectValue('mMasterType');

  if (!srcDb)  { setFieldError('mSrcDb',      'Source DB is required');       ok = false; }
  else           clearFieldError('mSrcDb');
  if (!destDb) { setFieldError('mDestDb',     'Destination DB is required');  ok = false; }
  else           clearFieldError('mDestDb');
  if (!master) { setFieldError('mMasterType', 'Master Type is required');     ok = false; }
  else           clearFieldError('mMasterType');

  // text fields — เรียงตาม DB schema
  ['mSourceType', 'mRawType', 'mLogicalType', 'mFinalType'].forEach(id => {
    if (!validateMappingField(id)) ok = false;
  });

  return ok;
}

// ── editMapping: โหลดค่าทุก field รวม sourceType + confidence ───────────────
function editMapping(id) {
  const m = mappingData.find(r => r.id === id);
  if (!m) return;
  loadMappingFormOptions().then(() => {
    // searchable selects
    setSearchableSelectValue('mSrcDb',      m.srcDb);
    setSearchableSelectValue('mDestDb',     m.destDb);
    setSearchableSelectValue('mMasterType', m.masterType);

    // text inputs — เรียงตาม DB schema
    const sourceTypeEl = document.getElementById('mSourceType');
    const rawTypeEl    = document.getElementById('mRawType');
    const logicalEl    = document.getElementById('mLogicalType');
    const finalTypeEl  = document.getElementById('mFinalType');
    const confidenceEl = document.getElementById('mConfidence');
    const statusEl     = document.getElementById('mStatus');

    if (sourceTypeEl) sourceTypeEl.value = m.sourceType;
    if (rawTypeEl)    rawTypeEl.value    = m.rawType;
    if (logicalEl)    logicalEl.value    = m.logicalType;
    if (finalTypeEl)  finalTypeEl.value  = m.finalType;
    if (confidenceEl) confidenceEl.value = m.confidence;
    if (statusEl)     statusEl.value     = m.status;

    // clear errors
    ['mSrcDb', 'mDestDb', 'mMasterType', 'mSourceType', 'mRawType', 'mLogicalType', 'mFinalType']
      .forEach(clearFieldError);
  });
  document.getElementById('mappingModalTitle').textContent = 'Edit Mapping Rule';
  document.getElementById('mappingModal').dataset.editId = id;
  openModal('mappingModal');
}

function deleteMapping(id) {
  const m = mappingData.find(r => r.id === id);
  if (!m) return;
  document.getElementById('deleteWarnText').textContent = `Delete mapping "${m.rawType} → ${m.finalType}"? This cannot be undone.`;
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try { await apiCall(`/api/mappings/${id}`, { method: 'DELETE' }); selectedMappings.delete(id); showToast('Mapping rule deleted', 'info'); closeModal('deleteModal'); await fetchMappings(); }
    catch (e) { showToast('Delete failed: ' + e.message, 'error'); }
  };
  openModal('deleteModal');
}

function bulkDelete() {
  if (!selectedMappings.size) return;
  document.getElementById('deleteWarnText').textContent = `Delete ${selectedMappings.size} selected mapping(s)? This cannot be undone.`;
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try {
      await Promise.all([...selectedMappings].map(id => apiCall(`/api/mappings/${id}`, { method: 'DELETE' })));
      selectedMappings.clear(); showToast('Selected mappings deleted', 'info'); closeModal('deleteModal'); await fetchMappings();
    } catch (e) { showToast('Bulk delete failed: ' + e.message, 'error'); }
  };
  openModal('deleteModal');
}

function bulkApprove() {
  if (!selectedMappings.size) return;
  Promise.all([...selectedMappings].map(id => apiCall(`/api/mappings/${id}`, { method:'PUT', body:JSON.stringify({ status:'active' }) })))
    .then(() => { showToast(`${selectedMappings.size} mapping(s) set to active`, 'success'); selectedMappings.clear(); fetchMappings(); })
    .catch(e => showToast('Approve failed: ' + e.message, 'error'));
}

// ── openAddMapping: reset ทุก field รวม sourceType + confidence ──────────────
function openAddMapping() {
  document.getElementById('mappingModalTitle').textContent = 'Add Mapping Rule';

  // reset searchable selects
  ['mSrcDb', 'mDestDb', 'mMasterType'].forEach(id => {
    const inp  = document.getElementById(id + 'Search');
    const hid  = document.getElementById(id + 'Val');
    if (inp) inp.value = '';
    if (hid) hid.value = '';
    clearFieldError(id);
    // close dropdown list if open
    const wrap = document.querySelector(`.searchable-select-wrap[data-ss="${id}"]`);
    if (wrap) { const list = wrap.querySelector('.ss-list'); if (list) list.classList.add('hidden'); }
  });

  // reset text inputs — เรียงตาม DB schema
  ['mSourceType', 'mRawType', 'mLogicalType', 'mFinalType'].forEach(id => {
    const el = document.getElementById(id);
    if (el) { el.value = ''; el.classList.remove('input-error', 'input-ok'); }
    clearFieldError(id);
  });

  // reset confidence + status
  const confEl   = document.getElementById('mConfidence');
  const statusEl = document.getElementById('mStatus');
  if (confEl)   confEl.value   = 100;
  if (statusEl) statusEl.value = 'pending';

  delete document.getElementById('mappingModal').dataset.editId;
  loadMappingFormOptions();
  openModal('mappingModal');
}

// ── saveMapping: ส่ง payload ครบทุก field รวม source_type + confidence ───────
async function saveMapping() {
  if (!_validateMappingForm()) {
    showToast('Please fix the errors before saving', 'error');
    return;
  }
  const saveBtn = document.getElementById('mSaveBtn');
  if (saveBtn) { saveBtn.classList.add('btn-loading'); saveBtn.textContent = 'Saving…'; }

  const payload = {
    src_db:       getSearchableSelectValue('mSrcDb'),
    source_type:  document.getElementById('mSourceType').value.trim(),
    raw_type:     document.getElementById('mRawType').value.trim(),
    logical_type: document.getElementById('mLogicalType').value.trim(),
    master_type:  getSearchableSelectValue('mMasterType'),
    dest_db:      getSearchableSelectValue('mDestDb'),
    final_type:   document.getElementById('mFinalType').value.trim(),
    confidence:   Number(document.getElementById('mConfidence')?.value ?? 100),
    status:       document.getElementById('mStatus')?.value || 'pending',
  };

  const editId = document.getElementById('mappingModal').dataset.editId;
  try {
    if (editId) {
      await apiCall(`/api/mappings/${editId}`, { method: 'PUT', body: JSON.stringify(payload) });
      showToast('Mapping rule updated', 'success');
    } else {
      await apiCall('/api/mappings', { method: 'POST', body: JSON.stringify(payload) });
      showToast('Mapping rule saved', 'success');
    }
    closeModal('mappingModal');
    await fetchMappings();
  } catch (e) {
    let msg = e.message;
    try { const parsed = JSON.parse(e.message); msg = parsed.message || msg; } catch {}
    showToast('Save failed: ' + msg, 'error');
  } finally {
    if (saveBtn) { saveBtn.classList.remove('btn-loading'); saveBtn.textContent = 'Save Rule'; }
  }
}

// ════════════════════════════════════════════════════════════
//  BULK IMPORT  (CSV / JSON → Mapping Rules)
// ════════════════════════════════════════════════════════════

const IMPORT_REQUIRED_COLS = ['src_db', 'raw_type', 'dest_db'];
const IMPORT_ALL_COLS      = ['src_db','raw_type','source_type','logical_type','master_type','dest_db','final_type','confidence','status'];
let   _importRows          = [];   // parsed & validated rows
let   _importHasErrors     = false;

function openBulkImport() {
  importReset();
  openModal('importModal');
}

function importReset() {
  _importRows      = [];
  _importHasErrors = false;

  // reset steps
  document.getElementById('importStep1').classList.remove('hidden');
  document.getElementById('importStep2').classList.add('hidden');
  document.getElementById('importStep3').classList.add('hidden');
  document.getElementById('importRunBtn').classList.add('hidden');

  // reset file input
  const fi = document.getElementById('importFileInput');
  if (fi) fi.value = '';

  // reset preview
  document.getElementById('importPreviewHead').innerHTML = '';
  document.getElementById('importPreviewBody').innerHTML = '';
  document.getElementById('importPreviewMeta').textContent = '';
  document.getElementById('importValidationErrors').classList.add('hidden');
  document.getElementById('importValidationErrors').innerHTML = '';

  // reset progress
  document.getElementById('importProgressBar').style.width = '0%';
  document.getElementById('importProgressCount').textContent = '0 / 0';
  document.getElementById('importProgressLabel').textContent = 'Importing…';
  document.getElementById('importResultLog').innerHTML = '';
}

// ── Drag & drop ──────────────────────────────────────────────────────────────

function importDragOver(e) {
  e.preventDefault();
  document.getElementById('importDropzone').classList.add('drag-over');
}
function importDragLeave(e) {
  document.getElementById('importDropzone').classList.remove('drag-over');
}
function importDrop(e) {
  e.preventDefault();
  document.getElementById('importDropzone').classList.remove('drag-over');
  const file = e.dataTransfer.files[0];
  if (file) _importHandleFile(file);
}
function importFileSelected(input) {
  if (input.files[0]) _importHandleFile(input.files[0]);
}

// ── File reading & parsing ────────────────────────────────────────────────────

function _importHandleFile(file) {
  const ext = file.name.split('.').pop().toLowerCase();
  if (!['csv','json'].includes(ext)) {
    showToast('Only CSV and JSON files are supported', 'error');
    return;
  }
  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      const rows = ext === 'csv'
        ? _parseCSV(e.target.result)
        : _parseJSON(e.target.result);
      _importShowPreview(rows, file.name);
    } catch (err) {
      showToast('Failed to parse file: ' + err.message, 'error');
    }
  };
  reader.readAsText(file, 'utf-8');
}

function _parseCSV(text) {
  const lines = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n').filter(l => l.trim());
  if (lines.length < 2) throw new Error('CSV must have a header row and at least one data row');

  // Parse header (handle quoted headers)
  const headers = _csvSplitLine(lines[0]).map(h => h.trim().toLowerCase().replace(/^"|"$/g,''));

  return lines.slice(1).map((line, i) => {
    const vals = _csvSplitLine(line);
    const row  = {};
    headers.forEach((h, j) => { row[h] = (vals[j] || '').trim().replace(/^"|"$/g,''); });
    return row;
  });
}

function _csvSplitLine(line) {
  const result = [];
  let cur = '', inQ = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') { inQ = !inQ; }
    else if (ch === ',' && !inQ) { result.push(cur); cur = ''; }
    else { cur += ch; }
  }
  result.push(cur);
  return result;
}

function _parseJSON(text) {
  const data = JSON.parse(text);
  if (!Array.isArray(data)) throw new Error('JSON must be an array of objects');
  return data.map(item => {
    const row = {};
    IMPORT_ALL_COLS.forEach(col => { row[col] = item[col] !== undefined ? String(item[col]) : ''; });
    return row;
  });
}

// ── Preview & validation ──────────────────────────────────────────────────────

function _importShowPreview(rows, filename) {
  _importRows      = rows;
  _importHasErrors = false;

  const errors     = [];
  const errorRows  = new Set();

  rows.forEach((row, i) => {
    IMPORT_REQUIRED_COLS.forEach(col => {
      if (!row[col] || !row[col].trim()) {
        errors.push(`Row ${i + 1}: missing required field "${col}"`);
        errorRows.add(i);
        _importHasErrors = true;
      }
    });
    // validate confidence if present
    const conf = row.confidence;
    if (conf !== undefined && conf !== '') {
      const n = Number(conf);
      if (isNaN(n) || n < 0 || n > 100) {
        errors.push(`Row ${i + 1}: "confidence" must be 0–100`);
        errorRows.add(i);
        _importHasErrors = true;
      }
    }
  });

  // Show step 2
  document.getElementById('importStep1').classList.add('hidden');
  document.getElementById('importStep2').classList.remove('hidden');

  // Meta
  const metaEl = document.getElementById('importPreviewMeta');
  metaEl.innerHTML = `<strong>${filename}</strong> — ${rows.length} row(s)` +
    (_importHasErrors ? ` <span style="color:#ef4444">⚠ ${errors.length} error(s)</span>` : ' <span style="color:#22c55e">✓ Valid</span>');

  // Build preview table (max 50 rows shown)
  const cols    = IMPORT_ALL_COLS.filter(c => rows.some(r => r[c]));
  const headEl  = document.getElementById('importPreviewHead');
  const bodyEl  = document.getElementById('importPreviewBody');

  headEl.innerHTML = '<tr>' + cols.map(c => `<th>${c}</th>`).join('') + '</tr>';

  const displayRows = rows.slice(0, 50);
  bodyEl.innerHTML = displayRows.map((row, i) =>
    `<tr class="${errorRows.has(i) ? 'row-error' : ''}">` +
    cols.map(c => `<td title="${(row[c]||'').replace(/"/g,'&quot;')}">${row[c] || '<span style="color:var(--text3)">—</span>'}</td>`).join('') +
    '</tr>'
  ).join('');

  if (rows.length > 50) {
    bodyEl.innerHTML += `<tr><td colspan="${cols.length}" style="color:var(--text3);text-align:center;padding:8px">… and ${rows.length - 50} more rows</td></tr>`;
  }

  // Show errors
  const errEl = document.getElementById('importValidationErrors');
  if (errors.length > 0) {
    errEl.classList.remove('hidden');
    errEl.innerHTML = '<ul>' + errors.slice(0, 10).map(e => `<li>${e}</li>`).join('') +
      (errors.length > 10 ? `<li>…and ${errors.length - 10} more</li>` : '') + '</ul>';
  } else {
    errEl.classList.add('hidden');
  }

  // Show/hide import button
  const runBtn = document.getElementById('importRunBtn');
  if (_importHasErrors) {
    runBtn.classList.add('hidden');
  } else {
    runBtn.classList.remove('hidden');
    runBtn.textContent = `Import ${rows.length} Row(s)`;
    runBtn.disabled = false;
  }
}

// ── Run import ────────────────────────────────────────────────────────────────

async function runBulkImport() {
  if (!_importRows.length) return;

  const runBtn = document.getElementById('importRunBtn');
  runBtn.disabled = true;

  // Show step 3
  document.getElementById('importStep2').classList.add('hidden');
  document.getElementById('importStep3').classList.remove('hidden');

  const total    = _importRows.length;
  const logEl    = document.getElementById('importResultLog');
  const barEl    = document.getElementById('importProgressBar');
  const countEl  = document.getElementById('importProgressCount');
  const labelEl  = document.getElementById('importProgressLabel');

  let ok = 0, skipped = 0, failed = 0;

  for (let i = 0; i < total; i++) {
    const row  = _importRows[i];
    const pct  = Math.round(((i + 1) / total) * 100);
    barEl.style.width  = pct + '%';
    countEl.textContent = `${i + 1} / ${total}`;
    labelEl.textContent = `Importing row ${i + 1} of ${total}…`;

    const payload = {
      src_db:       row.src_db      || '',
      raw_type:     row.raw_type    || '',
      source_type:  row.source_type || '',
      logical_type: row.logical_type|| '',
      master_type:  row.master_type || '',
      dest_db:      row.dest_db     || '',
      final_type:   row.final_type  || '',
      confidence:   row.confidence !== '' ? Number(row.confidence) : 100,
      status:       row.status      || 'draft',
    };

    try {
      await apiCall('/api/mappings', { method: 'POST', body: JSON.stringify(payload) });
      ok++;
      const line = document.createElement('div');
      line.className = 'log-line log-ok';
      line.textContent = `✓ [${i+1}] ${payload.src_db} → ${payload.dest_db}  |  ${payload.raw_type}`;
      logEl.appendChild(line);
    } catch (err) {
      const isDup = err.message && (err.message.includes('409') || err.message.toLowerCase().includes('duplicate'));
      if (isDup) {
        skipped++;
        const line = document.createElement('div');
        line.className = 'log-line log-skip';
        line.textContent = `⚠ [${i+1}] Skipped (duplicate): ${payload.raw_type} ${payload.src_db}→${payload.dest_db}`;
        logEl.appendChild(line);
      } else {
        failed++;
        const line = document.createElement('div');
        line.className = 'log-line log-err';
        line.textContent = `✗ [${i+1}] Error: ${err.message}`;
        logEl.appendChild(line);
      }
    }

    // Auto-scroll log
    logEl.scrollTop = logEl.scrollHeight;
  }

  // Done
  barEl.style.width  = '100%';
  labelEl.textContent = `Done! ${ok} imported, ${skipped} skipped, ${failed} failed`;
  labelEl.style.color = failed > 0 ? 'var(--danger,#ef4444)' : ok > 0 ? '#22c55e' : 'var(--text2)';

  showToast(`Import complete: ${ok} added, ${skipped} skipped, ${failed} failed`, failed > 0 ? 'error' : 'success');
  await fetchMappings();

  runBtn.textContent = 'Close';
  runBtn.disabled    = false;
  runBtn.classList.remove('hidden');
  runBtn.onclick     = () => closeModal('importModal');
}

// ── Template download ─────────────────────────────────────────────────────────

function downloadImportTemplate(type) {
  const sample = [
    { src_db:'postgres', raw_type:'varchar', source_type:'string', logical_type:'string', master_type:'STRING', dest_db:'kafka', final_type:'string', confidence:100, status:'active' },
    { src_db:'mysql',    raw_type:'int',     source_type:'int',    logical_type:'integer',master_type:'INTEGER',dest_db:'kafka', final_type:'int',    confidence:100, status:'active' },
  ];

  let content, filename, mime;

  if (type === 'csv') {
    const header = IMPORT_ALL_COLS.join(',');
    const rows   = sample.map(r => IMPORT_ALL_COLS.map(c => r[c]).join(','));
    content  = [header, ...rows].join('\n');
    filename = 'mapping_import_template.csv';
    mime     = 'text/csv';
  } else {
    content  = JSON.stringify(sample, null, 2);
    filename = 'mapping_import_template.json';
    mime     = 'application/json';
  }

  const blob = new Blob([content], { type: mime });
  const a    = document.createElement('a');
  a.href     = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}
// ════════════════════════════════════════════════════════════
//  DATABASE REGISTRY
// ════════════════════════════════════════════════════════════

let dbData = [];
const DB_ICONS = { sqlserver:'🗄', postgresql:'🐘', mysql:'🐬', oracle:'🔴', confluent:'⚡', default:'🗄' };

async function fetchDatabases() {
  try {
    const data = await apiCall('/api/databases');
    dbData = data.data || [];
    renderDatabases();
  } catch (e) {
    dbData = [];
    renderDatabaseError(e);
    showToast('Failed to load databases: ' + e.message, 'error');
  }
}

function renderDatabases() {
  const grid = document.getElementById('dbGrid');
  if (!grid) return;
  if (!dbData.length) { grid.innerHTML = `<div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--text3);border:1px dashed var(--border2);border-radius:var(--radius);">No databases configured</div>`; return; }
  grid.innerHTML = dbData.map(db => {
    const icon = DB_ICONS[db.key] || DB_ICONS.default;
    return `
    <div class="db-card">
      <div class="db-card-header">
        <div class="db-card-info">
          <div class="db-logo">${icon}</div>
          <div><div class="db-card-name">${db.name}</div><div class="db-card-key">${db.key}${db.version?' · '+db.version:''}</div></div>
        </div>
        <label class="toggle-switch"><input type="checkbox" ${db.enabled?'checked':''} onchange="toggleDatabase(${db.id},this.checked)" /><span class="toggle-track"></span></label>
      </div>
      <div class="db-card-stats">
        <div class="db-stat"><div class="db-stat-label">Mapping Rules</div><div class="db-stat-val">${db.rules}</div></div>
        <div class="db-stat"><div class="db-stat-label">Active Sessions</div><div class="db-stat-val">${db.sessions}</div></div>
      </div>
      <div class="db-card-actions">
        <button class="btn btn-sm btn-ghost" onclick="showToast('Viewing rules for ${db.name}','info')">View Rules</button>
        <button class="btn btn-sm btn-ghost" onclick="editDatabase(${db.id})">Edit</button>
        <button class="btn btn-sm btn-danger" onclick="confirmDeleteDatabase(${db.id})">Delete</button>
      </div>
    </div>`;
  }).join('');
}

function renderDatabaseError(error) {
  const grid = document.getElementById('dbGrid');
  if (!grid) return;
  const detail = error?.message || 'Unknown error';
  const pageOrigin = window.location.origin || 'file://';
  grid.innerHTML = `
    <div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--text3);border:1px dashed var(--border2);border-radius:var(--radius);">
      <div style="font-weight:600;color:var(--text);margin-bottom:8px">Unable to load databases</div>
      <div style="margin-bottom:16px">${detail}</div>
      <div style="font-family:var(--mono);font-size:11px;line-height:1.6;margin-bottom:16px;color:var(--text3)">
        API: ${API_URL}<br />
        Page: ${pageOrigin}
      </div>
      <button class="btn btn-primary" onclick="fetchDatabases()">Retry</button>
    </div>`;
}

async function toggleDatabase(id, enabled) {
  const db = dbData.find(d => d.id === id);
  if (!db) return;
  try { await apiCall(`/api/databases/${id}`, { method:'PUT', body:JSON.stringify({ enabled }) }); db.enabled = enabled; showToast(`${db.name} ${enabled?'enabled':'disabled'}`, enabled?'success':'warn'); }
  catch (e) { showToast('Update failed: ' + e.message, 'error'); renderDatabases(); }
}

function editDatabase(id) {
  const db = dbData.find(d => d.id === id);
  if (!db) return;
  ['dbName','dbLabel','dbVersion'].forEach(fid => {
    const el = document.getElementById(fid);
    if (el) el.classList.remove('input-error', 'input-ok');
  });
  ['dbNameErr','dbLabelErr'].forEach(fid => {
    const el = document.getElementById(fid);
    if (el) el.classList.add('hidden');
  });
  const preview = document.getElementById('dbKeyPreview');
  if (preview) preview.style.display = 'none';
  document.getElementById('dbName').value    = db.key;
  document.getElementById('dbLabel').value   = db.name;
  document.getElementById('dbVersion').value = db.version || '';
  document.getElementById('dbStatus').value  = db.status || 'active';
  document.getElementById('dbModalTitle').textContent = 'Edit Database';
  document.getElementById('dbModal').dataset.editId = id;
  const saveBtn = document.querySelector('#dbModal .btn-primary');
  if (saveBtn) saveBtn.textContent = 'Save Changes';
  openModal('dbModal');
}

function confirmDeleteDatabase(id) {
  const db = dbData.find(d => d.id === id);
  if (!db) return;
  document.getElementById('deleteWarnText').textContent = `Delete "${db.name}"? All associated mapping rules (${db.rules}) will also be removed.`;
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try { await apiCall(`/api/databases/${id}`, { method:'DELETE' }); showToast(`${db.name} removed`, 'warn'); closeModal('deleteModal'); await fetchDatabases(); }
    catch (e) { showToast('Delete failed: ' + e.message, 'error'); }
  };
  openModal('deleteModal');
}

// ════════════════════════════════════════════════════════════
//  DATABASE KEY SANITIZE
// ════════════════════════════════════════════════════════════
function sanitizeDbKey(raw) {
  return (raw || '').trim().toLowerCase().replace(/\s+/g, '');
}

const _DB_KEY_RE = /^[a-z0-9_]+$/;

function onDbKeyInput(input) {
  const raw       = input.value;
  const sanitized = sanitizeDbKey(raw);
  const preview    = document.getElementById('dbKeyPreview');
  const previewVal = document.getElementById('dbKeyPreviewVal');
  if (sanitized && sanitized !== raw.trim().toLowerCase()) {
    if (preview)    preview.style.display = '';
    if (previewVal) previewVal.textContent = sanitized;
  } else {
    if (preview) preview.style.display = 'none';
  }
  const errEl = document.getElementById('dbNameErr');
  if (!sanitized) {
    input.classList.add('input-error');
    input.classList.remove('input-ok');
    if (errEl) errEl.classList.remove('hidden');
  } else if (!_DB_KEY_RE.test(sanitized)) {
    input.classList.add('input-error');
    input.classList.remove('input-ok');
    if (errEl) { errEl.textContent = 'Only a–z, 0–9, _ allowed'; errEl.classList.remove('hidden'); }
  } else {
    input.classList.remove('input-error');
    input.classList.add('input-ok');
    if (errEl) errEl.classList.add('hidden');
  }
}

function validateDbField(id) {
  const el  = document.getElementById(id);
  const errEl = document.getElementById(id + 'Err');
  const val = el ? el.value.trim() : '';
  if (!val) {
    if (el) { el.classList.add('input-error'); el.classList.remove('input-ok'); }
    if (errEl) errEl.classList.remove('hidden');
    return false;
  }
  if (el) { el.classList.remove('input-error'); el.classList.add('input-ok'); }
  if (errEl) errEl.classList.add('hidden');
  return true;
}

function openAddDatabase() {
  ['dbName','dbLabel','dbVersion'].forEach(id => {
    const el = document.getElementById(id);
    if (el) { el.value = ''; el.classList.remove('input-error', 'input-ok'); }
  });
  ['dbNameErr','dbLabelErr'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.classList.add('hidden');
  });
  const preview = document.getElementById('dbKeyPreview');
  if (preview) preview.style.display = 'none';
  document.getElementById('dbModalTitle').textContent = 'Add Database';
  delete document.getElementById('dbModal').dataset.editId;
  openModal('dbModal');
}

async function saveDatabase() {
  const rawKey  = document.getElementById('dbName')?.value || '';
  const key     = sanitizeDbKey(rawKey);
  const name    = document.getElementById('dbLabel')?.value.trim();
  const version = document.getElementById('dbVersion')?.value.trim();
  const status  = document.getElementById('dbStatus')?.value || 'active';

  let ok = true;
  if (!key || !_DB_KEY_RE.test(key)) {
    const errEl = document.getElementById('dbNameErr');
    const input = document.getElementById('dbName');
    if (input) input.classList.add('input-error');
    if (errEl) { errEl.textContent = 'Key must use only a–z, 0–9, _'; errEl.classList.remove('hidden'); }
    ok = false;
  }
  if (!validateDbField('dbLabel')) ok = false;
  if (!ok) { showToast('Please fix the errors before saving', 'error'); return; }

  const saveBtn = document.querySelector('#dbModal .btn-primary');
  if (saveBtn) { saveBtn.classList.add('btn-loading'); saveBtn.textContent = 'Saving…'; }
  const editId = document.getElementById('dbModal').dataset.editId;
  try {
    if (editId) {
      await apiCall(`/api/databases/${editId}`, { method:'PUT', body:JSON.stringify({ name, key, version, status }) });
      showToast(`Database "${name}" updated`, 'success');
    } else {
      await apiCall('/api/databases', { method:'POST', body:JSON.stringify({ name, key, version, status, enabled:true }) });
      showToast(`Database "${name}" added`, 'success');
    }
    closeModal('dbModal');
    await fetchDatabases();
    _mappingFormOptionsLoaded = false;
  } catch (e) {
    let msg = e.message;
    try { const d = JSON.parse(e.message); msg = d.message || msg; } catch {}
    showToast('Save failed: ' + msg, 'error');
  } finally {
    if (saveBtn) { saveBtn.classList.remove('btn-loading'); saveBtn.textContent = 'Add Database'; }
  }
}

// ════════════════════════════════════════════════════════════
//  SESSION MONITOR
// ════════════════════════════════════════════════════════════

let presenceWs        = null;
let presencePingTimer = null;
const PRESENCE_PING_INTERVAL    = 25_000;
const PRESENCE_RECONNECT_DELAY  = 5_000;

function connectPresence() {
  if (presenceWs && presenceWs.readyState < 2) return;
  const token = _getToken();
  if (!token) return;

  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  const host  = new URL(API_URL).host;
  const url   = `${proto}://${host}/ws/presence/admin?token=${encodeURIComponent(token)}`;
  presenceWs  = new WebSocket(url);

  presenceWs.onopen = () => { startPresencePing(); };
  presenceWs.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      if (msg.event === 'update_online_users') renderOnlineUsers(msg.users || [], msg.total || 0);
    } catch { /* ignore */ }
  };
  presenceWs.onclose = () => { stopPresencePing(); setTimeout(connectPresence, PRESENCE_RECONNECT_DELAY); };
  presenceWs.onerror = () => presenceWs.close();
}

function startPresencePing() { stopPresencePing(); presencePingTimer = setInterval(() => { if (presenceWs?.readyState === WebSocket.OPEN) presenceWs.send(JSON.stringify({ event:'ping' })); }, PRESENCE_PING_INTERVAL); }
function stopPresencePing()  { clearInterval(presencePingTimer); }

function renderOnlineUsers(users, total) {
  const badge    = document.querySelector('.nav-item[data-page="sessions"] .nav-badge.live');
  if (badge)     badge.textContent = total;
  const countEl  = document.getElementById('onlineUserCount');
  if (countEl)   countEl.textContent = total;

  const active   = users.filter(u => u.idle_seconds < 60).length;
  const expiring = users.filter(u => u.idle_seconds >= 60 && u.idle_seconds < 90).length;
  const elActive   = document.getElementById('sessActive');
  const elExpiring = document.getElementById('sessExpiring');
  if (elActive)   elActive.textContent   = active;
  if (elExpiring) elExpiring.textContent = expiring;

  const tbody = document.getElementById('onlineUsersBody');
  if (!tbody) return;
  if (!users.length) { tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:32px;color:var(--text3)">No users online</td></tr>`; return; }
  tbody.innerHTML = users.map(u => {
    const idleMin = Math.floor(u.idle_seconds / 60);
    const idleTxt = idleMin > 0 ? `${idleMin}m ago` : 'just now';
    return `<tr>
      <td style="font-family:var(--mono);font-size:11px">${u.client_id.slice(0,8)}…</td>
      <td>${!u.user_id ? '<span style="color:var(--text3)">Guest</span>' : u.user_id}</td>
      <td style="font-family:var(--mono);font-size:11px">${u.page}</td>
      <td style="font-size:11px;color:var(--text3)">${u.connected_at?.slice(11,19)||'-'}</td>
      <td><span class="badge badge-${u.idle_seconds<60?'active':'draft'}">${idleTxt}</span></td>
    </tr>`;
  }).join('');
}

let sessionData = [];

async function fetchSessions() {
  try {
    const data    = await apiCall('/api/sessions');
    const payload = data.data || {};
    sessionData   = payload.sessions || [];
    const stats   = payload.stats    || { active:0, warning:0, expired:0 };
    const elActive   = document.getElementById('sessActive');
    const elExpiring = document.getElementById('sessExpiring');
    const elExpired = document.getElementById('sessExpired');
    if (elActive)   elActive.textContent = stats.active;
    if (elExpiring) elExpiring.textContent = stats.warning;
    if (elExpired) elExpired.textContent = stats.expired;
    const liveBadge = document.querySelector('.nav-item[data-page="sessions"] .nav-badge.live');
    if (liveBadge) liveBadge.textContent = stats.active + stats.warning;
    renderSessions();
  } catch (e) { showToast('Failed to load sessions: ' + e.message, 'error'); }
}

function renderSessions() {
  const tbody = document.getElementById('sessionBody');
  if (!tbody) return;
  if (!sessionData.length) { tbody.innerHTML = `<tr><td colspan="9" style="text-align:center;padding:32px;color:var(--text3)">No active sessions found</td></tr>`; return; }
  tbody.innerHTML = sessionData.map(s => {
    const ttlClass = s.ttl === 0 ? 'expired' : s.ttl < 10 ? 'warn' : 'ok';
    const ttlText  = s.ttl === 0 ? 'Expired' : `${s.ttl}m`;
    return `<tr>
      <td style="font-family:var(--mono);font-size:11px;color:var(--accent)">${s.id}</td>
      <td style="color:var(--text2)">${s.user}</td>
      <td><span class="badge badge-active">${s.role}</span></td>
      <td style="font-family:var(--mono);font-size:11px">${s.db}</td>
      <td style="font-family:var(--mono)">${s.tables}</td>
      <td style="font-family:var(--mono);font-size:11px;color:var(--text3)">${s.created}</td>
      <td><span class="ttl-badge ${ttlClass}">⏱ ${ttlText}</span></td>
      <td><span class="badge badge-${s.status==='active'?'active':s.status==='warning'?'draft':'deprecated'}">${s.status}</span></td>
      <td><div class="row-actions"><button class="row-btn danger" onclick="revokeSession('${s.id}')">✕ Revoke</button></div></td>
    </tr>`;
  }).join('');
}

function revokeSession(id) {
  document.getElementById('deleteWarnText').textContent = `Revoke session ${id}? The user will be disconnected immediately.`;
  document.getElementById('deleteConfirmBtn').textContent = 'Revoke';
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try { await apiCall(`/api/sessions/${id}`, { method:'DELETE' }); showToast(`Session ${id} revoked`, 'warn'); closeModal('deleteModal'); await fetchSessions(); }
    catch (e) { showToast('Revoke failed: ' + e.message, 'error'); }
  };
  openModal('deleteModal');
}

async function cleanupSessions() {
  try { const data = await apiCall('/api/sessions', { method:'DELETE' }); const removed = data.data?.removed??0; showToast(`${removed} expired session(s) cleaned up`, removed?'success':'info'); await fetchSessions(); }
  catch (e) { showToast('Cleanup failed: ' + e.message, 'error'); }
}

async function refreshSessions() { await fetchSessions(); showToast('Sessions refreshed', 'success'); }

// ════════════════════════════════════════════════════════════
//  LOG VIEWER
// ════════════════════════════════════════════════════════════

let logAutoScroll  = true;
let logLevelFilter = 'ALL';

function setLogFilter(level, btn) {
  logLevelFilter = level;
  document.querySelectorAll('.log-filter-btn').forEach(b => b.classList.remove('active'));
  if (btn) btn.classList.add('active');
  filterLogs();
}

async function fetchLogs() {
  const token = _getToken();
  if (!token) return;
  try {
    const data     = await apiCall('/api/logs');
    const terminal = document.getElementById('logTerminal');
    if (!terminal) return;
    terminal.innerHTML = '';
    (data.data || []).forEach(entry => appendLogLine(terminal, entry.timestamp, entry.level, entry.message));
    if (logAutoScroll) terminal.scrollTop = terminal.scrollHeight;
  } catch (e) { showToast('Failed to load logs: ' + e.message, 'error'); }
}

function appendLogLine(terminal, timestamp, level, message) {
  const ts   = (timestamp || new Date().toISOString()).slice(0, 19).replace('T', ' ');
  const line = document.createElement('div');
  line.className = 'log-line';
  line.innerHTML = `<span class="log-ts">${ts}</span><span class="log-lvl ${(level||'info').toLowerCase()}">${level}</span><span class="log-msg">${message}</span>`;
  terminal.appendChild(line);
  const lines = terminal.querySelectorAll('.log-line');
  if (lines.length > 200) lines[0].remove();
}

function filterLogs() {
  const terminal = document.getElementById('logTerminal');
  if (!terminal) return;
  const search = (document.getElementById('logSearch')?.value || '').toLowerCase();
  terminal.querySelectorAll('.log-line').forEach(line => {
    const lvl     = line.querySelector('.log-lvl')?.textContent.trim() || '';
    const msg     = line.querySelector('.log-msg')?.textContent.toLowerCase() || '';
    const levelOk = logLevelFilter === 'ALL' || lvl === logLevelFilter;
    const searchOk = !search || msg.includes(search) || lvl.toLowerCase().includes(search);
    line.style.display = levelOk && searchOk ? '' : 'none';
  });
  if (logAutoScroll) { const t = document.getElementById('logTerminal'); if (t) t.scrollTop = t.scrollHeight; }
}

function clearLogs() {
  const terminal = document.getElementById('logTerminal');
  if (terminal) terminal.innerHTML = `<div class="log-line"><span class="log-ts">${new Date().toISOString().slice(0,19).replace('T',' ')}</span><span class="log-lvl info">INFO</span><span class="log-msg">Log terminal cleared by admin</span></div>`;
  showToast('Logs cleared', 'info');
}

function toggleAutoScroll() {
  logAutoScroll = !logAutoScroll;
  const btn = document.getElementById('autoScrollBtn');
  if (btn) { btn.textContent = logAutoScroll ? '↓ Auto-scroll' : '⏸ Auto-scroll'; btn.classList.toggle('btn-accent', logAutoScroll); }
  showToast(`Auto-scroll ${logAutoScroll ? 'enabled' : 'paused'}`, 'info');
}

setInterval(async () => {
  const token    = _getToken();
  const terminal = document.getElementById('logTerminal');
  if (!token || !terminal) return;
  try {
    const data    = await apiCall('/api/logs/new');
    const entries = data.data || [];
    entries.forEach(e => appendLogLine(terminal, e.timestamp, e.level, e.message));
    if (entries.length > 0) {
      if (logAutoScroll) terminal.scrollTop = terminal.scrollHeight;
      filterLogs();
    }
  } catch { /* silent */ }
}, 10_000);

// ════════════════════════════════════════════════════════════
//  SETTINGS
// ════════════════════════════════════════════════════════════

function switchSettings(section, btn) {
  document.querySelectorAll('.settings-nav-item').forEach(b => b.classList.remove('active'));
  if (btn) btn.classList.add('active');
  document.querySelectorAll('.settings-section').forEach(s => s.classList.add('hidden'));
  const target = document.getElementById('settings-' + section);
  if (target) target.classList.remove('hidden');
  if (section === 'users')     { fetchMyRole().then(() => fetchUsers()); }
  if (section === 'security' || section === 'ratelimit') { _loadSettingsValues(); }
}

function saveSettings() { showToast('Settings saved successfully', 'success'); }
function toggleApiKey() { const input = document.getElementById('apiKeyInput'); if (!input) return; input.type = input.type === 'password' ? 'text' : 'password'; }
function rotateApiKey() {
  const input = document.getElementById('apiKeyInput');
  if (!input) return;
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let key = 'sk-admin-';
  for (let i = 0; i < 24; i++) key += chars[Math.floor(Math.random() * chars.length)];
  input.value = key; input.type = 'text';
  showToast('API key rotated — remember to update your clients', 'warn');
}

// ── Security Settings ─────────────────────────────────────────────────────────

function saveSecuritySettings() {
  const timeout    = parseInt(document.getElementById('secSessionTimeout')?.value) || 60;
  const minPw      = parseInt(document.getElementById('secMinPwLen')?.value) || 6;
  const maxAttempt = parseInt(document.getElementById('secMaxAttempts')?.value) || 5;
  localStorage.setItem('sec_session_timeout', timeout);
  localStorage.setItem('sec_min_pw_len',      minPw);
  localStorage.setItem('sec_max_attempts',    maxAttempt);
  showToast('บันทึกการตั้งค่า Security แล้ว', 'success');
}

async function cleanExpiredSessions() {
  try {
    const data = await apiCall('/api/sessions', { method: 'DELETE' });
    const removed = data.data?.removed ?? 0;
    showToast(`ล้าง ${removed} expired session(s) แล้ว`, removed ? 'success' : 'info');
    await fetchSessions();
  } catch (e) {
    showToast('Cleanup failed: ' + e.message, 'error');
  }
}

async function revokeAllSessions() {
  if (!confirm('ยืนยันการยกเลิก session ทั้งหมด? ผู้ใช้ทุกคนจะถูก logout')) return;
  try {
    const sessions = await apiCall('/api/sessions');
    const list     = sessions.data?.sessions || [];
    const myToken  = localStorage.getItem('ba_token') || sessionStorage.getItem('ba_token');
    let revoked = 0;
    for (const s of list) {
      if (s.id && !s.id.startsWith('auth-')) continue; // skip non-auth sessions
      try {
        await apiCall(`/api/sessions/${encodeURIComponent(s.id)}`, { method: 'DELETE' });
        revoked++;
      } catch { /* ignore individual failures */ }
    }
    showToast(`ยกเลิก ${revoked} session(s) แล้ว`, 'warn');
    await fetchSessions();
  } catch (e) {
    showToast('Revoke failed: ' + e.message, 'error');
  }
}

// ── Rate Limit Settings ───────────────────────────────────────────────────────

function saveRateLimitSettings() {
  const maxReq   = parseInt(document.getElementById('rlMaxReqMin')?.value) || 300;
  const bulk     = parseInt(document.getElementById('rlBulkLimit')?.value) || 5000;
  const interval = parseInt(document.getElementById('rlSyncInterval')?.value) || 300;
  const retry    = parseInt(document.getElementById('rlMaxRetry')?.value) || 3;
  localStorage.setItem('rl_max_req_min',    maxReq);
  localStorage.setItem('rl_bulk_limit',     bulk);
  localStorage.setItem('rl_sync_interval',  interval);
  localStorage.setItem('rl_max_retry',      retry);
  showToast('บันทึกการตั้งค่า Rate Limiting แล้ว', 'success');
}

function _loadSettingsValues() {
  const si = document.getElementById('secSessionTimeout');
  const sp = document.getElementById('secMinPwLen');
  const sa = document.getElementById('secMaxAttempts');
  const rr = document.getElementById('rlMaxReqMin');
  const rb = document.getElementById('rlBulkLimit');
  const ri = document.getElementById('rlSyncInterval');
  const rm = document.getElementById('rlMaxRetry');
  if (si) si.value = localStorage.getItem('sec_session_timeout') || 60;
  if (sp) sp.value = localStorage.getItem('sec_min_pw_len') || 6;
  if (sa) sa.value = localStorage.getItem('sec_max_attempts') || 5;
  if (rr) rr.value = localStorage.getItem('rl_max_req_min') || 300;
  if (rb) rb.value = localStorage.getItem('rl_bulk_limit') || 5000;
  if (ri) ri.value = localStorage.getItem('rl_sync_interval') || 300;
  if (rm) rm.value = localStorage.getItem('rl_max_retry') || 3;
}


// ════════════════════════════════════════════════════════════
//  GLOBAL SEARCH
// ════════════════════════════════════════════════════════════

(function setKbdHint() {
  const kbd = document.querySelector('.search-kbd');
  if (kbd) { const isMac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent); kbd.textContent = isMac ? '⌘K' : 'Ctrl+K'; }
})();

const globalSearch = document.getElementById('globalSearch');
if (globalSearch) {
  globalSearch.addEventListener('input', () => {
    const val = globalSearch.value.trim().toLowerCase();
    if (!val) return;
    const mappingPage = document.getElementById('page-mapping');
    if (mappingPage?.classList.contains('hidden')) navigate('mapping');
    const ms = document.getElementById('mappingSearch');
    if (ms) { ms.value = val; filterMappings(); }
  });
  document.addEventListener('keydown', e => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') { e.preventDefault(); globalSearch.focus(); globalSearch.select(); }
    if (e.key === 'Escape') globalSearch.blur();
  });
}

// ════════════════════════════════════════════════════════════
//  SYNC ENGINE TRIGGER
// ════════════════════════════════════════════════════════════

async function triggerSync() {
  const btn = document.getElementById('syncBtn');
  if (btn) { btn.classList.add('btn-loading'); btn.textContent = '⟳ Syncing…'; }
  try {
    const res = await apiCall('/api/sync/run', { method: 'POST' });
    const m   = res.data || {};
    showToast(
      `Sync complete — ${m.synced ?? 0} synced, ${m.errors ?? 0} error(s)`,
      (m.errors ?? 0) > 0 ? 'warn' : 'success',
    );
    await fetchMappings();
  } catch (e) {
    showToast('Sync failed: ' + e.message, 'error');
  } finally {
    if (btn) { btn.classList.remove('btn-loading'); btn.textContent = '⟳ Sync Pending'; }
  }
}

// ════════════════════════════════════════════════════════════
//  INIT
// ════════════════════════════════════════════════════════════

function init() {
  // fetch role จริงก่อนเสมอ เพื่อให้ทุก permission check ถูกต้อง
  fetchMyRole().then(() => {
    fetchMappings();
    fetchDatabases();
    fetchSessions();
    fetchLogs();
    refreshDashboard();
    connectPresence();
    fetchActivities();
  });
}
// ════════════════════════════════════════════════════════════
//  UPDATE ACTIVITY
// ════════════════════════════════════════════════════════════

let activityData   = [];
let activityPage   = 1;
const ACTIVITY_PAGE_SIZE = 15;

// ── action badge color ────────────────────────────────────────
function actionBadgeClass(action) {
  return { create: 'success', update: 'warning', delete: 'error', bulk_import: 'info' }[action] || 'draft';
}

function actionLabel(action) {
  return { create: '➕ Create', update: '✏ Update', delete: '✕ Delete', bulk_import: '⬆ Bulk' }[action] || action;
}

function formatActivityDate(iso) {
  if (!iso) return '—';
  try {
    const d = new Date(iso);
    const date = d.toLocaleDateString('th-TH', { year: 'numeric', month: 'short', day: 'numeric' });
    const time = d.toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    return `<span style="display:block;font-size:12px;font-weight:600">${date}</span><span style="display:block;font-size:11px;color:var(--text3)">${time}</span>`;
  } catch { return iso; }
}

async function fetchActivities() {
  try {
    const res = await apiCall('/api/activities?limit=200');
    activityData  = (res.data?.activities || []);
    const badge   = document.getElementById('activityNavBadge');
    if (badge) { badge.textContent = activityData.length; badge.style.display = activityData.length ? '' : 'none'; }
    activityPage  = 1;
    filterActivities();
  } catch (e) {
    showToast('ไม่สามารถโหลด Activity: ' + e.message, 'error');
  }
}

function getFilteredActivities() {
  const user   = (document.getElementById('activitySearchUser')?.value  || '').toLowerCase();
  const action = document.getElementById('activityFilterAction')?.value || '';
  const type   = document.getElementById('activityFilterType')?.value   || '';
  return activityData.filter(a =>
    (!user   || (a.username || '').toLowerCase().includes(user)) &&
    (!action || a.action      === action) &&
    (!type   || a.target_type === type)
  );
}

function filterActivities() {
  activityPage = 1;
  renderActivityTable();
}

function renderActivityTable() {
  const filtered   = getFilteredActivities();
  const totalPages = Math.max(1, Math.ceil(filtered.length / ACTIVITY_PAGE_SIZE));
  if (activityPage > totalPages) activityPage = 1;
  const start = (activityPage - 1) * ACTIVITY_PAGE_SIZE;
  const page  = filtered.slice(start, start + ACTIVITY_PAGE_SIZE);

  const tbody = document.getElementById('activityBody');
  if (!tbody) return;

  const countEl = document.getElementById('activityCount');
  if (countEl) countEl.textContent = `แสดง ${filtered.length} รายการ`;

  if (!page.length) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--text3)">ไม่พบข้อมูล Activity</td></tr>`;
  } else {
    tbody.innerHTML = page.map(a => `
      <tr style="cursor:default">
        <td style="font-family:var(--mono);font-size:11px;color:var(--text3)">${a.id}</td>
        <td>
          <div style="display:flex;align-items:center;gap:8px">
            <div style="width:28px;height:28px;border-radius:50%;background:var(--accent);color:#000;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;flex-shrink:0">${(a.username||'?')[0].toUpperCase()}</div>
            <span style="font-weight:500;font-size:13px">${a.username || '—'}</span>
          </div>
        </td>
        <td><span class="badge badge-${actionBadgeClass(a.action)}">${actionLabel(a.action)}</span></td>
        <td style="font-size:12px;color:var(--text3)">${a.target_type || '—'}</td>
        <td style="font-family:var(--mono);font-size:11px">${a.target_id ?? '—'}</td>
        <td style="font-size:12px;max-width:260px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${(a.summary||'').replace(/"/g,'&quot;')}">${a.summary || '—'}</td>
        <td>${formatActivityDate(a.created_at)}</td>
        <td>
          <button class="row-btn" title="ดูรายละเอียด" onclick="openActivityDetail(${a.id})">🔍</button>
        </td>
      </tr>`).join('');
  }

  // pagination
  const pag = document.getElementById('activityPagination');
  if (pag) {
    let html = `<button class="page-btn" onclick="goActivityPage(${activityPage-1})" ${activityPage===1?'disabled':''}>‹</button>`;
    for (let i = 1; i <= totalPages; i++) html += `<button class="page-btn ${i===activityPage?'active':''}" onclick="goActivityPage(${i})">${i}</button>`;
    html += `<button class="page-btn" onclick="goActivityPage(${activityPage+1})" ${activityPage===totalPages?'disabled':''}>›</button>`;
    pag.innerHTML = html;
  }
}

function goActivityPage(p) {
  const filtered   = getFilteredActivities();
  const totalPages = Math.max(1, Math.ceil(filtered.length / ACTIVITY_PAGE_SIZE));
  if (p < 1 || p > totalPages) return;
  activityPage = p;
  renderActivityTable();
}

async function openActivityDetail(id) {
  const overlay = document.getElementById('activityDetailModal');
  const body    = document.getElementById('activityModalBody');
  const title   = document.getElementById('activityModalTitle');
  if (!overlay || !body) return;

  body.innerHTML = `<div style="padding:32px;text-align:center;color:var(--text3)">กำลังโหลด…</div>`;
  overlay.classList.remove('hidden');

  try {
    const res  = await apiCall(`/api/activities/${id}`);
    const act  = res.data;
    title.textContent = `Activity #${act.id} — ${act.username}`;

    const detail = act.detail;
    let detailHtml = '';

    if (detail && typeof detail === 'object') {
      // before / after / changes
      const sections = [];
      if (detail.before) sections.push({ label: '📷 ก่อนแก้ไข (Before)', data: detail.before, color: '#f87171' });
      if (detail.after)  sections.push({ label: '✅ หลังแก้ไข (After)',  data: detail.after,  color: '#34d399' });
      if (detail.changes) sections.push({ label: '✏ ค่าที่เปลี่ยน (Changes)', data: detail.changes, color: 'var(--accent)' });
      if (detail.imported !== undefined) sections.push({ label: '📊 สรุป Import', data: { imported: detail.imported, skipped: detail.skipped, failed: detail.failed }, color: 'var(--accent)' });

      sections.forEach(sec => {
        detailHtml += `<div style="margin-bottom:20px">
          <div style="font-size:12px;font-weight:700;color:${sec.color};margin-bottom:8px;padding:0 24px">${sec.label}</div>
          <div style="background:var(--bg2);border-radius:8px;margin:0 16px;overflow:hidden">
            <table style="width:100%;border-collapse:collapse">
              ${Object.entries(sec.data).map(([k,v]) => `
                <tr style="border-bottom:1px solid var(--border)">
                  <td style="padding:8px 16px;font-size:12px;color:var(--text3);font-family:var(--mono);width:140px;white-space:nowrap">${k}</td>
                  <td style="padding:8px 16px;font-size:12px;word-break:break-all">${v === null ? '<em style="color:var(--text3)">null</em>' : String(v)}</td>
                </tr>`).join('')}
            </table>
          </div>
        </div>`;
      });

      if (!sections.length) {
        detailHtml = `<div style="padding:0 24px"><pre style="font-size:11px;background:var(--bg2);padding:16px;border-radius:8px;overflow:auto">${JSON.stringify(detail, null, 2)}</pre></div>`;
      }
    } else {
      detailHtml = `<div style="padding:0 24px;font-size:13px;color:var(--text3)">ไม่มีข้อมูลรายละเอียดเพิ่มเติม</div>`;
    }

    body.innerHTML = `
      <div style="padding:20px 0 8px">
        <!-- Meta info -->
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;padding:0 24px 20px;border-bottom:1px solid var(--border);margin-bottom:20px">
          <div>
            <div style="font-size:11px;color:var(--text3);margin-bottom:4px">ผู้ใช้งาน</div>
            <div style="font-weight:600;font-size:14px">${act.username}</div>
          </div>
          <div>
            <div style="font-size:11px;color:var(--text3);margin-bottom:4px">Action</div>
            <span class="badge badge-${actionBadgeClass(act.action)}">${actionLabel(act.action)}</span>
          </div>
          <div>
            <div style="font-size:11px;color:var(--text3);margin-bottom:4px">Target</div>
            <div style="font-size:13px">${act.target_type}${act.target_id ? ' #'+act.target_id : ''}</div>
          </div>
          <div style="grid-column:1/-1">
            <div style="font-size:11px;color:var(--text3);margin-bottom:4px">สรุป</div>
            <div style="font-size:13px">${act.summary || '—'}</div>
          </div>
          <div style="grid-column:1/-1">
            <div style="font-size:11px;color:var(--text3);margin-bottom:4px">วันที่ / เวลา</div>
            <div style="font-size:13px;font-family:var(--mono)">${act.created_at ? new Date(act.created_at).toLocaleString('th-TH') : '—'}</div>
          </div>
        </div>
        <!-- Detail -->
        ${detailHtml}
      </div>`;
  } catch (e) {
    body.innerHTML = `<div style="padding:24px;color:var(--error)">โหลดข้อมูลล้มเหลว: ${e.message}</div>`;
  }
}

function closeActivityModal() {
  const overlay = document.getElementById('activityDetailModal');
  if (overlay) overlay.classList.add('hidden');
}

// ════════════════════════════════════════════════════════════
//  USER MANAGEMENT
// ════════════════════════════════════════════════════════════

let _usersData    = [];      // รายการ users ทั้งหมด
let _currentRole  = 'viewer'; // role ของผู้ใช้ที่ login
let _editingUserId = null;   // null = create mode, number = edit mode
let _resetPwUserId = null;

// ── ดึง role ของตัวเองหลัง login ─────────────────────────────────────────────
async function fetchMyRole() {
  try {
    const res = await apiCall('/api/auth/me');
    _currentRole = res.data?.role || 'viewer';
    _applyMappingRoleUI();
  } catch (_) { /* ignore */ }
}

function _applyMappingRoleUI() {
  const canEdit  = _currentRole === 'admin' || _currentRole === 'editor';
  const isAdmin  = _currentRole === 'admin';
  // Mapping page header buttons
  const btnBulk  = document.getElementById('btnBulkImport');
  const btnAdd   = document.getElementById('btnAddRule');
  if (btnBulk) btnBulk.style.display = canEdit ? '' : 'none';
  if (btnAdd)  btnAdd.style.display  = canEdit ? '' : 'none';
  // Bulk action bar
  const bulkApproveBtn = document.querySelector('[onclick="bulkApprove()"]');
  const bulkDeleteBtn  = document.querySelector('[onclick="bulkDelete()"]');
  if (bulkApproveBtn) bulkApproveBtn.style.display = canEdit ? '' : 'none';
  if (bulkDeleteBtn)  bulkDeleteBtn.style.display  = isAdmin ? '' : 'none';
}

// ── โหลด users (ทุกคนดูได้ แต่แก้ไขได้เฉพาะ admin) ─────────────────────────
async function fetchUsers() {
  try {
    const res  = await apiCall('/api/users');
    _usersData = res.data || [];
    renderUsersTable();
    _applyUserAdminUI();
  } catch (e) {
    const tbody = document.getElementById('usersBody');
    if (tbody) tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:32px;color:var(--error)">โหลดข้อมูลล้มเหลว: ${e.message}</td></tr>`;
  }
}

function _applyUserAdminUI() {
  const isAdmin = _currentRole === 'admin';
  const btn     = document.getElementById('btnAddUser');
  const notice  = document.getElementById('userAdminNotice');
  const actHdr  = document.getElementById('userActionHeader');
  if (btn)    { btn.style.display    = isAdmin ? '' : 'none'; }
  if (notice) { notice.classList[isAdmin ? 'add' : 'remove']('hidden'); notice.classList[!isAdmin ? 'add' : 'remove']('hidden'); }
  if (actHdr) actHdr.textContent = isAdmin ? 'Actions' : '';
}

function roleBadgeClass(role) {
  return { admin: 'success', editor: 'warning', viewer: 'draft' }[role] || 'draft';
}

function roleLabel(role) {
  return { admin: '🛡 Admin', editor: '✏ Editor', viewer: '👁 Viewer' }[role] || role;
}

function fmtDate(iso) {
  if (!iso) return '—';
  try { return new Date(iso).toLocaleDateString('th-TH', { year:'numeric', month:'short', day:'numeric' }); }
  catch { return iso; }
}

function renderUsersTable() {
  const tbody   = document.getElementById('usersBody');
  if (!tbody) return;
  const isAdmin = _currentRole === 'admin';

  if (!_usersData.length) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:40px;color:var(--text3)">ยังไม่มีผู้ใช้ในระบบ</td></tr>`;
    return;
  }

  tbody.innerHTML = _usersData.map(u => `
    <tr>
      <td style="font-family:var(--mono);font-size:11px;color:var(--text3)">${u.id}</td>
      <td>
        <div style="display:flex;align-items:center;gap:8px">
          <div style="width:30px;height:30px;border-radius:50%;background:var(--accent);color:#000;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0">${(u.username||'?')[0].toUpperCase()}</div>
          <div>
            <div style="font-weight:600;font-size:13px">${u.username}</div>
          </div>
        </div>
      </td>
      <td style="font-size:13px;color:var(--text2)">${u.display_name || '—'}</td>
      <td><span class="badge badge-${roleBadgeClass(u.role)}">${roleLabel(u.role)}</span></td>
      <td>
        <span style="display:inline-flex;align-items:center;gap:4px;font-size:12px;${u.is_active ? 'color:#34d399' : 'color:var(--text3)'}">
          ${u.is_active ? '● Active' : '○ Inactive'}
        </span>
      </td>
      <td style="font-size:12px;color:var(--text3)">${fmtDate(u.created_at)}</td>
      <td style="font-size:12px;color:var(--text3)">${u.last_login ? fmtDate(u.last_login) : '—'}</td>
      <td>
        ${isAdmin ? `
        <div class="row-actions">
          <button class="row-btn" title="แก้ไข" onclick="openUserModal(${u.id})">✎</button>
          <button class="row-btn" title="Reset Password" onclick="openResetPwModal(${u.id},'${u.username}')">🔑</button>
          <button class="row-btn danger" title="ลบ" onclick="deleteUser(${u.id},'${u.username}')">✕</button>
        </div>` : ''}
      </td>
    </tr>`).join('');
}

// ── Open Create / Edit Modal ──────────────────────────────────────────────────
function openUserModal(userId = null) {
  _editingUserId = userId;
  const overlay = document.getElementById('userModal');
  const title   = document.getElementById('userModalTitle');
  const pwRow   = document.getElementById('uPasswordRow');
  const actRow  = document.getElementById('uActiveRow');
  if (!overlay) return;

  // reset fields
  document.getElementById('uUsername').value    = '';
  document.getElementById('uPassword').value    = '';
  document.getElementById('uDisplayName').value = '';
  document.getElementById('uRole').value        = 'viewer';
  document.getElementById('uIsActive').checked  = true;
  ['uUsernameErr','uPasswordErr'].forEach(id => document.getElementById(id)?.classList.add('hidden'));

  if (userId) {
    // Edit mode
    const u = _usersData.find(x => x.id === userId);
    if (!u) return;
    title.textContent = `แก้ไขผู้ใช้: ${u.username}`;
    document.getElementById('uUsername').value    = u.username;
    document.getElementById('uUsername').disabled = true;
    document.getElementById('uDisplayName').value = u.display_name || '';
    document.getElementById('uRole').value        = u.role;
    document.getElementById('uIsActive').checked  = u.is_active;
    pwRow?.classList.add('hidden');
    actRow?.classList.remove('hidden');
    document.getElementById('btnSaveUser').textContent = 'บันทึกการแก้ไข';
  } else {
    // Create mode
    title.textContent = 'เพิ่มผู้ใช้ใหม่';
    document.getElementById('uUsername').disabled = false;
    pwRow?.classList.remove('hidden');
    actRow?.classList.add('hidden');
    document.getElementById('btnSaveUser').textContent = 'สร้างผู้ใช้';
  }
  overlay.classList.remove('hidden');
}

function closeUserModal() {
  document.getElementById('userModal')?.classList.add('hidden');
  _editingUserId = null;
}

async function saveUser() {
  const btn = document.getElementById('btnSaveUser');
  let valid = true;

  const username    = document.getElementById('uUsername')?.value.trim().toLowerCase();
  const password    = document.getElementById('uPassword')?.value;
  const displayName = document.getElementById('uDisplayName')?.value.trim();
  const role        = document.getElementById('uRole')?.value;
  const isActive    = document.getElementById('uIsActive')?.checked ?? true;

  // Validate
  if (!_editingUserId) {
    const unErr = document.getElementById('uUsernameErr');
    if (!username || username.length < 3 || !/^[a-z0-9_\-.]+$/.test(username)) {
      unErr?.classList.remove('hidden');
      unErr.textContent = !username ? 'Username ต้องไม่ว่าง' : username.length < 3 ? 'ต้องมีอย่างน้อย 3 ตัวอักษร' : 'ใช้ได้เฉพาะ a-z, 0-9, _, -, .';
      valid = false;
    } else unErr?.classList.add('hidden');

    const pwErr = document.getElementById('uPasswordErr');
    if (!password || password.length < 6) {
      pwErr?.classList.remove('hidden');
      valid = false;
    } else pwErr?.classList.add('hidden');
  }

  if (!valid) return;

  if (btn) { btn.disabled = true; btn.textContent = 'กำลังบันทึก…'; }

  try {
    if (_editingUserId) {
      await apiCall(`/api/users/${_editingUserId}`, {
        method: 'PUT',
        body: JSON.stringify({ role, display_name: displayName, is_active: isActive }),
      });
      showToast('อัปเดตผู้ใช้สำเร็จ', 'success');
    } else {
      await apiCall('/api/users', {
        method: 'POST',
        body: JSON.stringify({ username, password, role, display_name: displayName }),
      });
      showToast(`สร้างผู้ใช้ '${username}' สำเร็จ`, 'success');
    }
    closeUserModal();
    await fetchUsers();
  } catch (e) {
    showToast(e.message || 'บันทึกล้มเหลว', 'error');
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = _editingUserId ? 'บันทึกการแก้ไข' : 'สร้างผู้ใช้'; }
  }
}

// ── Reset Password ────────────────────────────────────────────────────────────
function openResetPwModal(userId, username) {
  _resetPwUserId = userId;
  const overlay = document.getElementById('resetPwModal');
  const nameEl  = document.getElementById('resetPwUsername');
  const inp     = document.getElementById('newPwInput');
  if (!overlay) return;
  if (nameEl) nameEl.textContent = username;
  if (inp)    inp.value = '';
  document.getElementById('newPwErr')?.classList.add('hidden');
  overlay.classList.remove('hidden');
}

function closeResetPwModal() {
  document.getElementById('resetPwModal')?.classList.add('hidden');
  _resetPwUserId = null;
}

async function confirmResetPw() {
  const pw  = document.getElementById('newPwInput')?.value;
  const err = document.getElementById('newPwErr');
  if (!pw || pw.length < 6) {
    err?.classList.remove('hidden');
    return;
  }
  err?.classList.add('hidden');
  try {
    await apiCall(`/api/users/${_resetPwUserId}/reset-password`, {
      method: 'POST',
      body: JSON.stringify({ new_password: pw }),
    });
    showToast('Reset password สำเร็จ', 'success');
    closeResetPwModal();
  } catch (e) {
    showToast(e.message || 'Reset ล้มเหลว', 'error');
  }
}

// ── Delete User ───────────────────────────────────────────────────────────────
async function deleteUser(userId, username) {
  if (!confirm(`ยืนยันลบผู้ใช้ "${username}" ?\nการกระทำนี้ไม่สามารถยกเลิกได้`)) return;
  try {
    await apiCall(`/api/users/${userId}`, { method: 'DELETE' });
    showToast(`ลบผู้ใช้ '${username}' สำเร็จ`, 'success');
    await fetchUsers();
  } catch (e) {
    showToast(e.message || 'ลบล้มเหลว', 'error');
  }
}

// ── Toggle password visibility ────────────────────────────────────────────────
function toggleFieldPw(inputId, iconEl) {
  const inp  = document.getElementById(inputId);
  if (!inp) return;
  const hide = inp.type === 'password';
  inp.type   = hide ? 'text' : 'password';
  if (iconEl) iconEl.style.color = hide ? 'var(--accent)' : 'var(--text3)';
}
