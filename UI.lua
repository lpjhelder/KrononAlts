-- KrononAlts — UI: janela movável com a tabela cross-character.
-- Lê KrononAlts.GetChars(); pool de linhas sem ghost; tooltips de 2 camadas;
-- countdown de reset no topo; selo "precisa logar"; refresh ao vivo via EventBus.

local KA = KrononAlts
local L = KA.L

-- ---------------------------------------------------------------------------
-- Cores semânticas (sempre acompanhadas de número/glifo, nunca só cor)
-- ---------------------------------------------------------------------------
local COLOR_DONE    = { 0.40, 0.85, 0.40 }
local COLOR_PARTIAL = { 1.00, 0.82, 0.00 }
local COLOR_MISSING = { 0.55, 0.55, 0.55 }
local COLOR_HEADER  = { 0.82, 0.78, 0.60 }
local ACCENT        = { 1.00, 0.82, 0.00 }

local function hex(col)
  return string.format("%02x%02x%02x",
    math.floor((col[1] or 1) * 255 + 0.5),
    math.floor((col[2] or 1) * 255 + 0.5),
    math.floor((col[3] or 1) * 255 + 0.5))
end

local function colored(col, text)
  return "|cff" .. hex(col) .. tostring(text) .. "|r"
end

-- ---------------------------------------------------------------------------
-- Layout da tabela
-- ---------------------------------------------------------------------------
local ROW_H    = 22
local FRAME_W  = 594
local ROWS_TOP = 80 -- distância (positiva) do topo até a 1ª linha de dados

local COLS = {
  { key = "name",   x = 12,  w = 156, justify = "LEFT"   },
  { key = "vault",  x = 170, w = 80,  justify = "CENTER" },
  { key = "mplus",  x = 252, w = 40,  justify = "CENTER" },
  { key = "key",    x = 296, w = 104, justify = "LEFT"   },
  { key = "rating", x = 402, w = 56,  justify = "CENTER" },
  { key = "raid",   x = 462, w = 120, justify = "LEFT"   },
}

local HEADER_LABEL = {
  name   = L.COL_CHAR,
  vault  = L.COL_VAULT,
  mplus  = L.COL_MPLUS,
  key    = L.COL_KEY,
  rating = L.COL_RATING,
  raid   = L.COL_RAID,
}

local DIFF_ABBR = {
  [17] = L.DIFF_LFR, -- Raid Finder
  [14] = L.DIFF_N,   -- Normal
  [15] = L.DIFF_H,   -- Heroic
  [16] = L.DIFF_M,   -- Mythic
}
local function DiffAbbr(id, name)
  return DIFF_ABBR[id or 0] or (name and name:sub(1, 3)) or "?"
end

-- ---------------------------------------------------------------------------
-- Formatação de tempo
-- ---------------------------------------------------------------------------
local function FormatCountdown(seconds)
  seconds = math.max(0, math.floor(seconds or 0))
  local d = math.floor(seconds / 86400)
  local h = math.floor((seconds % 86400) / 3600)
  local m = math.floor((seconds % 3600) / 60)
  if d > 0 then return string.format("%d%s %d%s", d, L.ABBR_D, h, L.ABBR_H) end
  if h > 0 then return string.format("%d%s %d%s", h, L.ABBR_H, m, L.ABBR_M) end
  return string.format("%d%s", m, L.ABBR_M)
end

local function FormatAgo(seconds)
  seconds = math.max(0, math.floor(seconds or 0))
  if seconds < 60 then return seconds .. "s" end
  local m = math.floor(seconds / 60)
  if m < 60 then return m .. L.ABBR_M end
  local h = math.floor(m / 60)
  if h < 24 then return h .. L.ABBR_H .. " " .. (m % 60) .. L.ABBR_M end
  local d = math.floor(h / 24)
  return d .. L.ABBR_D .. " " .. (h % 24) .. L.ABBR_H
end

-- ---------------------------------------------------------------------------
-- Confirmação de remoção de personagem
-- ---------------------------------------------------------------------------
StaticPopupDialogs["KRONONALTS_REMOVE"] = {
  text = L.REMOVE_CONFIRM,
  button1 = YES,
  button2 = NO,
  OnAccept = function(_, key) if key then KA.RemoveChar(key) end end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  showAlert = true,
  preferredIndex = 3,
}

-- ---------------------------------------------------------------------------
-- Estado da UI
-- ---------------------------------------------------------------------------
local frame
local rows = {}

-- ---------------------------------------------------------------------------
-- Criação de uma linha (pool)
-- ---------------------------------------------------------------------------
local function CreateRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(FRAME_W, ROW_H)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()

  row.cells = {}
  for _, col in ipairs(COLS) do
    local cell = CreateFrame("Frame", nil, row)
    cell:SetPoint("TOPLEFT", row, "TOPLEFT", col.x, 0)
    cell:SetSize(col.w, ROW_H)
    cell:EnableMouse(true)

    local fs = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetAllPoints()
    fs:SetJustifyH(col.justify)
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(false)
    cell.text = fs

    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.cells[col.key] = cell
  end

  return row
end

-- ---------------------------------------------------------------------------
-- Preenchimento de uma linha com os dados de um personagem
-- ---------------------------------------------------------------------------
local function PopulateRow(row, entry, index)
  local d = entry.data
  local stale = (not entry.isCurrent) and KA.IsStale(d)

  -- fundo alternado + leve esmaecida se snapshot velho
  if index % 2 == 0 then
    row.bg:SetColorTexture(1, 1, 1, 0.03)
  else
    row.bg:SetColorTexture(0, 0, 0, 0)
  end
  row:SetAlpha(stale and 0.6 or 1)

  -- classe / cor
  local cc = RAID_CLASS_COLORS[d.class or ""]
  local cr, cg, cb = 1, 1, 1
  if cc then cr, cg, cb = cc.r, cc.g, cc.b end

  -- ===== NOME =====
  local nameCell = row.cells.name
  local nm = d.name or "?"
  local sealPrefix = stale and "|cffff4040(!)|r " or ""
  local ilvlStr = d.ilvl and ("  |cff8888ff" .. d.ilvl .. "|r") or ""
  nameCell.text:SetTextColor(cr, cg, cb)
  nameCell.text:SetText(sealPrefix .. nm .. ilvlStr)
  nameCell:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(nm, cr, cg, cb)
    if d.realm then GameTooltip:AddLine(d.realm, 0.7, 0.7, 0.7) end
    GameTooltip:AddLine(string.format(L.TT_LEVEL_ILVL, d.level or 0, d.ilvl or 0), 0.85, 0.85, 0.85)
    if d.updatedAt then
      GameTooltip:AddLine(string.format(L.TT_UPDATED, FormatAgo(time() - d.updatedAt)), 0.6, 0.8, 1)
    end
    if stale then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L.STALE, 1, 0.4, 0.4, true)
    end
    if not entry.isCurrent then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L.TT_REMOVE_HINT, 0.5, 0.5, 0.5)
    end
    GameTooltip:Show()
  end)
  nameCell:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" and not entry.isCurrent then
      StaticPopup_Show("KRONONALTS_REMOVE", nm, nil, entry.key)
    end
  end)

  -- ===== COFRE (3 trilhas: M+ · Raide · Mundo) =====
  local v = d.vault
  local function filled(t) return (t and t.filled) or 0 end
  local function digit(n)
    local col = (n >= 3) and COLOR_DONE or (n >= 1 and COLOR_PARTIAL or COLOR_MISSING)
    return colored(col, n)
  end
  local m = filled(v and v.mplus)
  local r = filled(v and v.raid)
  local w = filled(v and v.world)
  local vaultText = digit(m) .. "|cff555555·|r" .. digit(r) .. "|cff555555·|r" .. digit(w)
  if v and v.hasRewards then vaultText = vaultText .. " |cffffd000!|r" end
  local vaultCell = row.cells.vault
  vaultCell.text:SetText(vaultText)
  vaultCell:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.TT_VAULT_TITLE, ACCENT[1], ACCENT[2], ACCENT[3])
    local function trackLines(label, t)
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine(label, ((t and t.filled) or 0) .. "/" .. ((t and t.total) or 3),
        1, 0.82, 0, 1, 1, 1)
      if t and t.slots then
        for _, s in ipairs(t.slots) do
          local mark, desc
          if s.unlocked then
            mark = "|cff66ff66" .. "+" .. "|r"
            desc = s.ilvl and string.format(L.TT_SLOT_ILVL, s.ilvl) or L.TT_SLOT_READY
          else
            mark = "|cff888888-|r"
            desc = string.format("%d/%d", s.progress or 0, s.threshold or 0)
          end
          GameTooltip:AddDoubleLine("   " .. mark, desc, 1, 1, 1, 0.8, 0.8, 0.8)
        end
      end
    end
    trackLines(L.TRACK_MPLUS, v and v.mplus)
    trackLines(L.TRACK_RAID,  v and v.raid)
    trackLines(L.TRACK_WORLD, v and v.world)
    if v and v.hasRewards then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L.VAULT_HAS_REWARDS, 1, 0.82, 0)
    end
    GameTooltip:Show()
  end)

  -- ===== M+ (runs da semana) =====
  local mp = d.mplus or {}
  local runs = mp.runs or 0
  local runsCol = (runs >= 8) and COLOR_DONE or (runs >= 1 and COLOR_PARTIAL or COLOR_MISSING)
  local mplusCell = row.cells.mplus
  mplusCell.text:SetText(colored(runsCol, runs))
  mplusCell:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.TT_MPLUS_TITLE, ACCENT[1], ACCENT[2], ACCENT[3])
    GameTooltip:AddLine(string.format(L.TT_RUNS, runs), 1, 1, 1)
    if (mp.best or 0) > 0 then
      GameTooltip:AddLine(string.format(L.TT_BEST, mp.best), 0.85, 0.85, 0.85)
    end
    GameTooltip:Show()
  end)

  -- ===== CHAVE (keystone) =====
  local keyCell = row.cells.key
  if mp.keystoneLevel then
    keyCell.text:SetText(colored(COLOR_PARTIAL, "+" .. mp.keystoneLevel) .. " |cffffffff" .. (mp.keystoneMap or "") .. "|r")
  else
    keyCell.text:SetText(colored(COLOR_MISSING, L.NONE))
  end
  keyCell:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.COL_KEY, ACCENT[1], ACCENT[2], ACCENT[3])
    if mp.keystoneLevel then
      GameTooltip:AddLine(string.format("+%d  %s", mp.keystoneLevel, mp.keystoneMap or "?"), 1, 1, 1)
    else
      GameTooltip:AddLine(L.TT_NO_KEY, 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
  end)

  -- ===== RATING =====
  local rating = mp.rating or 0
  local ratingCell = row.cells.rating
  if rating > 0 then
    ratingCell.text:SetText("|cffffffff" .. rating .. "|r")
  else
    ratingCell.text:SetText(colored(COLOR_MISSING, L.NONE))
  end
  ratingCell:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(string.format(L.TT_RATING, rating), ACCENT[1], ACCENT[2], ACCENT[3])
    GameTooltip:Show()
  end)

  -- ===== RAIDE (lockout mais relevante) =====
  local raids = d.raids or {}
  local top = raids[1] -- já vem ordenado por dificuldade desc no Core
  local raidCell = row.cells.raid
  if top then
    local total = top.total or 0
    local prog = top.progress or 0
    local done = total > 0 and prog >= total
    local col = done and COLOR_DONE or (prog > 0 and COLOR_PARTIAL or COLOR_MISSING)
    local mark = done and "+ " or ""
    raidCell.text:SetText(colored(col, mark .. DiffAbbr(top.difficultyId, top.difficultyName) .. " " .. prog .. "/" .. total))
  else
    raidCell.text:SetText(colored(COLOR_MISSING, L.NONE))
  end
  raidCell:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.TT_RAID_TITLE, ACCENT[1], ACCENT[2], ACCENT[3])
    if #raids == 0 then
      GameTooltip:AddLine(L.TT_NO_RAID, 0.7, 0.7, 0.7)
    else
      for _, lk in ipairs(raids) do
        local total = lk.total or 0
        local prog = lk.progress or 0
        local done = total > 0 and prog >= total
        local dc = done and COLOR_DONE or COLOR_PARTIAL
        local label = (lk.name or "?") .. "  (" .. (lk.difficultyName or "?") .. ")"
        GameTooltip:AddDoubleLine(label, prog .. "/" .. total, 1, 1, 1, dc[1], dc[2], dc[3])
      end
    end
    GameTooltip:Show()
  end)
end

-- ---------------------------------------------------------------------------
-- Refresh: lê GetChars(), reaproveita o pool, redimensiona a janela
-- ---------------------------------------------------------------------------
local function Refresh()
  if not frame then return end
  local chars = KA.GetChars()
  local n = #chars

  for i = 1, n do
    local row = rows[i]
    if not row then
      row = CreateRow(frame)
      rows[i] = row
    end
    PopulateRow(row, chars[i], i)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(ROWS_TOP + (i - 1) * ROW_H))
    row:Show()
  end
  for i = n + 1, #rows do
    rows[i]:Hide()
  end

  if frame.empty then frame.empty:SetShown(n == 0) end

  local bodyRows = (n > 0) and n or 1
  frame:SetHeight(ROWS_TOP + bodyRows * ROW_H + 14)
end

-- ---------------------------------------------------------------------------
-- Construção da janela
-- ---------------------------------------------------------------------------
local function BuildFrame()
  if frame then return end

  frame = CreateFrame("Frame", "KrononAltsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(FRAME_W, 220)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("HIGH")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.06, 0.96)
    frame:SetBackdropBorderColor(0.30, 0.30, 0.35, 1)
  end

  tinsert(UISpecialFrames, "KrononAltsFrame") -- ESC fecha

  -- título
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -10)
  title:SetText(L.TITLE)
  title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

  -- botão fechar
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- countdown de reset
  local cd = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cd:SetPoint("TOPLEFT", 14, -34)
  cd:SetJustifyH("LEFT")
  frame.countdown = cd

  -- divisória
  local div = frame:CreateTexture(nil, "ARTWORK")
  div:SetColorTexture(0.4, 0.4, 0.45, 0.5)
  div:SetHeight(1)
  div:SetPoint("TOPLEFT", 10, -52)
  div:SetPoint("TOPRIGHT", -10, -52)

  -- cabeçalho de colunas
  for _, col in ipairs(COLS) do
    local h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    h:SetPoint("TOPLEFT", frame, "TOPLEFT", col.x, -58)
    h:SetWidth(col.w)
    h:SetJustifyH(col.justify)
    h:SetWordWrap(false)
    h:SetText(HEADER_LABEL[col.key] or col.key)
    h:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
  end

  -- estado vazio
  local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  empty:SetPoint("TOP", 0, -ROWS_TOP - 8)
  empty:SetWidth(FRAME_W - 48)
  empty:SetJustifyH("CENTER")
  empty:SetText(L.EMPTY)
  empty:Hide()
  frame.empty = empty

  -- ticker do countdown (throttle 1s)
  frame.elapsed = 1
  frame:SetScript("OnUpdate", function(self, e)
    self.elapsed = self.elapsed + e
    if self.elapsed < 1 then return end
    self.elapsed = 0
    local info = KA.GetResetInfo()
    self.countdown:SetText(string.format("|cffaaaaaa%s|r %s    |cffaaaaaa%s|r %s",
      L.RESET_WEEKLY, FormatCountdown(info.weeklySeconds),
      L.RESET_DAILY, FormatCountdown(info.dailySeconds)))
  end)

  Refresh()
end

-- ---------------------------------------------------------------------------
-- API pública da UI
-- ---------------------------------------------------------------------------
function KA.Toggle()
  if not frame then BuildFrame() end
  if frame:IsShown() then
    frame:Hide()
  else
    Refresh()
    frame:Show()
  end
end

-- refresh ao vivo quando o snapshot do char logado muda
KA.bus:Register(function()
  if frame and frame:IsShown() then Refresh() end
end)
