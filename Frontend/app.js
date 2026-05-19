/* ============================================================
   BA Tool — Admin Console  |  app.js
   Compatible with index.html + styles.css (responsive)
   ============================================================ */

'use strict';

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

// สร้าง overlay backdrop สำหรับมือถือ (ถ้ายังไม่มีใน HTML)
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
  document.body.style.overflow = 'hidden'; // ป้องกัน scroll ด้านหลัง
}

function closeMobileSidebar() {
  sidebar.classList.remove('mobile-open');
  sidebarOverlay.classList.remove('active');
  document.body.style.overflow = '';
}

// Overlay คลิกปิด sidebar
sidebarOverlay.addEventListener('click', closeMobileSidebar);

// Toggle sidebar — แยก desktop (collapsed) กับ mobile (drawer)
const sidebarToggle = document.getElementById('sidebarToggle');
if (sidebarToggle) {
  sidebarToggle.addEventListener('click', () => {
    if (isMobile()) {
      sidebar.classList.contains('mobile-open') ? closeMobileSidebar() : openMobileSidebar();
    } else {
      // desktop: collapsed ↔ expanded
      const collapsed = sidebar.classList.toggle('collapsed');
      mainWrap.classList.toggle('expanded', collapsed);
    }
  });
}

// ปิด sidebar มือถือเมื่อ resize ขึ้นไป desktop
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
  // ซ่อนทุกหน้า
  document.querySelectorAll('.page').forEach(p => p.classList.add('hidden'));

  // แสดงหน้าที่เลือก
  const target = document.getElementById('page-' + page);
  if (target) target.classList.remove('hidden');

  // อัป active nav
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const activeNav = document.querySelector(`.nav-item[data-page="${page}"]`);
  if (activeNav) activeNav.classList.add('active');

  // อัป breadcrumb
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

  // ปิด sidebar มือถือหลัง navigate
  if (isMobile()) closeMobileSidebar();
}

// ผูก nav items
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

// Settings theme toggle sync
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
// ปิดเมื่อคลิกนอก dropdown
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

  // Auto remove
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

// คลิก overlay ปิด modal
document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => {
    if (e.target === overlay) overlay.classList.add('hidden');
  });
});

// กด ESC ปิด modal ที่เปิดอยู่
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal-overlay:not(.hidden)').forEach(m => m.classList.add('hidden'));
    closeAvatarMenu();
  }
});

// ════════════════════════════════════════════════════════════
//  DASHBOARD
// ════════════════════════════════════════════════════════════

function refreshDashboard() {
  showToast('Dashboard refreshed', 'success');
}

// ════════════════════════════════════════════════════════════
//  MAPPING MANAGER
// ════════════════════════════════════════════════════════════

// --- ข้อมูล sample ---
const mappingData = [
  { id:1,  srcDb:'sqlserver',  rawType:'int',            logicalType:'integer',  masterType:'INTEGER', destDb:'confluent',   finalType:'int',            confidence:98, status:'active',     updated:'2025-03-14' },
  { id:2,  srcDb:'sqlserver',  rawType:'varchar',         logicalType:'string',   masterType:'STRING',  destDb:'confluent',   finalType:'string',         confidence:95, status:'active',     updated:'2025-03-14' },
  { id:3,  srcDb:'sqlserver',  rawType:'datetime',        logicalType:'datetime', masterType:'TIMESTAMP',destDb:'confluent',  finalType:'long',           confidence:91, status:'active',     updated:'2025-03-13' },
  { id:4,  srcDb:'postgresql', rawType:'uuid',            logicalType:'uuid',     masterType:'UUID',    destDb:'confluent',   finalType:'string',         confidence:88, status:'active',     updated:'2025-03-12' },
  { id:5,  srcDb:'postgresql', rawType:'jsonb',           logicalType:'json',     masterType:'JSON',    destDb:'confluent',   finalType:'string',         confidence:72, status:'draft',      updated:'2025-03-11' },
  { id:6,  srcDb:'mysql',      rawType:'tinyint(1)',      logicalType:'boolean',  masterType:'BOOLEAN', destDb:'confluent',   finalType:'boolean',        confidence:96, status:'active',     updated:'2025-03-10' },
  { id:7,  srcDb:'mysql',      rawType:'decimal(10,2)',   logicalType:'decimal',  masterType:'DECIMAL', destDb:'postgresql',  finalType:'numeric(10,2)',  confidence:93, status:'active',     updated:'2025-03-09' },
  { id:8,  srcDb:'oracle',     rawType:'NUMBER',          logicalType:'number',   masterType:'DOUBLE',  destDb:'confluent',   finalType:'double',         confidence:84, status:'deprecated', updated:'2025-03-08' },
  { id:9,  srcDb:'oracle',     rawType:'VARCHAR2',        logicalType:'string',   masterType:'STRING',  destDb:'postgresql',  finalType:'varchar',        confidence:90, status:'active',     updated:'2025-03-07' },
  { id:10, srcDb:'sqlserver',  rawType:'uniqueidentifier',logicalType:'uuid',     masterType:'UUID',    destDb:'mysql',       finalType:'char(36)',       confidence:87, status:'beta',       updated:'2025-03-06' },
  { id:11, srcDb:'postgresql', rawType:'timestamp',       logicalType:'datetime', masterType:'TIMESTAMP',destDb:'mysql',      finalType:'datetime',       confidence:94, status:'active',     updated:'2025-03-05' },
  { id:12, srcDb:'mysql',      rawType:'text',            logicalType:'string',   masterType:'STRING',  destDb:'confluent',   finalType:'string',         confidence:99, status:'active',     updated:'2025-03-04' },
];

let mappingCurrentPage = 1;
const MAPPING_PAGE_SIZE = 8;
let selectedMappings = new Set();

function getFilteredMappings() {
  const search = (document.getElementById('mappingSearch')?.value || '').toLowerCase();
  const srcDb  = document.getElementById('filterSrcDb')?.value  || '';
  const destDb = document.getElementById('filterDestDb')?.value || '';
  const status = document.getElementById('filterStatus')?.value || '';

  return mappingData.filter(m =>
    (!search || [m.srcDb, m.rawType, m.logicalType, m.masterType, m.finalType].some(v => v.toLowerCase().includes(search))) &&
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
    tbody.innerHTML = `<tr><td colspan="11" style="text-align:center;padding:32px;color:var(--text3)">No mapping rules found</td></tr>`;
  } else {
    tbody.innerHTML = page.map(m => `
      <tr>
        <td class="th-check">
          <input type="checkbox" ${selectedMappings.has(m.id) ? 'checked' : ''}
            onchange="toggleSelect(${m.id}, this.checked)" />
        </td>
        <td class="td-name">${m.srcDb}</td>
        <td>${m.rawType}</td>
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

  // count
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
  document.getElementById('mSrcDb').value      = m.srcDb;
  document.getElementById('mDestDb').value     = m.destDb;
  document.getElementById('mRawType').value    = m.rawType;
  document.getElementById('mLogicalType').value= m.logicalType;
  document.getElementById('mMasterType').value = m.masterType;
  document.getElementById('mFinalType').value  = m.finalType;
  document.getElementById('mStatus').value     = m.status;
  document.getElementById('mappingModalTitle').textContent = 'Edit Mapping Rule';
  openModal('mappingModal');
}

function deleteMapping(id) {
  const idx = mappingData.findIndex(r => r.id === id);
  if (idx === -1) return;
  document.getElementById('deleteWarnText').textContent =
    `Delete mapping "${mappingData[idx].rawType} → ${mappingData[idx].finalType}"? This cannot be undone.`;
  document.getElementById('deleteConfirmBtn').onclick = () => {
    mappingData.splice(idx, 1);
    selectedMappings.delete(id);
    renderMappingTable();
    showToast('Mapping rule deleted', 'info');
    closeModal('deleteModal');
  };
  openModal('deleteModal');
}

function bulkDelete() {
  if (!selectedMappings.size) return;
  document.getElementById('deleteWarnText').textContent =
    `Delete ${selectedMappings.size} selected mapping(s)? This cannot be undone.`;
  document.getElementById('deleteConfirmBtn').onclick = () => {
    selectedMappings.forEach(id => {
      const idx = mappingData.findIndex(r => r.id === id);
      if (idx !== -1) mappingData.splice(idx, 1);
    });
    selectedMappings.clear();
    renderMappingTable();
    showToast('Selected mappings deleted', 'info');
    closeModal('deleteModal');
  };
  openModal('deleteModal');
}

function bulkApprove() {
  selectedMappings.forEach(id => {
    const m = mappingData.find(r => r.id === id);
    if (m) m.status = 'active';
  });
  showToast(`${selectedMappings.size} mapping(s) set to active`, 'success');
  selectedMappings.clear();
  renderMappingTable();
}

function openAddMapping() {
  document.getElementById('mappingModalTitle').textContent = 'Add Mapping Rule';
  ['mSrcDb','mDestDb','mRawType','mLogicalType','mMasterType','mFinalType'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  openModal('mappingModal');
}

function saveMapping() {
  const raw = document.getElementById('mRawType')?.value.trim();
  if (!raw) { showToast('Raw Type is required', 'error'); return; }
  const newId = mappingData.length ? Math.max(...mappingData.map(m => m.id)) + 1 : 1;
  mappingData.unshift({
    id: newId,
    srcDb:       document.getElementById('mSrcDb')?.value || 'sqlserver',
    rawType:     raw,
    logicalType: document.getElementById('mLogicalType')?.value.trim() || '',
    masterType:  document.getElementById('mMasterType')?.value.trim() || '',
    destDb:      document.getElementById('mDestDb')?.value || 'confluent',
    finalType:   document.getElementById('mFinalType')?.value.trim() || '',
    confidence:  80,
    status:      document.getElementById('mStatus')?.value || 'draft',
    updated:     new Date().toISOString().slice(0, 10),
  });
  showToast('Mapping rule saved', 'success');
  closeModal('mappingModal');
  renderMappingTable();
}

function openBulkImport() {
  showToast('Bulk import — feature coming soon', 'info');
}

// ── AI Generate ────────────────────────────────────────────
const aiSuggestions = [
  { src:'bigint',    raw:'bigint',      logical:'integer',  final:'long',    confidence:97 },
  { src:'nvarchar',  raw:'nvarchar',    logical:'string',   final:'string',  confidence:95 },
  { src:'bit',       raw:'bit',         logical:'boolean',  final:'boolean', confidence:99 },
  { src:'float',     raw:'float',       logical:'decimal',  final:'double',  confidence:91 },
  { src:'date',      raw:'date',        logical:'date',     final:'int',     confidence:88 },
  { src:'time',      raw:'time',        logical:'time',     final:'long',    confidence:84 },
  { src:'xml',       raw:'xml',         logical:'string',   final:'string',  confidence:70 },
  { src:'geography', raw:'geography',   logical:'bytes',    final:'bytes',   confidence:62 },
];
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

  setTimeout(() => {
    // reset decisions
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

function saveApproved() {
  const approved = aiSuggestions.filter((_, i) => aiDecisions[i] === 'approved');
  if (!approved.length) { showToast('No approved mappings to save', 'warn'); return; }
  const newId = mappingData.length ? Math.max(...mappingData.map(m => m.id)) : 0;
  approved.forEach((s, idx) => {
    mappingData.unshift({
      id: newId + idx + 1,
      srcDb:       document.getElementById('aiSrcDb')?.value || 'sqlserver',
      rawType:     s.raw,
      logicalType: s.logical,
      masterType:  s.logical.toUpperCase(),
      destDb:      document.getElementById('aiDestDb')?.value || 'confluent',
      finalType:   s.final,
      confidence:  s.confidence,
      status:      'active',
      updated:     new Date().toISOString().slice(0, 10),
    });
  });
  showToast(`${approved.length} mapping(s) saved successfully`, 'success');
  closeModal('aiModal');
  renderMappingTable();
}

// ════════════════════════════════════════════════════════════
//  DATABASE REGISTRY
// ════════════════════════════════════════════════════════════

const dbData = [
  { id:1, name:'SQL Server',    key:'sqlserver',   icon:'🗄', rules:482, sessions:3,  enabled:true },
  { id:2, name:'PostgreSQL',    key:'postgresql',  icon:'🐘', rules:391, sessions:1,  enabled:true },
  { id:3, name:'MySQL',         key:'mysql',       icon:'🐬', rules:218, sessions:2,  enabled:true },
  { id:4, name:'Oracle',        key:'oracle',      icon:'🔴', rules:167, sessions:0,  enabled:false },
  { id:5, name:'Confluent AVRO',key:'confluent',   icon:'⚡', rules:0,   sessions:6,  enabled:true },
  { id:6, name:'Snowflake',     key:'snowflake',   icon:'❄', rules:43,  sessions:0,  enabled:false },
  { id:7, name:'DB2',           key:'db2',         icon:'💠', rules:28,  sessions:0,  enabled:false },
  { id:8, name:'BigQuery',      key:'bigquery',    icon:'☁', rules:12,  sessions:0,  enabled:false },
];

function renderDatabases() {
  const grid = document.getElementById('dbGrid');
  if (!grid) return;
  grid.innerHTML = dbData.map(db => `
    <div class="db-card">
      <div class="db-card-header">
        <div class="db-card-info">
          <div class="db-logo">${db.icon}</div>
          <div>
            <div class="db-card-name">${db.name}</div>
            <div class="db-card-key">${db.key}</div>
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
    </div>
  `).join('');
}

function toggleDatabase(id, enabled) {
  const db = dbData.find(d => d.id === id);
  if (db) {
    db.enabled = enabled;
    showToast(`${db.name} ${enabled ? 'enabled' : 'disabled'}`, enabled ? 'success' : 'warn');
  }
}

function editDatabase(id) {
  const db = dbData.find(d => d.id === id);
  if (!db) return;
  document.getElementById('dbName').value    = db.key;
  document.getElementById('dbLabel').value   = db.name;
  document.getElementById('dbVersion').value = '';
  document.getElementById('dbStatus').value  = db.enabled ? 'active' : 'beta';
  document.getElementById('dbModalTitle').textContent = 'Edit Database';
  openModal('dbModal');
}

function confirmDeleteDatabase(id) {
  const db = dbData.find(d => d.id === id);
  if (!db) return;
  document.getElementById('deleteWarnText').textContent =
    `Delete "${db.name}" from the registry? All associated mapping rules (${db.rules}) will also be removed.`;
  document.getElementById('deleteConfirmBtn').onclick = () => {
    const idx = dbData.findIndex(d => d.id === id);
    if (idx !== -1) dbData.splice(idx, 1);
    renderDatabases();
    showToast(`${db.name} removed`, 'warn');
    closeModal('deleteModal');
  };
  openModal('deleteModal');
}

function openAddDatabase() {
  ['dbName','dbLabel','dbVersion'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  document.getElementById('dbModalTitle').textContent = 'Add Database';
  openModal('dbModal');
}

function saveDatabase() {
  const name  = document.getElementById('dbLabel')?.value.trim();
  const key   = document.getElementById('dbName')?.value.trim();
  if (!name || !key) { showToast('Name and Key are required', 'error'); return; }
  const newId = dbData.length ? Math.max(...dbData.map(d => d.id)) + 1 : 1;
  dbData.push({ id: newId, name, key, icon: '🗄', rules: 0, sessions: 0, enabled: true });
  renderDatabases();
  showToast(`Database "${name}" added`, 'success');
  closeModal('dbModal');
}

// ════════════════════════════════════════════════════════════
//  SESSION MONITOR
// ════════════════════════════════════════════════════════════

const sessionData = [
  { id:'a3f9c2d1', user:'superadmin@ba.local',  role:'Admin',     db:'sqlserver→confluent', tables:120, created:'2026-05-18 11:50', ttl:45,  status:'active' },
  { id:'b1e7f3a2', user:'dev01@ba.local',        role:'Developer', db:'postgresql→confluent',tables:34,  created:'2026-05-18 12:10', ttl:22,  status:'active' },
  { id:'c5d2g8h4', user:'dev02@ba.local',        role:'Developer', db:'mysql→confluent',     tables:88,  created:'2026-05-18 10:30', ttl:3,   status:'warning' },
  { id:'d0f1h2k9', user:'viewer01@ba.local',     role:'Viewer',    db:'sqlserver→postgresql',tables:12,  created:'2026-05-18 09:00', ttl:0,   status:'expired' },
];

function renderSessions() {
  const tbody = document.getElementById('sessionBody');
  if (!tbody) return;

  // Update stat counters
  const active   = sessionData.filter(s => s.status === 'active').length;
  const expiring = sessionData.filter(s => s.status === 'warning').length;
  const expired  = sessionData.filter(s => s.status === 'expired').length;
  const elActive   = document.getElementById('sessActive');
  const elExpiring = document.getElementById('sessExpiring');
  const elExpired  = document.getElementById('sessExpired');
  if (elActive)   elActive.textContent   = active;
  if (elExpiring) elExpiring.textContent = expiring;
  if (elExpired)  elExpired.textContent  = expired;

  // อัป live badge ใน sidebar
  const liveBadge = document.querySelector('.nav-item[data-page="sessions"] .nav-badge.live');
  if (liveBadge) liveBadge.textContent = active + expiring;

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
  document.getElementById('deleteConfirmBtn').onclick = () => {
    const idx = sessionData.findIndex(s => s.id === id);
    if (idx !== -1) sessionData.splice(idx, 1);
    renderSessions();
    showToast(`Session ${id} revoked`, 'warn');
    closeModal('deleteModal');
  };
  openModal('deleteModal');
}

function cleanupSessions() {
  const before = sessionData.length;
  for (let i = sessionData.length - 1; i >= 0; i--) {
    if (sessionData[i].status === 'expired') sessionData.splice(i, 1);
  }
  const removed = before - sessionData.length;
  renderSessions();
  showToast(`${removed} expired session(s) cleaned up`, removed ? 'success' : 'info');
}

function refreshSessions() {
  renderSessions();
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

// Simulate live log entries
const liveLogs = [
  { lvl:'INFO',  msg:'GET /api/v2/schemas — 200 OK (28ms)' },
  { lvl:'INFO',  msg:'POST /api/v2/sessions/export — 200 OK (412ms)' },
  { lvl:'WARN',  msg:'Cache utilization at 71% — consider cleanup' },
  { lvl:'INFO',  msg:'Schema sync triggered by superadmin' },
  { lvl:'ERROR', msg:'Connection timeout: db2→confluent pair not found' },
  { lvl:'INFO',  msg:'Cleanup task: removed 1 expired session' },
  { lvl:'DEBUG', msg:'Mapping lookup: sqlserver.varchar → confluent.string (cache hit)' },
  { lvl:'INFO',  msg:'Health check passed — all monitored services nominal' },
];

let liveLogIdx = 0;
setInterval(() => {
  const terminal = document.getElementById('logTerminal');
  if (!terminal) return;
  const entry = liveLogs[liveLogIdx % liveLogs.length];
  liveLogIdx++;
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const line = document.createElement('div');
  line.className = 'log-line';
  line.innerHTML = `
    <span class="log-ts">${now}</span>
    <span class="log-lvl ${entry.lvl.toLowerCase()}">${entry.lvl}</span>
    <span class="log-msg">${entry.msg}</span>
  `;
  terminal.appendChild(line);

  // trim เกิน 200 บรรทัด
  const lines = terminal.querySelectorAll('.log-line');
  if (lines.length > 200) lines[0].remove();

  if (logAutoScroll) terminal.scrollTop = terminal.scrollHeight;

  // re-apply filter
  filterLogs();
}, 5000);

// ════════════════════════════════════════════════════════════
//  SETTINGS
// ════════════════════════════════════════════════════════════

function switchSettings(section, btn) {
  // toggle nav active
  document.querySelectorAll('.settings-nav-item').forEach(b => b.classList.remove('active'));
  if (btn) btn.classList.add('active');

  // toggle section visibility
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

// แสดง Ctrl+K หรือ ⌘K ตาม OS
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
    // navigate ไปหน้า mapping ก่อนถ้าไม่ได้อยู่หน้านั้น
    const mappingPage = document.getElementById('page-mapping');
    if (mappingPage?.classList.contains('hidden')) navigate('mapping');
    const mappingSearch = document.getElementById('mappingSearch');
    if (mappingSearch) {
      mappingSearch.value = val;
      filterMappings();
    }
  });
  // Keyboard shortcut ⌘K / Ctrl+K
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
  // Render ล่วงหน้าให้พร้อม
  renderMappingTable();
  renderDatabases();
  renderSessions();
}