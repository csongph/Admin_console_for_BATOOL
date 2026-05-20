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
    // เก็บลงที่เดิม (localStorage หรือ sessionStorage ตามที่เลือก)
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
    // ลอง refresh token ก่อน logout
    const refreshed = await _refreshToken();
    if (refreshed) {
      // retry ครั้งเดียว
      return apiCall(path, options);
    }
    // refresh ไม่ได้ → logout
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

// Auto-refresh token 5 นาทีก่อนหมดอายุ (ค่า default expire = 60 นาที)
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
  // sync ทั้ง topbar toggle และ settings toggle
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
    const labels = { dashboard:'Dashboard', mapping:'Mapping Manager', databases:'Database Registry', sessions:'Session Monitor', logs:'Log Viewer', settings:'Settings' };
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

// sync settings toggle เมื่อเปิดหน้า settings
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

function normMapping(m) {
  return { id:m.id, srcDb:m.src_db, rawType:m.raw_type, sourceType:m.source_type||'', logicalType:m.logical_type, masterType:m.master_type, destDb:m.dest_db, finalType:m.final_type, confidence:m.confidence??100, status:m.status, updated:m.updated };
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
    (!search || [m.srcDb,m.rawType,m.logicalType,m.masterType,m.finalType].some(v => (v||'').toLowerCase().includes(search))) &&
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
        <td><div class="row-actions"><button class="row-btn" title="Edit" onclick="editMapping(${m.id})">✎</button><button class="row-btn danger" title="Delete" onclick="deleteMapping(${m.id})">✕</button></div></td>
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

function editMapping(id) {
  const m = mappingData.find(r => r.id === id);
  if (!m) return;
  document.getElementById('mSrcDb').value       = m.srcDb;
  document.getElementById('mDestDb').value      = m.destDb;
  document.getElementById('mRawType').value     = m.rawType;
  document.getElementById('mLogicalType').value = m.logicalType;
  document.getElementById('mMasterType').value  = m.masterType;
  document.getElementById('mFinalType').value   = m.finalType;
  document.getElementById('mStatus').value      = m.status;
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

function openAddMapping() {
  document.getElementById('mappingModalTitle').textContent = 'Add Mapping Rule';
  ['mSrcDb','mDestDb','mRawType','mLogicalType','mMasterType','mFinalType'].forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; });
  delete document.getElementById('mappingModal').dataset.editId;
  openModal('mappingModal');
}

async function saveMapping() {
  const raw = document.getElementById('mRawType')?.value.trim();
  if (!raw) { showToast('Raw Type is required', 'error'); return; }
  const payload = {
    src_db:       document.getElementById('mSrcDb')?.value || 'sqlserver',
    raw_type:     raw,
    logical_type: document.getElementById('mLogicalType')?.value.trim() || '',
    master_type:  document.getElementById('mMasterType')?.value.trim() || '',
    dest_db:      document.getElementById('mDestDb')?.value || 'confluent',
    final_type:   document.getElementById('mFinalType')?.value.trim() || '',
    confidence:   100,
    status:       document.getElementById('mStatus')?.value || 'draft',
  };
  const editId = document.getElementById('mappingModal').dataset.editId;
  try {
    if (editId) { await apiCall(`/api/mappings/${editId}`, { method:'PUT', body:JSON.stringify(payload) }); showToast('Mapping rule updated', 'success'); }
    else        { await apiCall('/api/mappings', { method:'POST', body:JSON.stringify(payload) }); showToast('Mapping rule saved', 'success'); }
    closeModal('mappingModal');
    await fetchMappings();
  } catch (e) { showToast('Save failed: ' + e.message, 'error'); }
}

// Bulk Import — ซ่อนจน implement จริง
function openBulkImport() { showToast('Bulk import coming soon', 'info'); }

// AI Generate — ซ่อนจน implement จริง (endpoint ยังไม่มี)
function openAIGenerate() { showToast('AI Generate coming soon — backend endpoint pending', 'info'); }

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
  document.getElementById('dbName').value    = db.key;
  document.getElementById('dbLabel').value   = db.name;
  document.getElementById('dbVersion').value = db.version || '';
  document.getElementById('dbStatus').value  = db.status || 'active';
  document.getElementById('dbModalTitle').textContent = 'Edit Database';
  document.getElementById('dbModal').dataset.editId = id;
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

function openAddDatabase() {
  ['dbName','dbLabel','dbVersion'].forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; });
  document.getElementById('dbModalTitle').textContent = 'Add Database';
  delete document.getElementById('dbModal').dataset.editId;
  openModal('dbModal');
}

async function saveDatabase() {
  const name    = document.getElementById('dbLabel')?.value.trim();
  const key     = document.getElementById('dbName')?.value.trim();
  const version = document.getElementById('dbVersion')?.value.trim();
  const status  = document.getElementById('dbStatus')?.value || 'active';
  if (!name || !key) { showToast('Name and Key are required', 'error'); return; }
  const editId = document.getElementById('dbModal').dataset.editId;
  try {
    if (editId) { await apiCall(`/api/databases/${editId}`, { method:'PUT', body:JSON.stringify({ name, key, version, status }) }); showToast(`Database "${name}" updated`, 'success'); }
    else        { await apiCall('/api/databases', { method:'POST', body:JSON.stringify({ name, key, version, status, enabled:true }) }); showToast(`Database "${name}" added`, 'success'); }
    closeModal('dbModal'); await fetchDatabases();
  } catch (e) { showToast('Save failed: ' + e.message, 'error'); }
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
  // ส่ง JWT token ผ่าน query param
  const url   = `${proto}://${host}/ws/presence/admin?token=${encodeURIComponent(token)}`;
  presenceWs  = new WebSocket(url);

  presenceWs.onopen = () => {
    startPresencePing();
  };
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
//  LOG VIEWER — dedup polling ด้วย /api/logs/new
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

// ── Polling ใช้ /api/logs/new เพื่อรับเฉพาะ entries ใหม่ (ไม่ซ้ำ) ──────────
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
  } catch { /* เงียบ — ไม่ spam toast */ }
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
//  INIT
// ════════════════════════════════════════════════════════════

function init() {
  fetchMappings();
  fetchDatabases();
  fetchSessions();
  fetchLogs();
  refreshDashboard();
  connectPresence();
}
