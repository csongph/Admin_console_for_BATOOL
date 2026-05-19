/* ============================================================
   BA Tool — Admin Console  |  app.js (Cleaned - No Mockup)
   Compatible with index.html + styles.css (responsive)
   ============================================================ */

'use strict';

// ════════════════════════════════════════════════════════════
//  API CONFIG
//  เปลี่ยน API_URL เป็น Render URL ตอน deploy จริง
//  เช่น: 'https://ba-tool-backend.onrender.com'
// ════════════════════════════════════════════════════════════

const API_URL = 'http://localhost:8000';

async function apiCall(path, options = {}) {
  const token = localStorage.getItem('ba_token') || sessionStorage.getItem('ba_token');
  const res = await fetch(API_URL + path, {
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...options,
  });
  const data = await res.json();
  if (!res.ok) {
    // token หมดอายุ → logout อัตโนมัติ
    if (res.status === 401) {
      localStorage.removeItem('ba_token');
      localStorage.removeItem('ba_session');
      sessionStorage.removeItem('ba_token');
      sessionStorage.removeItem('ba_session');
      if (typeof doLogout === 'function') doLogout();
    }
    throw new Error(data.detail || data.message || `HTTP ${res.status}`);
  }
  return data;
}

// ════════════════════════════════════════════════════════════
//  THEME — persist ใน localStorage
// ════════════════════════════════════════════════════════════

(function initTheme() {
  const saved = localStorage.getItem('ba_theme');
  if (saved) document.documentElement.setAttribute('data-theme', saved);
})();

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('ba_theme', theme);
  // sync settings checkbox
  const cb = document.getElementById('themeCheckbox');
  if (cb) cb.checked = theme === 'light';
}

// ════════════════════════════════════════════════════════════
//  MOBILE SIDEBAR
// ════════════════════════════════════════════════════════════

const sidebar   = document.getElementById('sidebar');
const mainWrap  = document.getElementById('mainWrap');

let sidebarOverlay = document.querySelector('.sidebar-overlay');
if (!sidebarOverlay) {
  sidebarOverlay = document.createElement('div');
  sidebarOverlay.className = 'sidebar-overlay';
  document.body.appendChild(sidebarOverlay);
}

function isMobile() { return window.innerWidth <= 768; }

function openMobileSidebar() {
  sidebar.classList.add('mobile-open');
  sidebarOverlay.classList.add('active');
  document.body.style.overflow = 'hidden'; 
}

function closeMobileSidebar() {
  sidebar.classList.remove('mobile-open');
  sidebarOverlay.classList.remove('active');
  document.body.style.overflow = '';
}

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

window.addEventListener('resize', () => {
  if (!isMobile()) {
    closeMobileSidebar();
    document.body.style.overflow = '';
  }
});

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
    const labels = {
      dashboard: 'Dashboard',
      mapping: 'Mapping Manager',
      databases: 'Database Registry',
      sessions: 'Session Monitor',
      logs: 'Log Viewer',
      settings: 'Settings',
    };
    bcPage.textContent = labels[page] || page;
  }

  if (isMobile()) closeMobileSidebar();
}

document.querySelectorAll('.nav-item[data-page]').forEach(item => {
  item.addEventListener('click', e => {
    e.preventDefault();
    navigate(item.dataset.page);
  });
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

// ════════════════════════════════════════════════════════════
//  AVATAR DROPDOWN
// ════════════════════════════════════════════════════════════

function toggleAvatarMenu() {
  document.getElementById('avatarDropdown')?.classList.toggle('hidden');
}
function closeAvatarMenu() {
  document.getElementById('avatarDropdown')?.classList.add('hidden');
}
document.addEventListener('click', e => {
  const wrap = document.getElementById('avatarWrap');
  if (wrap && !wrap.contains(e.target)) closeAvatarMenu();
});

// ════════════════════════════════════════════════════════════
//  TOAST NOTIFICATIONS
// ════════════════════════════════════════════════════════════

const toastContainer = document.getElementById('toastContainer');

function showToast(message, type = 'info') {
  if (!toastContainer) return;

  const icons = { success: '✓', error: '✕', warn: '⚠', info: 'ℹ' };
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span class="toast-icon">${icons[type] || icons.info}</span>
    <span class="toast-msg">${message}</span>
  `;

  toastContainer.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('out');
    setTimeout(() => toast.remove(), 220);
  }, 3000);
}

// ════════════════════════════════════════════════════════════
//  MODAL HELPERS
// ════════════════════════════════════════════════════════════

function openModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.remove('hidden');
}

function closeModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.add('hidden');
}

document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => {
    if (e.target === overlay) overlay.classList.add('hidden');
  });
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal-overlay:not(.hidden)').forEach(m => m.classList.add('hidden'));
    closeAvatarMenu();
  }
});

// ════════════════════════════════════════════════════════════
//  DASHBOARD
// ════════════════════════════════════════════════════════════

const BA_TOOL_URL = 'https://ba-tool-backend.onrender.com';

async function fetchBATool(path) {
  const res = await fetch(BA_TOOL_URL + path);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function parseLogs(logs) {
  const today = new Date().toISOString().slice(0, 10);

  // Sessions ที่ created วันนี้
  const createdToday = logs.filter(l =>
    l.message.includes('created') && l.message.includes('Session') && l.timestamp.startsWith(today)
  );

  // Sessions ที่ยังไม่ถูก delete (active)
  const deletedIds = new Set(
    logs.filter(l => l.message.includes('deleted'))
      .map(l => { const m = l.message.match(/Session ([a-f0-9-]+)/); return m?.[1]; })
      .filter(Boolean)
  );
  const activeSessions = logs.filter(l => {
    const m = l.message.match(/Session ([a-f0-9-]+) created/);
    return m && !deletedIds.has(m[1]);
  });

  // Conversions วันนี้ = จำนวน Convert วันนี้
  const conversionsToday = logs.filter(l =>
    l.message.includes('Convert') && l.timestamp.startsWith(today)
  ).length;

  // Warning วันนี้
  const warningsToday = logs.filter(l =>
    l.level === 'WARNING' && l.timestamp.startsWith(today)
  ).length;

  return { createdToday, activeSessions, conversionsToday, warningsToday };
}

async function refreshDashboard() {
  try {
    const start = Date.now();

    const [health, systemStatus, dbSupport, dbPairs, logs] = await Promise.allSettled([
      apiCall('/api/health'),
      apiCall('/api/system/status'),
      fetchBATool('/database-support'),
      fetchBATool('/db-pairs'),
      fetchBATool('/logs'),
    ]);

    const ping = Date.now() - start;

    // ── Status Cards ──────────────────────────────────────
    const cards = document.querySelectorAll('.status-card');
    const healthOk = health.status === 'fulfilled' && health.value?.success;
    if (cards[0]) {
      cards[0].querySelector('.sc-val').textContent = healthOk ? 'Online' : 'Error';
      cards[0].querySelector('.sc-ping').textContent = `${ping} ms`;
      cards[0].querySelector('.sc-indicator').className = `sc-indicator ${healthOk ? 'online' : 'offline'}`;
    }

    // ── Sidebar status ────────────────────────────────────
    const statusDot   = document.querySelector('.status-dot');
    const statusLabel = document.querySelector('.status-label');
    const isRunning   = systemStatus.status === 'fulfilled' && systemStatus.value?.data?.status === 'running';
    if (statusDot)   statusDot.className     = `status-dot ${isRunning ? 'online' : 'offline'}`;
    if (statusLabel) statusLabel.textContent  = isRunning ? 'System Online' : 'System Stopped';

    // ── Parse logs ────────────────────────────────────────
    const logList = logs.status === 'fulfilled' ? (logs.value || []) : [];
    const { activeSessions, conversionsToday, warningsToday, createdToday } = parseLogs(logList);

    // ── Metric Cards ──────────────────────────────────────
    const metrics = document.querySelectorAll('.metric-card');

    // Supported Databases
    const dbList = dbSupport.status === 'fulfilled'
      ? (dbSupport.value?.database_support_matrix || []) : [];
    if (metrics[0]) {
      metrics[0].querySelector('.metric-val').textContent = dbList.length || '-';
      metrics[0].querySelector('.metric-sub').textContent = dbList.map(d => d.database).join(', ') || '-';
    }

    // Total Mapping Pairs
    const pairs = dbPairs.status === 'fulfilled' ? (dbPairs.value?.pairs || []) : [];
    if (metrics[1]) {
      metrics[1].querySelector('.metric-val').textContent = pairs.length || '-';
      metrics[1].querySelector('.metric-sub').textContent = `${pairs.length} conversion pairs`;
    }

    // Active Sessions
    if (metrics[2]) {
      metrics[2].querySelector('.metric-val').textContent = activeSessions.length;
      metrics[2].querySelector('.metric-sub').textContent = `${createdToday.length} created today`;
    }

    // Conversions Today
    if (metrics[3]) {
      metrics[3].querySelector('.metric-val').textContent = conversionsToday;
      metrics[3].querySelector('.metric-sub').textContent = warningsToday ? `⚠ ${warningsToday} warning(s) today` : 'No warnings today';
    }

    // ── Database Coverage ─────────────────────────────────
    const coverageList = document.getElementById('dbCoverageList');
    if (coverageList && dbList.length && pairs.length) {
      const total = dbList.length - 1 || 1;
      const pairCount = {};
      pairs.forEach(p => {
        const key = p.source_db.toLowerCase();
        pairCount[key] = (pairCount[key] || 0) + 1;
      });
      coverageList.innerHTML = dbList.map(db => {
        const key = db.database.toLowerCase().replace(' ', '').replace('sql server', 'sqlserver');
        const count = pairCount[key] || pairCount[db.database.toLowerCase()] || 0;
        const pct = Math.round((count / total) * 100);
        return `
          <div class="db-cov-item">
            <span class="db-cov-name">${db.database}</span>
            <div class="db-cov-bar"><div class="db-cov-fill" style="width:${pct}%"></div></div>
            <span class="db-cov-pct">${pct}%</span>
          </div>`;
      }).join('');
    }

    // ── Activity Feed ─────────────────────────────────────
    const activityFeed = document.getElementById('activityFeed');
    if (activityFeed && logList.length) {
      const recent = [...logList].reverse().slice(0, 8);
      activityFeed.innerHTML = recent.map(l => {
        const level = (l.level || 'INFO').toUpperCase();
        const dotClass = level === 'WARNING' ? 'warn' : level === 'ERROR' ? 'error' : 'success';
        return `
          <div class="activity-item">
            <div class="activity-dot ${dotClass}"></div>
            <div class="activity-body">
              <div class="activity-msg">${l.message}</div>
              <div class="activity-time">${l.timestamp}</div>
            </div>
          </div>`;
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

let mappingData = []; // populated from API

let mappingCurrentPage = 1;
const MAPPING_PAGE_SIZE = 8;
let selectedMappings = new Set();

// แปลง snake_case จาก API → camelCase ที่ UI ใช้
function normMapping(m) {
  return {
    id:          m.id,
    srcDb:       m.src_db,
    rawType:     m.raw_type,
    sourceType:  m.source_type  || '',
    logicalType: m.logical_type,
    masterType:  m.master_type,
    destDb:      m.dest_db,
    finalType:   m.final_type,
    confidence:  m.confidence ?? 100,
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
    renderMappingTable();
  } catch (e) {
    showToast('Failed to load mappings: ' + e.message, 'error');
  }
}

function getFilteredMappings() {
  const search = (document.getElementById('mappingSearch')?.value || '').toLowerCase();
  const srcDb  = document.getElementById('filterSrcDb')?.value  || '';
  const destDb = document.getElementById('filterDestDb')?.value || '';
  const status = document.getElementById('filterStatus')?.value || '';

  return mappingData.filter(m =>
    (!search || [m.srcDb, m.rawType, m.logicalType, m.masterType, m.finalType].some(v => (v||'').toLowerCase().includes(search))) &&
    (!srcDb  || m.srcDb  === srcDb)  &&
    (!destDb || m.destDb === destDb) &&
    (!status || m.status === status)
  );
}

function renderMappingTable() {
  const filtered = getFilteredMappings();
  const totalPages = Math.max(1, Math.ceil(filtered.length / MAPPING_PAGE_SIZE));
  if (mappingCurrentPage > totalPages) mappingCurrentPage = 1;

  const start = (mappingCurrentPage - 1) * MAPPING_PAGE_SIZE;
  const page  = filtered.slice(start, start + MAPPING_PAGE_SIZE);

  const tbody = document.getElementById('mappingBody');
  if (!tbody) return;

  if (!page.length) {
    tbody.innerHTML = `<tr><td colspan="12" style="text-align:center;padding:32px;color:var(--text3)">No mapping rules found</td></tr>`;
  } else {
    tbody.innerHTML = page.map(m => `
      <tr>
        <td class="th-check">
          <input type="checkbox" ${selectedMappings.has(m.id) ? 'checked' : ''}
            onchange="toggleSelect(${m.id}, this.checked)" />
        </td>
        <td class="td-name">${m.srcDb}</td>
        <td>${m.rawType}</td>
        <td style="font-family:var(--mono);font-size:11px;color:var(--text3)">${m.sourceType}</td>
        <td>${m.logicalType}</td>
        <td>${m.masterType}</td>
        <td>${m.destDb}</td>
        <td>${m.finalType}</td>
        <td>
          <div class="confidence-bar">
            <div class="conf-track"><div class="conf-fill" style="width:${m.confidence}%"></div></div>
            <span class="conf-txt">${m.confidence}%</span>
          </div>
        </td>
        <td><span class="badge badge-${m.status}">${m.status}</span></td>
        <td>${m.updated}</td>
        <td>
          <div class="row-actions">
            <button class="row-btn" title="Edit" onclick="editMapping(${m.id})">✎</button>
            <button class="row-btn danger" title="Delete" onclick="deleteMapping(${m.id})">✕</button>
          </div>
        </td>
      </tr>
    `).join('');
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
  for (let i = 1; i <= totalPages; i++) {
    html += `<button class="page-btn ${i===mappingCurrentPage?'active':''}" onclick="goMappingPage(${i})">${i}</button>`;
  }
  html += `<button class="page-btn" onclick="goMappingPage(${mappingCurrentPage+1})" ${mappingCurrentPage===totalPages?'disabled':''}>›</button>`;
  pag.innerHTML = html;
}

function goMappingPage(p) {
  const filtered = getFilteredMappings();
  const totalPages = Math.max(1, Math.ceil(filtered.length / MAPPING_PAGE_SIZE));
  if (p < 1 || p > totalPages) return;
  mappingCurrentPage = p;
  renderMappingTable();
}

function filterMappings() {
  mappingCurrentPage = 1;
  selectedMappings.clear();
  renderMappingTable();
}

function toggleSelect(id, checked) {
  checked ? selectedMappings.add(id) : selectedMappings.delete(id);
  updateBulkBar();
}

function toggleAll(checkbox) {
  const filtered = getFilteredMappings();
  const start = (mappingCurrentPage - 1) * MAPPING_PAGE_SIZE;
  filtered.slice(start, start + MAPPING_PAGE_SIZE).forEach(m => {
    checkbox.checked ? selectedMappings.add(m.id) : selectedMappings.delete(m.id);
  });
  renderMappingTable();
}

function updateBulkBar() {
  const bar = document.getElementById('tableBulk');
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
  document.getElementById('deleteWarnText').textContent =
    `Delete mapping "${m.rawType} → ${m.finalType}"? This cannot be undone.`;
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try {
      await apiCall(`/api/mappings/${id}`, { method: 'DELETE' });
      selectedMappings.delete(id);
      showToast('Mapping rule deleted', 'info');
      closeModal('deleteModal');
      await fetchMappings();
    } catch (e) {
      showToast('Delete failed: ' + e.message, 'error');
    }
  };
  openModal('deleteModal');
}

function bulkDelete() {
  if (!selectedMappings.size) return;
  document.getElementById('deleteWarnText').textContent =
    `Delete ${selectedMappings.size} selected mapping(s)? This cannot be undone.`;
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try {
      await Promise.all([...selectedMappings].map(id =>
        apiCall(`/api/mappings/${id}`, { method: 'DELETE' })
      ));
      selectedMappings.clear();
      showToast('Selected mappings deleted', 'info');
      closeModal('deleteModal');
      await fetchMappings();
    } catch (e) {
      showToast('Bulk delete failed: ' + e.message, 'error');
    }
  };
  openModal('deleteModal');
}

function bulkApprove() {
  if (!selectedMappings.size) return;
  Promise.all([...selectedMappings].map(id =>
    apiCall(`/api/mappings/${id}`, { method: 'PUT', body: JSON.stringify({ status: 'active' }) })
  )).then(() => {
    showToast(`${selectedMappings.size} mapping(s) set to active`, 'success');
    selectedMappings.clear();
    fetchMappings();
  }).catch(e => showToast('Approve failed: ' + e.message, 'error'));
}

function openAddMapping() {
  document.getElementById('mappingModalTitle').textContent = 'Add Mapping Rule';
  ['mSrcDb','mDestDb','mRawType','mLogicalType','mMasterType','mFinalType'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
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
    showToast('Save failed: ' + e.message, 'error');
  }
}

function openBulkImport() {
  showToast('Bulk import — feature coming soon', 'info');
}

// ── AI Generate ────────────────────────────────────────────
const aiSuggestions = []; // Mockup cleared
let aiDecisions = {};

function openAIGenerate() {
  aiDecisions = {};
  document.getElementById('aiStep1').classList.remove('hidden');
  document.getElementById('aiStep2').classList.add('hidden');
  document.getElementById('aiGenerateBtn').classList.remove('hidden');
  document.getElementById('aiSaveBtn').classList.add('hidden');
  openModal('aiModal');
}

function runAIGenerate() {
  const src  = document.getElementById('aiSrcDb')?.value;
  const dest = document.getElementById('aiDestDb')?.value;
  if (!src || !dest) { showToast('Please select source and destination databases', 'error'); return; }

  const btn = document.getElementById('aiGenerateBtn');
  btn.textContent = '⟳ Generating…';
  btn.disabled = true;

  // Placeholder for real API call
  setTimeout(() => {
    aiDecisions = {};
    aiSuggestions.forEach((_, i) => aiDecisions[i] = 'pending');

    renderAIReview();
    document.getElementById('aiStep1').classList.add('hidden');
    document.getElementById('aiStep2').classList.remove('hidden');
    btn.textContent = '✦ Generate';
    btn.disabled = false;
    btn.classList.add('hidden');
    document.getElementById('aiSaveBtn').classList.remove('hidden');
    updateReviewStats();
  }, 1500);
}

function renderAIReview() {
  const tbody = document.getElementById('reviewBody');
  if (!tbody) return;
  
  if (!aiSuggestions.length) {
      tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:32px;color:var(--text3)">No suggestions generated</td></tr>`;
      return;
  }

  tbody.innerHTML = aiSuggestions.map((s, i) => `
    <tr id="aiRow_${i}" class="${aiDecisions[i]==='approved'?'approved':aiDecisions[i]==='rejected'?'rejected':''}">
      <td>${s.src}</td>
      <td>${s.raw}</td>
      <td>${s.logical}</td>
      <td>${s.final}</td>
      <td>
        <div class="confidence-bar">
          <div class="conf-track"><div class="conf-fill" style="width:${s.confidence}%"></div></div>
          <span class="conf-txt">${s.confidence}%</span>
        </div>
      </td>
      <td>
        <div class="decision-btns">
          <button class="decision-btn approve ${aiDecisions[i]==='approved'?'active':''}"
            onclick="setDecision(${i},'approved')">✓</button>
          <button class="decision-btn reject ${aiDecisions[i]==='rejected'?'active':''}"
            onclick="setDecision(${i},'rejected')">✕</button>
        </div>
      </td>
    </tr>
  `).join('');
}

function setDecision(i, decision) {
  aiDecisions[i] = aiDecisions[i] === decision ? 'pending' : decision;
  renderAIReview();
  updateReviewStats();
}

function updateReviewStats() {
  const vals = Object.values(aiDecisions);
  document.getElementById('rApproved').textContent = vals.filter(v => v === 'approved').length;
  document.getElementById('rRejected').textContent = vals.filter(v => v === 'rejected').length;
  document.getElementById('rPending').textContent  = vals.filter(v => v === 'pending').length;
}

function batchApprove() {
  Object.keys(aiDecisions).forEach(k => aiDecisions[k] = 'approved');
  renderAIReview(); updateReviewStats();
}

function batchReject() {
  Object.keys(aiDecisions).forEach(k => aiDecisions[k] = 'rejected');
  renderAIReview(); updateReviewStats();
}

async function saveApproved() {
  const approved = aiSuggestions.filter((_, i) => aiDecisions[i] === 'approved');
  if (!approved.length) { showToast('No approved mappings to save', 'warn'); return; }
  const srcDb  = document.getElementById('aiSrcDb')?.value || 'sqlserver';
  const destDb = document.getElementById('aiDestDb')?.value || 'confluent';
  try {
    await Promise.all(approved.map(s => apiCall('/api/mappings', {
      method: 'POST',
      body: JSON.stringify({
        src_db:       srcDb,
        raw_type:     s.raw,
        logical_type: s.logical,
        master_type:  s.logical.toUpperCase(),
        dest_db:      destDb,
        final_type:   s.final,
        confidence:   s.confidence,
        status:       'active',
      }),
    })));
    showToast(`${approved.length} mapping(s) saved successfully`, 'success');
    closeModal('aiModal');
    await fetchMappings();
  } catch (e) {
    showToast('Save failed: ' + e.message, 'error');
  }
}

// ════════════════════════════════════════════════════════════
//  DATABASE REGISTRY
// ════════════════════════════════════════════════════════════

let dbData = []; // populated from API

const DB_ICONS = {
  sqlserver: '🗄', postgresql: '🐘', mysql: '🐬',
  oracle: '🔴', confluent: '⚡', default: '🗄',
};

async function fetchDatabases() {
  try {
    const data = await apiCall('/api/databases');
    dbData = data.data || [];
    renderDatabases();
  } catch (e) {
    showToast('Failed to load databases: ' + e.message, 'error');
  }
}

function renderDatabases() {
  const grid = document.getElementById('dbGrid');
  if (!grid) return;

  if (!dbData.length) {
    grid.innerHTML = `<div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--text3);border:1px dashed var(--border2);border-radius:var(--radius);">No databases configured</div>`;
    return;
  }

  grid.innerHTML = dbData.map(db => {
    const icon = DB_ICONS[db.key] || DB_ICONS.default;
    return `
    <div class="db-card">
      <div class="db-card-header">
        <div class="db-card-info">
          <div class="db-logo">${icon}</div>
          <div>
            <div class="db-card-name">${db.name}</div>
            <div class="db-card-key">${db.key}${db.version ? ' · ' + db.version : ''}</div>
          </div>
        </div>
        <div class="db-card-toggle">
          <label class="toggle-switch">
            <input type="checkbox" ${db.enabled ? 'checked' : ''}
              onchange="toggleDatabase(${db.id}, this.checked)" />
            <span class="toggle-track"></span>
          </label>
        </div>
      </div>
      <div class="db-card-stats">
        <div class="db-stat">
          <div class="db-stat-label">Mapping Rules</div>
          <div class="db-stat-val">${db.rules}</div>
        </div>
        <div class="db-stat">
          <div class="db-stat-label">Active Sessions</div>
          <div class="db-stat-val">${db.sessions}</div>
        </div>
      </div>
      <div class="db-card-actions">
        <button class="btn btn-sm btn-ghost" onclick="showToast('Viewing rules for ${db.name}','info')">View Rules</button>
        <button class="btn btn-sm btn-ghost" onclick="editDatabase(${db.id})">Edit</button>
        <button class="btn btn-sm btn-danger" onclick="confirmDeleteDatabase(${db.id})">Delete</button>
      </div>
    </div>`;
  }).join('');
}

async function toggleDatabase(id, enabled) {
  const db = dbData.find(d => d.id === id);
  if (!db) return;
  try {
    await apiCall(`/api/databases/${id}`, { method: 'PUT', body: JSON.stringify({ enabled }) });
    db.enabled = enabled;
    showToast(`${db.name} ${enabled ? 'enabled' : 'disabled'}`, enabled ? 'success' : 'warn');
  } catch (e) {
    showToast('Update failed: ' + e.message, 'error');
    renderDatabases(); // revert toggle UI
  }
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
  document.getElementById('deleteWarnText').textContent =
    `Delete "${db.name}" from the registry? All associated mapping rules (${db.rules}) will also be removed.`;
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try {
      await apiCall(`/api/databases/${id}`, { method: 'DELETE' });
      showToast(`${db.name} removed`, 'warn');
      closeModal('deleteModal');
      await fetchDatabases();
    } catch (e) {
      showToast('Delete failed: ' + e.message, 'error');
    }
  };
  openModal('deleteModal');
}

function openAddDatabase() {
  ['dbName','dbLabel','dbVersion'].forEach(id => {
    const el = document.getElementById(id); if (el) el.value = '';
  });
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
    if (editId) {
      await apiCall(`/api/databases/${editId}`, { method: 'PUT', body: JSON.stringify({ name, key, version, status }) });
      showToast(`Database "${name}" updated`, 'success');
    } else {
      await apiCall('/api/databases', { method: 'POST', body: JSON.stringify({ name, key, version, status, enabled: true }) });
      showToast(`Database "${name}" added`, 'success');
    }
    closeModal('dbModal');
    await fetchDatabases();
  } catch (e) {
    showToast('Save failed: ' + e.message, 'error');
  }
}

// ════════════════════════════════════════════════════════════
//  SESSION MONITOR
// ════════════════════════════════════════════════════════════

let sessionData = []; // populated from API

async function fetchSessions() {
  try {
    const data = await apiCall('/api/sessions');
    const payload = data.data || {};
    sessionData = payload.sessions || [];
    const stats  = payload.stats   || { active: 0, warning: 0, expired: 0 };

    const elActive   = document.getElementById('sessActive');
    const elExpiring = document.getElementById('sessExpiring');
    const elExpired  = document.getElementById('sessExpired');
    if (elActive)   elActive.textContent   = stats.active;
    if (elExpiring) elExpiring.textContent = stats.warning;
    if (elExpired)  elExpired.textContent  = stats.expired;

    const liveBadge = document.querySelector('.nav-item[data-page="sessions"] .nav-badge.live');
    if (liveBadge) liveBadge.textContent = stats.active + stats.warning;

    renderSessions();
  } catch (e) {
    showToast('Failed to load sessions: ' + e.message, 'error');
  }
}

function renderSessions() {
  const tbody = document.getElementById('sessionBody');
  if (!tbody) return;

  if (!sessionData.length) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:32px;color:var(--text3)">No active sessions found</td></tr>`;
    return;
  }

  tbody.innerHTML = sessionData.map(s => {
    const ttlClass = s.ttl === 0 ? 'expired' : s.ttl < 10 ? 'warn' : 'ok';
    const ttlText  = s.ttl === 0 ? 'Expired' : `${s.ttl}m`;
    return `
      <tr>
        <td style="font-family:var(--mono);font-size:11px;color:var(--accent)">${s.id}</td>
        <td style="color:var(--text2)">${s.user}</td>
        <td><span class="badge badge-active">${s.role}</span></td>
        <td style="font-family:var(--mono);font-size:11px">${s.db}</td>
        <td style="font-family:var(--mono)">${s.tables}</td>
        <td style="font-family:var(--mono);font-size:11px;color:var(--text3)">${s.created}</td>
        <td><span class="ttl-badge ${ttlClass}">⏱ ${ttlText}</span></td>
        <td><span class="badge badge-${s.status==='active'?'active':s.status==='warning'?'draft':'deprecated'}">${s.status}</span></td>
        <td>
          <div class="row-actions">
            <button class="row-btn danger" title="Revoke" onclick="revokeSession('${s.id}')">✕ Revoke</button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

function revokeSession(id) {
  document.getElementById('deleteWarnText').textContent =
    `Revoke session ${id}? The user will be disconnected immediately.`;
  document.getElementById('deleteConfirmBtn').textContent = 'Revoke';
  document.getElementById('deleteConfirmBtn').onclick = async () => {
    try {
      await apiCall(`/api/sessions/${id}`, { method: 'DELETE' });
      showToast(`Session ${id} revoked`, 'warn');
      closeModal('deleteModal');
      await fetchSessions();
    } catch (e) {
      showToast('Revoke failed: ' + e.message, 'error');
    }
  };
  openModal('deleteModal');
}

async function cleanupSessions() {
  try {
    const data = await apiCall('/api/sessions', { method: 'DELETE' });
    const removed = data.data?.removed ?? 0;
    showToast(`${removed} expired session(s) cleaned up`, removed ? 'success' : 'info');
    await fetchSessions();
  } catch (e) {
    showToast('Cleanup failed: ' + e.message, 'error');
  }
}

async function refreshSessions() {
  await fetchSessions();
  showToast('Sessions refreshed', 'success');
}

// ════════════════════════════════════════════════════════════
//  LOG VIEWER
// ════════════════════════════════════════════════════════════

let logAutoScroll = true;
let logLevelFilter = 'ALL';

function setLogFilter(level, btn) {
  logLevelFilter = level;
  document.querySelectorAll('.log-filter-btn').forEach(b => b.classList.remove('active'));
  if (btn) btn.classList.add('active');
  filterLogs();
}

// ── ดึง logs จาก API ───────────────────────────────────────
async function fetchLogs() {
  const token = localStorage.getItem('ba_token') || sessionStorage.getItem('ba_token');
  if (!token) return;
  try {
    const data = await apiCall('/api/logs');
    const terminal = document.getElementById('logTerminal');
    if (!terminal) return;
    terminal.innerHTML = '';
    (data.data || []).forEach(entry => {
      appendLogLine(terminal, entry.timestamp, entry.level, entry.message);
    });
    if (logAutoScroll) terminal.scrollTop = terminal.scrollHeight;
  } catch (e) {
    showToast('Failed to load logs: ' + e.message, 'error');
  }
}

function appendLogLine(terminal, timestamp, level, message) {
  const ts = (timestamp || new Date().toISOString()).slice(0, 19).replace('T', ' ');
  const line = document.createElement('div');
  line.className = 'log-line';
  line.innerHTML = `
    <span class="log-ts">${ts}</span>
    <span class="log-lvl ${level.toLowerCase()}">${level}</span>
    <span class="log-msg">${message}</span>
  `;
  terminal.appendChild(line);
  // จำกัดสูงสุด 200 บรรทัด
  const lines = terminal.querySelectorAll('.log-line');
  if (lines.length > 200) lines[0].remove();
}

function filterLogs() {
  const terminal = document.getElementById('logTerminal');
  if (!terminal) return;
  const search = (document.getElementById('logSearch')?.value || '').toLowerCase();

  terminal.querySelectorAll('.log-line').forEach(line => {
    const lvlEl  = line.querySelector('.log-lvl');
    const msgEl  = line.querySelector('.log-msg');
    const lvl    = lvlEl ? lvlEl.textContent.trim() : '';
    const msg    = msgEl ? msgEl.textContent.toLowerCase() : '';

    const levelOk  = logLevelFilter === 'ALL' || lvl === logLevelFilter;
    const searchOk = !search || msg.includes(search) || lvl.toLowerCase().includes(search);

    line.style.display = levelOk && searchOk ? '' : 'none';
  });

  if (logAutoScroll) {
    terminal.scrollTop = terminal.scrollHeight;
  }
}

function clearLogs() {
  const terminal = document.getElementById('logTerminal');
  if (terminal) {
    terminal.innerHTML = `<div class="log-line">
      <span class="log-ts">${new Date().toISOString().slice(0,19).replace('T',' ')}</span>
      <span class="log-lvl info">INFO</span>
      <span class="log-msg">Log terminal cleared by admin</span>
    </div>`;
  }
  showToast('Logs cleared', 'info');
}

function toggleAutoScroll() {
  logAutoScroll = !logAutoScroll;
  const btn = document.getElementById('autoScrollBtn');
  if (btn) {
    btn.textContent = logAutoScroll ? '↓ Auto-scroll' : '⏸ Auto-scroll';
    btn.classList.toggle('btn-accent', logAutoScroll);
  }
  showToast(`Auto-scroll ${logAutoScroll ? 'enabled' : 'paused'}`, 'info');
}

// ── Polling logs ทุก 10 วิ (แทน mock array เดิม) ──────────
setInterval(async () => {
  const token = localStorage.getItem('ba_token') || sessionStorage.getItem('ba_token');
  if (!token) return;
  const terminal = document.getElementById('logTerminal');
  if (!terminal) return;
  try {
    const data = await apiCall('/api/logs');
    const entries = data.data || [];
    // เพิ่มเฉพาะ entry ล่าสุด (entry สุดท้าย) เป็น live indicator
    if (entries.length > 0) {
      const last = entries[entries.length - 1];
      appendLogLine(terminal, new Date().toISOString(), last.level, last.message);
      if (logAutoScroll) terminal.scrollTop = terminal.scrollHeight;
      filterLogs();
    }
  } catch (_) {
    // เงียบถ้า poll ไม่ได้ — ไม่ขึ้น toast spam
  }
}, 10000);

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

function saveSettings() {
  showToast('Settings saved successfully', 'success');
}

function toggleApiKey() {
  const input = document.getElementById('apiKeyInput');
  if (!input) return;
  input.type = input.type === 'password' ? 'text' : 'password';
}

function rotateApiKey() {
  const input = document.getElementById('apiKeyInput');
  if (!input) return;
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let key = 'sk-admin-';
  for (let i = 0; i < 24; i++) key += chars[Math.floor(Math.random() * chars.length)];
  input.value = key;
  input.type = 'text';
  showToast('API key rotated — remember to update your clients', 'warn');
}

// ════════════════════════════════════════════════════════════
//  GLOBAL SEARCH
// ════════════════════════════════════════════════════════════

(function setKbdHint() {
  const kbd = document.querySelector('.search-kbd');
  if (kbd) {
    const isMac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
    kbd.textContent = isMac ? '⌘K' : 'Ctrl+K';
  }
})();

const globalSearch = document.getElementById('globalSearch');
if (globalSearch) {
  globalSearch.addEventListener('input', () => {
    const val = globalSearch.value.trim().toLowerCase();
    if (!val) return;
    const mappingPage = document.getElementById('page-mapping');
    if (mappingPage?.classList.contains('hidden')) navigate('mapping');
    const mappingSearch = document.getElementById('mappingSearch');
    if (mappingSearch) {
      mappingSearch.value = val;
      filterMappings();
    }
  });
  document.addEventListener('keydown', e => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
      e.preventDefault();
      globalSearch.focus();
      globalSearch.select();
    }
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
}