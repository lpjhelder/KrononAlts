-- KrononAlts — UI: janela flat movável com a tabela cross-character.
-- Lê KrononAlts.GetChars(); pool de linhas sem ghost; linha-resumo;
-- ScrollFrame para muitos alts; accordion de detalhe (1 aberto por vez);
-- countdown de reset na titlebar; posição salva em KrononAltsDB.pos.

local KA = KrononAlts
local L = KA.L

-- ---------------------------------------------------------------------------
-- Paleta (valores reais do guia AlterEgo) — backdrop FLAT, não bisotado
-- ---------------------------------------------------------------------------
local BG          = { 0.1137, 0.1412, 0.1647 } -- #1D242A
local ACCENT      = { 1.00, 0.82, 0.00 }        -- dourado (recompensa / cap)
local ACCENT_BLUE = { 0.20, 0.60, 1.00 }        -- #3399FF (char logado)
local COLOR_DONE    = { 0.20, 0.82, 0.48 }      -- #33D17A
local COLOR_MISSING = { 0.50, 0.50, 0.50 }      -- #808080
local COLOR_HEADER  = { 0.70, 0.70, 0.74 }
local COLOR_NEUTRAL = { 0.80, 0.80, 0.84 }      -- cinza-claro neutro (números sem destaque)
local COLOR_ACTION  = { 1.00, 0.65, 0.25 }      -- laranja "a fazer" (acionável, NÃO é dourado de recompensa)

-- Paleta da janela de configurações (coerente com a janela do Alts: bg #1D242A,
-- accent azul, dourado). Verde p/ toggle ligado, cinza p/ desligado.
local CFG_BG      = { 0.1137, 0.1412, 0.1647 }  -- #1D242A (mesma da janela do Alts)
local CFG_SIDE    = { 0.082, 0.098, 0.114 }     -- sidebar um tom mais escura
local CFG_TITLEBG = { 0.055, 0.067, 0.078 }     -- titlebar mais escura
local CFG_GOLD    = ACCENT                       -- dourado (headers / categoria ativa)
local CFG_ACCENT  = ACCENT_BLUE                  -- azul (barra de acento / seleção)
local CFG_ON      = COLOR_DONE                    -- verde (toggle ligado)
local CFG_OFF     = { 0.40, 0.42, 0.46 }         -- cinza (toggle desligado)
local CFG_TEXT    = { 0.85, 0.86, 0.88 }         -- texto neutro
local CFG_WHITE8  = "Interface\\Buttons\\WHITE8X8"

-- Ícone de "no cap / concluído" (textura nativa, evita glyph unicode que pode não renderizar)
local CHECK_ICON = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t"

local function hex(col)
  return string.format("%02x%02x%02x",
    math.floor((col[1] or 1) * 255 + 0.5),
    math.floor((col[2] or 1) * 255 + 0.5),
    math.floor((col[3] or 1) * 255 + 0.5))
end

local function colored(col, text)
  return "|cff" .. hex(col) .. tostring(text) .. "|r"
end

-- Cor de qualidade épica (pips do cofre preenchidos)
local QC_EPIC = { 0.64, 0.21, 0.93 }
if GetItemQualityColor then
  local ok, r, g, b = pcall(GetItemQualityColor, 4)
  if ok and type(r) == "number" then QC_EPIC = { r, g, b } end
end

-- Cor do rating de M+ por faixa (usa a API quando disponível)
local function RatingColor(r)
  r = r or 0
  if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
    local ok, col = pcall(C_ChallengeMode.GetDungeonScoreRarityColor, r)
    if ok and type(col) == "table" and col.r then return { col.r, col.g, col.b } end
  end
  if r >= 2500 then return { 1.00, 0.50, 0.00 } end
  if r >= 2000 then return { 0.64, 0.21, 0.93 } end
  if r >= 1500 then return { 0.00, 0.44, 0.87 } end
  if r >= 750  then return { 0.12, 1.00, 0.00 } end
  if r > 0     then return { 1, 1, 1 } end
  return COLOR_MISSING
end

-- ---------------------------------------------------------------------------
-- Ícone de classe (atlas classicon-<token>; fallback CLASS_ICON_TCOORDS)
-- ---------------------------------------------------------------------------
local function SetClassIcon(tex, classFile)
  if not tex then return end
  classFile = classFile or ""
  local atlas = "classicon-" .. classFile:lower()
  local ok = pcall(tex.SetAtlas, tex, atlas)
  if ok and tex.GetAtlas and tex:GetAtlas() == atlas then return end
  tex:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
  local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
  if coords then
    tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  else
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------
local ROW_H   = 24
local GROUP_H = 20  -- altura do header de grupo (agrupar por reino/facção)
local FRAME_W = 600
local FRAME_H = 444
local TOP_TITLE   = 26  -- altura da titlebar
local TOP_SUMMARY = 20  -- linha de resumo
local TOP_HEADER  = 18  -- cabeçalho de colunas
local CONTENT_TOP = TOP_TITLE + TOP_SUMMARY + TOP_HEADER + 4 -- topo do scroll

-- x relativo à esquerda da linha; pips desenhados à parte na coluna "vault".
-- O conteúdo cabe na viewport do ScrollFrame (~570px) para a coluna de ouro
-- (à direita) não ser cortada pelo recorte do scroll.
-- Coluna "M+" funde RATING + CHAVE (mostra "+N" colorido pela faixa de rating; o
-- rating exato vai pro tooltip da linha). A coluna "gold" é opcional (toggle OFF
-- por padrão — /kalts gold) e fica escondida; o total da conta vai no tooltip do
-- minimapa. O cofre tem 9 pips agrupados M+ | Raide | Delve.
local COLS = {
  { key = "name",  x = 20,  w = 140, justify = "LEFT",   label = L.COL_CHAR,  sort = "name"   },
  { key = "ilvl",  x = 168, w = 34,  justify = "RIGHT",  label = L.COL_ILVL,  sort = "ilvl"   },
  { key = "mplus", x = 206, w = 54,  justify = "CENTER", label = L.COL_MPLUS, sort = "rating" },
  { key = "vault", x = 268, w = 116, justify = "CENTER", label = L.COL_VAULT, sort = "vault"  },
  { key = "crest", x = 388, w = 60,  justify = "RIGHT",  label = L.COL_CREST, sort = "crest"  },
  { key = "gold",  x = 470, w = 82,  justify = "RIGHT",  label = L.COL_GOLD,  sort = "gold", optional = true },
}

local PIP_BASE_X = 268

local DIFF_ABBR = {
  [17] = L.DIFF_LFR, [14] = L.DIFF_N, [15] = L.DIFF_H, [16] = L.DIFF_M,
}
local function DiffAbbr(id, name)
  return DIFF_ABBR[id or 0] or (name and name:sub(1, 3)) or "?"
end

-- ---------------------------------------------------------------------------
-- Formatação
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

local function FormatGold(copper)
  if type(copper) ~= "number" or copper <= 0 then return nil end
  local g = math.floor(copper / 10000)
  if BreakUpLargeNumbers then
    local ok, s = pcall(BreakUpLargeNumbers, g)
    if ok and s then return s .. "g" end
  end
  return g .. "g"
end

-- ---------------------------------------------------------------------------
-- Popups (remover / apelido) — preservados
-- ---------------------------------------------------------------------------
StaticPopupDialogs["KRONONALTS_REMOVE"] = {
  text = L.REMOVE_CONFIRM,
  button1 = YES,
  button2 = NO,
  OnAccept = function(_, key) if key then KA.RemoveChar(key) end end,
  timeout = 0, whileDead = true, hideOnEscape = true, showAlert = true, preferredIndex = 3,
}

StaticPopupDialogs["KRONONALTS_NICK"] = {
  text = L.NICK_PROMPT,
  button1 = ACCEPT,
  button2 = CANCEL,
  hasEditBox = true,
  maxLetters = 24,
  OnShow = function(self, data)
    local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
    if eb and data and data.key then
      local c = KrononAltsDB and KrononAltsDB.chars and KrononAltsDB.chars[data.key]
      eb:SetText((c and c.nick) or "")
      eb:HighlightText()
      eb:SetFocus()
    end
  end,
  OnAccept = function(self, data)
    local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
    if eb and data and data.key then KA.SetNick(data.key, eb:GetText()) end
  end,
  EditBoxOnEnterPressed = function(self)
    local parent = self:GetParent()
    local data = parent and parent.data
    if data and data.key then KA.SetNick(data.key, self:GetText()) end
    if parent then parent:Hide() end
  end,
  EditBoxOnEscapePressed = function(self)
    local parent = self:GetParent()
    if parent then parent:Hide() end
  end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function ShowCharMenu(anchor, entry)
  local d = entry.data
  local label = d.nick or d.name or "?"
  if MenuUtil and MenuUtil.CreateContextMenu then
    MenuUtil.CreateContextMenu(anchor, function(_, root)
      if root.CreateTitle then root:CreateTitle(label) end
      root:CreateButton(L.MENU_SET_NICK, function()
        StaticPopup_Show("KRONONALTS_NICK", label, nil, { key = entry.key })
      end)
      -- Atalho p/ o KrononBags (só aparece se o addon estiver presente)
      if type(KrononBags) == "table" and type(KrononBags.Toggle) == "function" then
        root:CreateButton(L.MENU_OPEN_BAGS, function()
          pcall(KrononBags.Toggle)
        end)
      end
      if not entry.isCurrent then
        root:CreateButton(L.MENU_REMOVE, function()
          StaticPopup_Show("KRONONALTS_REMOVE", label, nil, entry.key)
        end)
      end
    end)
  else
    StaticPopup_Show("KRONONALTS_NICK", label, nil, { key = entry.key })
  end
end

-- ---------------------------------------------------------------------------
-- Estado
-- ---------------------------------------------------------------------------
local frame
local scrollChild
local rows = {}
local groupHeaders = {}
local detailFrame
local expandedKey = nil
local fullVaultCount = 0 -- nº de chars com cofre 3/3/3 (define glow estático vs. pulsante)
local Refresh -- forward

-- Rótulo de facção localizado (usa as globais do cliente; fallback p/ o valor cru)
local FACTION_LABEL = {
  Alliance = FACTION_ALLIANCE or "Alliance",
  Horde    = FACTION_HORDE or "Horde",
}

-- Chave/rótulo do grupo de um char conforme o modo ("realm"/"faction")
local function GroupKeyLabel(d, mode)
  if mode == "realm" then
    local r = d.realm or "?"
    return r, r
  elseif mode == "faction" then
    local fac = d.faction or "?"
    return fac, (FACTION_LABEL[fac] or fac)
  end
  return nil, nil
end

-- ---------------------------------------------------------------------------
-- Criação de uma linha (pool)
-- ---------------------------------------------------------------------------
local function CreateRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_H)
  row:EnableMouse(true)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()

  row.hover = row:CreateTexture(nil, "BORDER")
  row.hover:SetAllPoints()
  row.hover:SetColorTexture(1, 1, 1, 0.05)
  row.hover:Hide()

  -- glow dourado SUTIL p/ linha com Grande Cofre cheio (3/3/3); pulsa em BOUNCE.
  -- ARTWORK sublevel -1 = atrás de pips/acento; texto (OVERLAY) fica por cima.
  row.glow = row:CreateTexture(nil, "ARTWORK", nil, -1)
  row.glow:SetAllPoints()
  row.glow:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
  row.glow:SetBlendMode("ADD")
  row.glow:SetAlpha(0)
  row.glow:Hide()
  row.glowAg = row.glow:CreateAnimationGroup()
  local pulse = row.glowAg:CreateAnimation("Alpha")
  pulse:SetFromAlpha(0.15)
  pulse:SetToAlpha(0.50)
  pulse:SetDuration(1.1)
  pulse:SetSmoothing("IN_OUT")
  row.glowAg:SetLooping("BOUNCE")

  row.accent = row:CreateTexture(nil, "ARTWORK")
  row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
  row.accent:SetWidth(3)
  row.accent:Hide()

  -- chevron de expand
  row.chevron = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.chevron:SetPoint("LEFT", row, "LEFT", 6, 0)
  row.chevron:SetWidth(12)
  row.chevron:SetJustifyH("CENTER")
  row.chevron:SetTextColor(0.6, 0.6, 0.6)

  -- ícone de classe
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(16, 16)
  row.icon:SetPoint("LEFT", row, "LEFT", 20, 0)

  -- células de texto
  row.cells = {}
  for _, col in ipairs(COLS) do
    if col.key ~= "vault" then
      local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetPoint("TOPLEFT", row, "TOPLEFT", col.x, 0)
      fs:SetSize(col.w, ROW_H)
      fs:SetJustifyH(col.justify)
      fs:SetJustifyV("MIDDLE")
      fs:SetWordWrap(false)
      row.cells[col.key] = fs
    end
  end
  -- o nome começa após o ícone
  row.cells.name:SetPoint("TOPLEFT", row, "TOPLEFT", 40, 0)
  row.cells.name:SetWidth(128)

  -- pips do cofre: 9 = 3 M+ | 3 Raide | 3 Delve (trilha Mundo). 2 gaps entre grupos.
  row.pips = {}
  for i = 1, 9 do
    local p = row:CreateTexture(nil, "ARTWORK")
    p:SetSize(8, 8)
    local groupGap = math.floor((i - 1) / 3) * 8
    local x = PIP_BASE_X + (i - 1) * 11 + groupGap
    p:SetPoint("LEFT", row, "LEFT", x, 0)
    row.pips[i] = p
  end

  row:SetScript("OnEnter", function(self)
    if not self._current then self.hover:Show() end
    local d = self._data
    if not d then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local cc = RAID_CLASS_COLORS[d.class or ""]
    local cr, cg, cb = 1, 1, 1
    if cc then cr, cg, cb = cc.r, cc.g, cc.b end
    GameTooltip:SetText(d.nick or d.name or "?", cr, cg, cb)
    if d.realm then GameTooltip:AddLine(d.realm, 0.7, 0.7, 0.7) end
    if d.updatedAt then
      GameTooltip:AddLine(string.format(L.TT_UPDATED, FormatAgo(time() - d.updatedAt)), 0.6, 0.8, 1)
    end
    -- M+ exato (a coluna mostra só "+N"; o rating preciso fica aqui)
    local mp = d.mplus
    if type(mp) == "table" then
      if (mp.rating or 0) > 0 then
        GameTooltip:AddLine(string.format(L.TT_RATING, mp.rating), 0.7, 0.7, 0.7)
      end
      if mp.keystoneLevel then
        local kt = string.format(L.TT_KEYSTONE, mp.keystoneLevel)
        if mp.keystoneMap and mp.keystoneMap ~= "" then kt = kt .. " " .. mp.keystoneMap end
        GameTooltip:AddLine(kt, 0.7, 0.7, 0.7)
      end
    end
    if self._stale then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L.STALE, 1, 0.4, 0.4, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.CLICK_EXPAND, 0.5, 0.5, 0.5)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function(self)
    self.hover:Hide()
    GameTooltip:Hide()
  end)
  row:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
      if self._entry then ShowCharMenu(self, self._entry) end
    else
      if self._key then
        if expandedKey == self._key then expandedKey = nil else expandedKey = self._key end
        if Refresh then Refresh() end
      end
    end
  end)

  return row
end

-- ---------------------------------------------------------------------------
-- Preenchimento de uma linha
-- ---------------------------------------------------------------------------
local function PopulateRow(row, entry, index)
  local d = entry.data
  local v = d.vault
  local hasRewards = v and v.hasRewards
  local stale = (not entry.isCurrent) and KA.IsStale(d)

  row._data, row._entry, row._key = d, entry, entry.key
  row._current, row._stale = entry.isCurrent, stale

  -- fundo / acento
  if entry.isCurrent then
    row.bg:SetColorTexture(ACCENT_BLUE[1], ACCENT_BLUE[2], ACCENT_BLUE[3], 0.10)
    row.accent:SetColorTexture(ACCENT_BLUE[1], ACCENT_BLUE[2], ACCENT_BLUE[3], 1); row.accent:Show()
  elseif hasRewards then
    row.bg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.12)
    row.accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1); row.accent:Show()
  elseif index % 2 == 0 then
    row.bg:SetColorTexture(1, 1, 1, 0.02); row.accent:Hide()
  else
    row.bg:SetColorTexture(0, 0, 0, 0); row.accent:Hide()
  end
  row:SetAlpha(stale and 0.6 or 1)

  -- chevron
  row.chevron:SetText((expandedKey == entry.key) and "-" or "+") -- - aberto / + fechado (ASCII p/ renderizar sempre)

  -- classe / cor
  local cc = RAID_CLASS_COLORS[d.class or ""]
  local cr, cg, cb = 1, 1, 1
  if cc then cr, cg, cb = cc.r, cc.g, cc.b end
  SetClassIcon(row.icon, d.class)

  -- NOME
  local shown = d.nick or d.name or "?"
  if stale then shown = "|cffff4040(!)|r " .. shown end
  row.cells.name:SetTextColor(cr, cg, cb)
  row.cells.name:SetText(shown)

  -- ILVL
  if d.ilvl then
    row.cells.ilvl:SetText("|cffe6e6f0" .. d.ilvl .. "|r")
  else
    row.cells.ilvl:SetText(colored(COLOR_MISSING, L.NONE))
  end

  -- M+ (rating + chave fundidos): mostra "+N" da chave colorido pela faixa de
  -- rating; sem chave mas com rating, mostra o rating. O valor exato vai no tooltip.
  local mp = d.mplus or {}
  local rating = mp.rating or 0
  if mp.keystoneLevel then
    row.cells.mplus:SetText(colored(RatingColor(rating), "+" .. mp.keystoneLevel))
  elseif rating > 0 then
    row.cells.mplus:SetText(colored(RatingColor(rating), tostring(rating)))
  else
    row.cells.mplus:SetText(colored(COLOR_MISSING, L.NONE))
  end

  -- COFRE (9 pips): M+ | Raide | Delve (trilha Mundo). Um alt que só fez delves
  -- preenche o 3º grupo e deixa de parecer vazio.
  local slotsM = (v and v.mplus and v.mplus.slots) or {}
  local slotsR = (v and v.raid and v.raid.slots) or {}
  local slotsW = (v and v.world and v.world.slots) or {}
  local function setPip(tex, slot)
    if slot and slot.unlocked then
      tex:SetColorTexture(QC_EPIC[1], QC_EPIC[2], QC_EPIC[3], 1)
    else
      tex:SetColorTexture(0.45, 0.45, 0.50, 0.35)
    end
  end
  for i = 1, 3 do setPip(row.pips[i],     slotsM[i]) end
  for i = 1, 3 do setPip(row.pips[3 + i], slotsR[i]) end
  for i = 1, 3 do setPip(row.pips[6 + i], slotsW[i]) end

  -- CREST: indicador de CAP semanal (✓ no cap, senão progresso curto da crest que
  -- você está enchendo). Os 5 tiers em número ficam no detalhe.
  local track, bestQty
  if type(d.currencies) == "table" then
    for _, c in ipairs(d.currencies) do
      if c.kind == "crest" then
        if (c.weeklyMax or 0) > 0 then
          if not track
             or (c.weekly or 0) > (track.weekly or 0)
             or ((c.weekly or 0) == (track.weekly or 0) and (c.weeklyMax or 0) > (track.weeklyMax or 0)) then
            track = c
          end
        elseif (c.quantity or 0) > 0 and (not bestQty or c.quantity > bestQty.quantity) then
          bestQty = c
        end
      end
    end
  end
  if track then
    if (track.weekly or 0) >= (track.weeklyMax or 0) then
      row.cells.crest:SetText(CHECK_ICON)
    else
      row.cells.crest:SetText(colored(COLOR_NEUTRAL, (track.weekly or 0) .. "/" .. (track.weeklyMax or 0)))
    end
  elseif bestQty then
    row.cells.crest:SetText(colored(COLOR_NEUTRAL, tostring(bestQty.quantity)))
  else
    row.cells.crest:SetText(colored(COLOR_MISSING, L.NONE))
  end

  -- OURO (coluna opcional, escondida por padrão — /kalts gold). Número neutro.
  if KA.GetShowGold and KA.GetShowGold() then
    local g = FormatGold(d.gold)
    row.cells.gold:SetText(g and colored(COLOR_NEUTRAL, g) or colored(COLOR_MISSING, L.NONE))
    row.cells.gold:Show()
  else
    row.cells.gold:Hide()
  end

  -- GLOW dourado: só na(s) linha(s) com Grande Cofre cheio (3/3/3). Com VÁRIAS
  -- linhas cheias, usa brilho ESTÁTICO (menos ruído de movimento); com 1 só, pulsa.
  local vaultIsFull = KA.IsVaultFull and KA.IsVaultFull(d)
  if row.glow then
    if vaultIsFull then
      row.glow:Show()
      if fullVaultCount and fullVaultCount > 1 then
        if row.glowAg and row.glowAg:IsPlaying() then row.glowAg:Stop() end
        row.glow:SetAlpha(0.22)
      else
        if row.glowAg and not row.glowAg:IsPlaying() then row.glowAg:Play() end
      end
    else
      if row.glowAg and row.glowAg:IsPlaying() then row.glowAg:Stop() end
      row.glow:SetAlpha(0)
      row.glow:Hide()
    end
  end
end

-- ---------------------------------------------------------------------------
-- Texto do painel de detalhe (lado direito, rich text)
-- ---------------------------------------------------------------------------
-- Filtra as seções por modo (DB.settings.mode):
--   pve  → seções PvE (Cofre, Delves, M+ por masmorra, raide, moedas) + Conquista semanal
--   pvp  → só a seção PvP (rating por modalidade, Conquista, semanal); esconde M+/raide/delves
--   both → tudo + PvP (a Conquista vai só na seção PvP, sem duplicar)
local function BuildDetailText(d, mode)
  mode = mode or "pve"
  local showPvE = (mode ~= "pvp")
  local showPvP = (mode == "pvp" or mode == "both")
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  local function head(s) add(colored(ACCENT, s)) end
  local v = d.vault

  if showPvE then
    -- GRANDE COFRE — ilvl dos slots cheios + marcador neutro nos vazios. SEM repetir
    -- "falta +N" (o painel "O que falta" no topo já é o destaque acionável → dedup).
    head(L.DETAIL_VAULT)
    local function trackLine(label, t)
      local parts = {}
      if type(t) == "table" and type(t.slots) == "table" then
        for _, s in ipairs(t.slots) do
          if s.unlocked then
            parts[#parts + 1] = colored(QC_EPIC, s.ilvl and ("ilvl " .. s.ilvl) or "+")
          else
            parts[#parts + 1] = colored(COLOR_MISSING, "\194\183") -- · slot ainda vazio
          end
        end
      end
      if #parts == 0 then parts[1] = colored(COLOR_MISSING, L.NONE) end
      local filled = (t and t.filled) or 0
      local total = (t and t.total) or 3
      add(string.format("  |cffcfcfcf%s|r  |cff888888%d/%d|r   %s",
        label, filled, total, table.concat(parts, "  ")))
    end
    trackLine(L.TRACK_MPLUS, v and v.mplus)
    trackLine(L.TRACK_RAID,  v and v.raid)
    trackLine(L.TRACK_WORLD, v and v.world)
    if v and v.hasRewards then add("  " .. colored(ACCENT, L.VAULT_HAS_REWARDS)) end
    add(" ")

    -- DELVES (promovido pro topo: tier + chave do cofre). A trilha Mundo já aparece
    -- nos pips/cofre acima, então aqui não repetimos a contagem de slots.
    head(L.DETAIL_DELVES)
    do
      local anyDelve = false
      local dv = d.delves
      if type(dv) == "table" and (dv.tier or 0) > 0 then
        anyDelve = true
        add(string.format("  |cffcfcfcf%s|r  %s", L.DELVE_TIER, colored(COLOR_DONE, tostring(dv.tier))))
      end
      if type(d.currencies) == "table" then
        for _, c in ipairs(d.currencies) do
          if c.kind == "delve" then
            anyDelve = true
            local amount = tostring(c.quantity or 0)
            if (c.max or 0) > 0 then amount = amount .. "/" .. c.max end
            local wk = ""
            if (c.weeklyMax or 0) > 0 then
              wk = "  |cff888888(" .. (c.weekly or 0) .. "/" .. c.weeklyMax .. " " .. L.TT_CREST_WEEKLY .. ")|r"
            end
            add(string.format("  |cffcfcfcf%s|r  %s%s", c.name or "?", colored(COLOR_NEUTRAL, amount), wk))
          end
        end
      end
      if not anyDelve then add("  " .. colored(COLOR_MISSING, L.DELVE_NONE)) end
    end
    add(" ")

    -- MÍTICA+ POR MASMORRA
    head(L.DETAIL_MPLUS)
    local maps = d.mplusMaps
    if type(maps) == "table" and #maps > 0 then
      for _, mapinfo in ipairs(maps) do
        local icon = ""
        if type(mapinfo.texture) == "number" and mapinfo.texture > 0 then
          icon = "|T" .. mapinfo.texture .. ":14:14:0:0:64:64:5:59:5:59|t "
        end
        local lvl
        if (mapinfo.level or 0) > 0 then
          lvl = colored(COLOR_DONE, "+" .. mapinfo.level)   -- feita esta semana
        else
          lvl = colored(COLOR_ACTION, L.MPLUS_TODO)          -- falta correr esta semana
        end
        add(string.format("  %s|cffe6e6f0%s|r  %s", icon, mapinfo.name or "?", lvl))
      end
    else
      add("  " .. colored(COLOR_MISSING, L.NO_DATA))
    end
    add(" ")

    -- LOCKOUTS DE RAIDE — 1 linha derivada (o lockout mais relevante; os pips de
    -- Raide do cofre já cobrem o resto). "+N" indica lockouts adicionais.
    head(L.DETAIL_RAID)
    local raids = d.raids
    if type(raids) == "table" and #raids > 0 then
      local top = raids[1]
      local total = top.total or 0
      local prog = top.progress or 0
      local done = total > 0 and prog >= total
      local extra = (#raids > 1) and (" |cff888888+" .. (#raids - 1) .. "|r") or ""
      add(string.format("  |cffe6e6f0%s|r |cff888888(%s)|r  %s%s",
        top.name or "?", top.difficultyName or DiffAbbr(top.difficultyId),
        colored(done and COLOR_DONE or COLOR_NEUTRAL, prog .. "/" .. total), extra))
    else
      add("  " .. colored(COLOR_MISSING, L.TT_NO_RAID))
    end
    add(" ")

    -- MOEDAS & CRESTS (5 tiers; moedas de delve aparecem na seção Delves acima).
    -- ✓ marca a crest no cap semanal; números em cinza neutro.
    head(L.DETAIL_CURR)
    local currencies = d.currencies
    local anyCurr = false
    if type(currencies) == "table" then
      for _, c in ipairs(currencies) do
        if c.kind ~= "delve" then
          anyCurr = true
          local amount = tostring(c.quantity or 0)
          if (c.max or 0) > 0 then amount = amount .. "/" .. c.max end
          local wk = ""
          if (c.weeklyMax or 0) > 0 then
            if (c.weekly or 0) >= c.weeklyMax then
              wk = "  " .. CHECK_ICON
            else
              wk = "  |cff888888(" .. (c.weekly or 0) .. "/" .. c.weeklyMax .. " " .. L.TT_CREST_WEEKLY .. ")|r"
            end
          end
          add(string.format("  |cffcfcfcf%s|r  %s%s", c.name or "?", colored(COLOR_NEUTRAL, amount), wk))
        end
      end
    end
    if not anyCurr then add("  " .. colored(COLOR_MISSING, L.NONE)) end

    -- SEMANAIS — Conquista (PvP) só quando há pontos ganhos (earned>0). No modo "both"
    -- a Conquista vai na seção PvP abaixo (não duplicar) → aqui só no modo PvE puro.
    if mode == "pve" then
      local wk = d.weeklies
      if type(wk) == "table" and type(wk.conquest) == "table" and (wk.conquest.earned or 0) > 0 then
        local cap = wk.conquest.cap or 0
        local earned = wk.conquest.earned or 0
        local capped = cap > 0 and earned >= cap
        add(" ")
        head(L.DETAIL_WEEKLY)
        add(string.format("  |cffcfcfcf%s|r  %s", L.WEEKLY_CONQUEST,
          capped and CHECK_ICON or colored(COLOR_NEUTRAL, earned .. (cap > 0 and ("/" .. cap) or ""))))
      end
    end

    -- PROFISSÕES — atrás de um toggle (OFF por padrão, /kalts prof ou botão no
    -- detalhe). A dica "abra a profissão" só aparece no estado vazio.
    if KA.GetShowProfessions and KA.GetShowProfessions() then
      add(" ")
      head(L.DETAIL_PROF)
      local profs = d.professions
      if type(profs) == "table" and #profs > 0 then
        for _, p in ipairs(profs) do
          local extra = {}
          if type(p.skillLevel) == "number" and (p.maxSkillLevel or 0) > 0 then
            extra[#extra + 1] = "|cff888888" .. p.skillLevel .. "/" .. p.maxSkillLevel .. "|r"
          end
          if type(p.knowledge) == "number" then
            extra[#extra + 1] = colored(COLOR_NEUTRAL, L.PROF_KNOWLEDGE .. " " .. p.knowledge)
          end
          add(string.format("  |cffcfcfcf%s|r  %s", p.name or "?", table.concat(extra, "  ")))
        end
      else
        add("  " .. colored(COLOR_MISSING, L.PROF_OPEN_HINT))
      end
    end
  end

  -- PvP — rating por modalidade + Conquista (ganho/cap semanal) + honra. Só nos
  -- modos PvP/Ambos. Blank de separação só quando já há seções acima (modo Ambos).
  if showPvP then
    if #lines > 0 then add(" ") end
    head(L.DETAIL_PVP)
    local pvp = d.pvp
    local anyPvP = false
    if type(pvp) == "table" then
      if type(pvp.ratings) == "table" then
        for _, r in ipairs(pvp.ratings) do
          if (r.rating or 0) > 0 then
            anyPvP = true
            local extra = ""
            if (r.seasonBest or 0) > (r.rating or 0) then
              extra = "  |cff888888(" .. r.seasonBest .. ")|r"
            end
            add(string.format("  |cffcfcfcf%s|r  %s%s",
              L[r.key] or r.key or "?", colored(RatingColor(r.rating), tostring(r.rating)), extra))
          end
        end
      end
      if type(pvp.conquest) == "table" and ((pvp.conquest.cap or 0) > 0 or (pvp.conquest.earned or 0) > 0) then
        anyPvP = true
        local cap = pvp.conquest.cap or 0
        local earned = pvp.conquest.earned or 0
        local capped = cap > 0 and earned >= cap
        add(string.format("  |cffcfcfcf%s|r  %s", L.WEEKLY_CONQUEST,
          capped and CHECK_ICON or colored(COLOR_NEUTRAL, earned .. (cap > 0 and ("/" .. cap) or ""))))
      end
      if type(pvp.honorLevel) == "number" and pvp.honorLevel > 0 then
        anyPvP = true
        add(string.format("  |cffcfcfcf%s|r  %s", L.PVP_HONOR, colored(COLOR_NEUTRAL, tostring(pvp.honorLevel))))
      end
    end
    if not anyPvP then add("  " .. colored(COLOR_MISSING, L.PVP_NONE)) end
  end

  return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------------
-- Painel de detalhe (criado uma vez, reutilizado)
-- ---------------------------------------------------------------------------
local function EnsureDetail()
  if detailFrame then return detailFrame end
  local df = CreateFrame("Frame", nil, scrollChild)
  df:Hide()

  df.bg = df:CreateTexture(nil, "BACKGROUND")
  df.bg:SetAllPoints()
  df.bg:SetColorTexture(0, 0, 0, 0.25)

  df.top = df:CreateTexture(nil, "ARTWORK")
  df.top:SetHeight(1)
  df.top:SetPoint("TOPLEFT", df, "TOPLEFT", 8, 0)
  df.top:SetPoint("TOPRIGHT", df, "TOPRIGHT", -8, 0)
  df.top:SetColorTexture(0.5, 0.5, 0.5, 0.30)

  -- retrato (esquerda)
  df.portrait = df:CreateTexture(nil, "ARTWORK")
  df.portrait:SetSize(48, 48)
  df.portrait:SetPoint("TOPLEFT", df, "TOPLEFT", 14, -12)

  df.pname = df:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  df.pname:SetPoint("TOPLEFT", df.portrait, "BOTTOMLEFT", -2, -6)
  df.pname:SetWidth(160)
  df.pname:SetJustifyH("LEFT")

  df.pmeta = df:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  df.pmeta:SetPoint("TOPLEFT", df.pname, "BOTTOMLEFT", 0, -2)
  df.pmeta:SetWidth(160)
  df.pmeta:SetJustifyH("LEFT")
  df.pmeta:SetTextColor(0.7, 0.7, 0.7)

  df.pnext = df:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  df.pnext:SetPoint("TOPLEFT", df.pmeta, "BOTTOMLEFT", 0, -8)
  df.pnext:SetWidth(160)
  df.pnext:SetJustifyH("LEFT")
  df.pnext:SetJustifyV("TOP")

  -- toggle de Profissões (abaixo da coluna esquerda; segue a altura de pnext)
  df.profBtn = CreateFrame("Button", nil, df)
  df.profBtn:SetSize(150, 16)
  df.profBtn:SetPoint("TOPLEFT", df.pnext, "BOTTOMLEFT", 0, -10)
  local pbt = df.profBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pbt:SetPoint("LEFT", df.profBtn, "LEFT", 0, 0)
  pbt:SetJustifyH("LEFT")
  pbt:SetTextColor(0.6, 0.6, 0.6)
  df.profBtn.text = pbt
  df.profBtn:SetScript("OnClick", function()
    if KA.ToggleProfessions then KA.ToggleProfessions() end
  end)
  df.profBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
  df.profBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(0.6, 0.6, 0.6) end)

  -- corpo (direita) — largura definida explicitamente em PopulateDetail
  df.body = df:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  df.body:SetPoint("TOPLEFT", df, "TOPLEFT", 188, -12)
  df.body:SetJustifyH("LEFT")
  df.body:SetJustifyV("TOP")
  df.body:SetSpacing(2)

  detailFrame = df
  return df
end

local function PopulateDetail(entry)
  local df = EnsureDetail()
  local d = entry.data

  local cc = RAID_CLASS_COLORS[d.class or ""]
  local cr, cg, cb = 1, 1, 1
  if cc then cr, cg, cb = cc.r, cc.g, cc.b end

  SetClassIcon(df.portrait, d.class)
  df.pname:SetTextColor(cr, cg, cb)
  df.pname:SetText(d.nick or d.name or "?")

  local meta = {}
  if d.spec then meta[#meta + 1] = d.spec end
  if d.realm then meta[#meta + 1] = d.realm end
  df.pmeta:SetText(table.concat(meta, "  \194\183  "))

  -- próxima ação
  local nexts = (KA.GetNextActions and KA.GetNextActions(d.vault)) or {}
  if #nexts == 0 then
    df.pnext:SetText(colored(COLOR_DONE, L.NEXT_DONE))
  else
    -- destaque acionável: laranja (não é o dourado reservado a recompensa pronta)
    local out = { colored(COLOR_ACTION, L.NEXT_TITLE) }
    for _, na in ipairs(nexts) do
      out[#out + 1] = "  |cffcfcfcf" .. (na.track or "?") .. "|r  " ..
        colored(COLOR_ACTION, string.format(L.NEXT_LINE, na.need or 0, na.slot or 0))
    end
    df.pnext:SetText(table.concat(out, "\n"))
  end

  -- modo de detalhe (filtra as seções): "pve" | "pvp" | "both"
  local mode = (KA.GetMode and KA.GetMode()) or "pve"

  -- toggle de Profissões (detalhe enxuto: OFF por padrão). Some no modo PvP (a seção
  -- de Profissões não é exibida nesse modo).
  if df.profBtn then
    if mode == "pvp" then
      df.profBtn:Hide()
    else
      df.profBtn:Show()
      local on = KA.GetShowProfessions and KA.GetShowProfessions()
      df.profBtn.text:SetText((on and "- " or "+ ") .. L.DETAIL_PROF)
      df.profBtn.text:SetTextColor(0.6, 0.6, 0.6)
    end
  end

  -- largura do corpo derivada do scrollChild (independe da âncora do frame de detalhe)
  local cw = (scrollChild and scrollChild:GetWidth()) or (FRAME_W - 34)
  local bodyW = math.max((cw or 560) - 188 - 12, 200)
  df.body:SetWidth(bodyW)
  df.body:SetText(BuildDetailText(d, mode))

  local bodyH = df.body:GetStringHeight() or 0
  local leftH = 48 + 6 + (df.pname:GetStringHeight() or 12)
              + 4 + (df.pmeta:GetStringHeight() or 10)
              + 8 + (df.pnext:GetStringHeight() or 10)
              + ((mode == "pvp") and 0 or (10 + 16)) -- toggle de Profissões (oculto no modo PvP)
  local h = math.max(bodyH, leftH) + 28
  df:SetHeight(h)
  return h
end

-- ---------------------------------------------------------------------------
-- Cabeçalhos: indicador de ordenação
-- ---------------------------------------------------------------------------
local function UpdateHeaders()
  if not (frame and frame.headers) then return end
  local sort = KA.GetSort and KA.GetSort() or nil
  for key, h in pairs(frame.headers) do
    local label = h.baseLabel or key
    if sort and sort.key == (h.sortKey or key) then
      label = label .. (sort.dir == "asc" and " |TInterface\\Buttons\\Arrow-Up-Up:14:14|t" or " |TInterface\\Buttons\\Arrow-Down-Up:14:14|t")
    end
    if h.text then h.text:SetText(label) end
  end
  -- coluna de ouro é opcional (toggle OFF por padrão)
  local gh = frame.headers.gold
  if gh then gh:SetShown(KA.GetShowGold and KA.GetShowGold() or false) end
end

-- ---------------------------------------------------------------------------
-- Header de grupo (pool) — usado ao agrupar por reino/facção
-- ---------------------------------------------------------------------------
local function CreateGroupHeader(parent)
  local g = CreateFrame("Frame", nil, parent)
  g:SetHeight(GROUP_H)
  g.bg = g:CreateTexture(nil, "BACKGROUND")
  g.bg:SetAllPoints()
  g.bg:SetColorTexture(1, 1, 1, 0.04)
  g.line = g:CreateTexture(nil, "ARTWORK")
  g.line:SetHeight(1)
  g.line:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 4, 0)
  g.line:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", -4, 0)
  g.line:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.25)
  g.text = g:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  g.text:SetPoint("LEFT", g, "LEFT", 10, 0)
  g.text:SetJustifyH("LEFT")
  g.text:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
  return g
end

-- ---------------------------------------------------------------------------
-- Refresh
-- ---------------------------------------------------------------------------
Refresh = function()
  if not frame then return end
  UpdateHeaders()

  local chars = KA.GetChars()
  local n = #chars

  -- resumo consolidado da conta (cofres prontos / no cap de crests / a coletar).
  -- O destaque dourado fica pro segmento "X com recompensa a coletar" (acionável).
  if frame.summary then
    local oks, s = pcall(KA.GetAccountSummary)
    if not oks or type(s) ~= "table" then
      s = { full = 0, rewards = 0, total = 0, crestCapped = 0, goldCopper = 0 }
    end
    fullVaultCount = s.full or 0
    if (s.total or 0) == 0 then
      frame.summary:SetText("|cff888888" .. L.SUMMARY_EMPTY .. "|r")
    else
      local rewards = s.rewards or 0
      local rewardSeg = (rewards > 0)
        and colored(ACCENT, string.format(L.SUMMARY_REWARDS, rewards))
        or  colored(COLOR_NEUTRAL, string.format(L.SUMMARY_REWARDS, rewards))
      frame.summary:SetText(
        string.format("|cffcfcfcf" .. L.SUMMARY_ACCT .. "|r", s.full or 0, s.total or 0, s.crestCapped or 0)
        .. "   \194\183   " .. rewardSeg)
    end
  end

  -- mantém o rótulo do botão de agrupar em sincronia
  if frame.groupBtn and frame.groupBtn.refresh then frame.groupBtn.refresh() end
  -- mantém o checkbox "ocultar concluídos" em sincronia (pode mudar pela config)
  if frame.hideCb and KA.GetHideCompleted then
    frame.hideCb:SetChecked(KA.GetHideCompleted() and true or false)
  end

  -- largura do scrollChild
  local sw = (frame.scroll and frame.scroll:GetWidth()) or (FRAME_W - 34)
  if sw and sw > 0 then scrollChild:SetWidth(sw) end

  -- valida o expandido (pode ter sido removido/ocultado)
  if expandedKey then
    local found = false
    for _, e in ipairs(chars) do if e.key == expandedKey then found = true; break end end
    if not found then expandedKey = nil end
  end

  if detailFrame then detailFrame:Hide() end

  -- monta a lista de exibição: sem agrupar = só chars; agrupando = headers + chars.
  -- A ordenação por coluna (KA.GetChars) é preservada DENTRO de cada grupo; a ordem
  -- dos grupos segue a 1ª aparição na lista já ordenada.
  local mode = (KA.GetGroupBy and KA.GetGroupBy()) or "none"
  local display = {}
  if mode ~= "none" then
    local order, bucket = {}, {}
    for i = 1, n do
      local entry = chars[i]
      local gk, gl = GroupKeyLabel(entry.data, mode)
      gk = gk or "?"
      if not bucket[gk] then
        bucket[gk] = { label = gl or gk, items = {} }
        order[#order + 1] = gk
      end
      local b = bucket[gk]
      b.items[#b.items + 1] = entry
    end
    for _, gk in ipairs(order) do
      local b = bucket[gk]
      display[#display + 1] = { kind = "header", label = b.label, count = #b.items }
      for _, e in ipairs(b.items) do display[#display + 1] = { kind = "char", entry = e } end
    end
  else
    for i = 1, n do display[#display + 1] = { kind = "char", entry = chars[i] } end
  end

  local y = 0
  local ri, hi = 0, 0
  for _, item in ipairs(display) do
    if item.kind == "header" then
      hi = hi + 1
      local gh = groupHeaders[hi]
      if not gh then gh = CreateGroupHeader(scrollChild); groupHeaders[hi] = gh end
      gh.text:SetText(string.format("%s  |cff888888(%d)|r", item.label or "?", item.count or 0))
      gh:ClearAllPoints()
      gh:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
      gh:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
      gh:Show()
      y = y + GROUP_H
    else
      local entry = item.entry
      ri = ri + 1
      local row = rows[ri]
      if not row then row = CreateRow(scrollChild); rows[ri] = row end
      PopulateRow(row, entry, ri)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
      row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
      row:Show()
      y = y + ROW_H

      if expandedKey == entry.key then
        local h = PopulateDetail(entry)
        detailFrame:ClearAllPoints()
        detailFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
        detailFrame:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -y)
        detailFrame:Show()
        y = y + (h or 0)
      end
    end
  end
  for i = ri + 1, #rows do
    local r = rows[i]
    r:Hide()
    -- para a animação de glow das linhas recicladas/ocultas (evita vazamento)
    if r.glowAg and r.glowAg:IsPlaying() then r.glowAg:Stop() end
    if r.glow then r.glow:Hide() end
  end
  for i = hi + 1, #groupHeaders do groupHeaders[i]:Hide() end

  if frame.empty then frame.empty:SetShown(n == 0) end
  scrollChild:SetHeight(math.max(y, 1))
end

-- ---------------------------------------------------------------------------
-- Posição persistida
-- ---------------------------------------------------------------------------
local function SavePosition(self)
  local p, _, rp, x, y = self:GetPoint()
  if KrononAltsDB then
    KrononAltsDB.pos = { point = p, relPoint = rp, x = x, y = y }
  end
end

local function ApplyPosition(self)
  local pos = KrononAltsDB and KrononAltsDB.pos
  self:ClearAllPoints()
  if type(pos) == "table" and pos.point then
    self:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
  else
    self:SetPoint("CENTER")
  end
end

-- ---------------------------------------------------------------------------
-- Construção da janela
-- ---------------------------------------------------------------------------
local function BuildFrame()
  if frame then return end

  frame = CreateFrame("Frame", "KrononAltsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(FRAME_W, FRAME_H)
  frame:SetFrameStrata("HIGH")
  frame:SetToplevel(true) -- vem INTEIRA pra frente ao clicar (não intercala com a bag/outras janelas)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  ApplyPosition(frame)

  -- fade-in suave ao abrir (animação nativa; SetToFinalAlpha garante alpha 1 ao fim)
  frame.fadeIn = frame:CreateAnimationGroup()
  local fade = frame.fadeIn:CreateAnimation("Alpha")
  fade:SetFromAlpha(0)
  fade:SetToAlpha(1)
  fade:SetDuration(0.18)
  fade:SetSmoothing("OUT")
  frame.fadeIn:SetToFinalAlpha(true)
  frame:SetScript("OnShow", function(self)
    if self.fadeIn then
      self.fadeIn:Stop()
      self:SetAlpha(0)
      self.fadeIn:Play()
    end
  end)

  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
    })
    frame:SetBackdropColor(BG[1], BG[2], BG[3], 1)
    frame:SetBackdropBorderColor(0, 0, 0, 0.85)
  end

  tinsert(UISpecialFrames, "KrononAltsFrame") -- ESC fecha

  -- TITLEBAR (preto @50%, alça de arrastar)
  local tb = CreateFrame("Frame", nil, frame)
  tb:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  tb:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  tb:SetHeight(TOP_TITLE)
  tb:EnableMouse(true)
  tb:RegisterForDrag("LeftButton")
  tb:SetScript("OnDragStart", function() frame:StartMoving() end)
  tb:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePosition(frame) end)
  local tbbg = tb:CreateTexture(nil, "BACKGROUND")
  tbbg:SetAllPoints()
  tbbg:SetColorTexture(0, 0, 0, 0.50)

  local tbicon = tb:CreateTexture(nil, "ARTWORK")
  tbicon:SetSize(16, 16)
  tbicon:SetPoint("LEFT", tb, "LEFT", 8, 0)
  tbicon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  tbicon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  local title = tb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("LEFT", tbicon, "RIGHT", 6, 0)
  title:SetText(L.TITLE)
  title:SetTextColor(1, 1, 1)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
  close:SetFrameLevel(tb:GetFrameLevel() + 5)
  close:SetScript("OnClick", function() frame:Hide() end)

  -- BOTÃO DE ENGRENAGEM (abre a janela de config) — à esquerda do X
  local gear = CreateFrame("Button", nil, tb)
  gear:SetSize(18, 18)
  gear:SetPoint("RIGHT", close, "LEFT", -2, 0)
  gear:SetFrameLevel(tb:GetFrameLevel() + 5)
  local gearTex = gear:CreateTexture(nil, "ARTWORK")
  gearTex:SetAllPoints()
  gearTex:SetTexture("Interface\\GossipFrame\\BinderGossipIcon")
  gearTex:SetVertexColor(0.85, 0.85, 0.88, 1)
  gear.tex = gearTex
  gear:SetScript("OnEnter", function(self)
    self.tex:SetVertexColor(1, 1, 1, 1)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L.TIP_CONFIG, 1, 1, 1)
    GameTooltip:Show()
  end)
  gear:SetScript("OnLeave", function(self)
    self.tex:SetVertexColor(0.85, 0.85, 0.88, 1)
    GameTooltip:Hide()
  end)
  gear:SetScript("OnClick", function() if KA.OpenConfig then KA.OpenConfig() end end)
  frame.gear = gear

  -- countdown na titlebar (entre título e engrenagem)
  local cd = tb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cd:SetPoint("RIGHT", gear, "LEFT", -6, 0)
  cd:SetJustifyH("RIGHT")
  frame.countdown = cd

  -- LINHA DE RESUMO
  local summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summary:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -(TOP_TITLE + 4))
  summary:SetPoint("RIGHT", frame, "RIGHT", -255, 0)
  summary:SetJustifyH("LEFT")
  summary:SetWordWrap(false)
  frame.summary = summary

  -- ocultar concluídos (canto direito da linha de resumo)
  local hideCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  hideCb:SetSize(20, 20)
  hideCb:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -(TOP_TITLE + 2))
  local cbLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cbLabel:SetPoint("RIGHT", hideCb, "LEFT", -2, 0)
  cbLabel:SetText(L.HIDE_COMPLETED)
  cbLabel:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
  hideCb:SetChecked(KA.GetHideCompleted and KA.GetHideCompleted() or false)
  hideCb:SetScript("OnClick", function(self)
    if KA.SetHideCompleted then KA.SetHideCompleted(self:GetChecked()) end
  end)
  frame.hideCb = hideCb

  -- BOTÃO AGRUPAR (3 estados: não / reino / facção) — à esquerda do "ocultar"
  local groupBtn = CreateFrame("Button", nil, frame)
  groupBtn:SetSize(100, 18)
  groupBtn:SetPoint("RIGHT", cbLabel, "LEFT", -14, 0)
  local gbText = groupBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  gbText:SetAllPoints()
  gbText:SetJustifyH("RIGHT")
  gbText:SetWordWrap(false)
  gbText:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
  groupBtn.text = gbText
  groupBtn.refresh = function()
    local m = (KA.GetGroupBy and KA.GetGroupBy()) or "none"
    local name = (m == "realm" and L.GROUP_REALM) or (m == "faction" and L.GROUP_FACTION) or L.GROUP_NONE
    gbText:SetText(string.format(L.GROUP_BTN, name))
  end
  groupBtn:SetScript("OnClick", function(self)
    if KA.CycleGroupBy then KA.CycleGroupBy() end
    if self.refresh then self.refresh() end
  end)
  groupBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
  groupBtn:SetScript("OnLeave", function(self)
    self.text:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
  end)
  groupBtn.refresh()
  frame.groupBtn = groupBtn

  -- CABEÇALHO DE COLUNAS (preto @30%)
  local headerBar = CreateFrame("Frame", nil, frame)
  headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -(TOP_TITLE + TOP_SUMMARY))
  headerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -(TOP_TITLE + TOP_SUMMARY))
  headerBar:SetHeight(TOP_HEADER)
  local hbbg = headerBar:CreateTexture(nil, "BACKGROUND")
  hbbg:SetAllPoints()
  hbbg:SetColorTexture(0, 0, 0, 0.30)

  frame.headers = {}
  for _, col in ipairs(COLS) do
    local h = CreateFrame("Button", nil, headerBar)
    h:SetPoint("LEFT", headerBar, "LEFT", col.x, 0)
    h:SetSize(col.w, TOP_HEADER)
    local fs = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints()
    fs:SetJustifyH(col.justify)
    fs:SetWordWrap(false)
    fs:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
    h.text = fs
    h.baseLabel = col.label or col.key
    fs:SetText(h.baseLabel)
    if col.sort then
      local sortKey = col.sort
      h.sortKey = sortKey -- a seta de ordenação casa por sortKey (ex: coluna "mplus" ordena por "rating")
      local isVault = (col.key == "vault")
      h:SetScript("OnClick", function() if KA.SetSort then KA.SetSort(sortKey) end end)
      h:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L.TT_SORT_HINT, 0.8, 0.8, 0.8)
        -- explica os 3 grupos de pips do cofre: M+ | Raide | Delve
        if isVault then GameTooltip:AddLine(L.VAULT_HEADER_HINT, 0.6, 0.6, 0.6) end
        GameTooltip:Show()
      end)
      h:SetScript("OnLeave", function(self)
        self.text:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
        GameTooltip:Hide()
      end)
    end
    frame.headers[col.key] = h
  end

  -- SCROLLFRAME
  local scroll = CreateFrame("ScrollFrame", "KrononAltsScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -CONTENT_TOP)
  scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 8)
  frame.scroll = scroll

  scrollChild = CreateFrame("Frame", nil, scroll)
  scrollChild:SetSize(FRAME_W - 34, 1)
  scroll:SetScrollChild(scrollChild)

  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll() or 0
    local maxs = self:GetVerticalScrollRange() or 0
    local new = cur - (delta or 0) * 40
    if new < 0 then new = 0 elseif new > maxs then new = maxs end
    self:SetVerticalScroll(new)
  end)

  -- estado vazio
  local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  empty:SetPoint("TOP", scroll, "TOP", 0, -20)
  empty:SetWidth(FRAME_W - 60)
  empty:SetJustifyH("CENTER")
  empty:SetText(L.EMPTY)
  empty:Hide()
  frame.empty = empty

  -- ticker do countdown (1s)
  frame.elapsed = 1
  frame:SetScript("OnUpdate", function(self, e)
    self.elapsed = self.elapsed + e
    if self.elapsed < 1 then return end
    self.elapsed = 0
    local info = KA.GetResetInfo()
    -- só o reset SEMANAL (o diário foi cortado); valor em branco vivo p/ destaque.
    self.countdown:SetText(string.format("|cff888888%s|r |cffffffff%s|r",
      L.RESET_WEEKLY, FormatCountdown(info.weeklySeconds)))
  end)

  Refresh()
  -- nasce oculta: KA.Toggle/Open decidem mostrar (e disparam o fade-in no OnShow).
  -- Sem isto, o frame criado já vem visível e o 1º Toggle apenas o esconderia.
  frame:Hide()
end

-- ---------------------------------------------------------------------------
-- API pública da UI (globais KrononAlts.* — KA == KrononAlts)
-- ---------------------------------------------------------------------------
--- KrononAlts.Toggle() — alterna a visibilidade da janela (cria sob demanda).
function KA.Toggle()
  if not frame then BuildFrame() end
  if frame:IsShown() then
    frame:Hide()
  else
    Refresh()
    frame:Show()
  end
end

--- KrononAlts.Open() — garante a janela ABERTA (nunca fecha). Reutiliza KA.Toggle.
function KA.Open()
  if not frame then BuildFrame() end
  if not frame:IsShown() then KA.Toggle() end
end

KA.bus:Register(function()
  if frame and frame:IsShown() then Refresh() end
end)

-- ===========================================================================
-- JANELA DE CONFIGURAÇÕES PRÓPRIA (autocontida, sem libs) — sidebar de categorias
-- + painel rolável com fábrica uniforme de controles (toggle switch / dropdown).
-- Estilo coerente com o KrononBags v0.54.0, mas sem dependências. Abre pela
-- engrenagem da janela do Alts e por /kalts config. Lembra a última categoria.
-- ===========================================================================
local cfgFrame

local function cfgFlat(f, col, a, ba)
  if not f.SetBackdrop then return end
  f:SetBackdrop({ bgFile = CFG_WHITE8, edgeFile = CFG_WHITE8, edgeSize = 1, tile = false })
  f:SetBackdropColor(col[1], col[2], col[3], a or 1)
  f:SetBackdropBorderColor(0, 0, 0, ba or 0.85)
end

-- atalho p/ a SavedVariable de settings (defensivo)
local function cfgSettings()
  if type(KrononAltsDB) == "table" and type(KrononAltsDB.settings) == "table" then
    return KrononAltsDB.settings
  end
  return nil
end

-- restaura os ajustes migrados pra config aos padrões (usa setters → disparam o bus)
local function cfgResetDefaults()
  if KA.SetMode then KA.SetMode("pve") end
  if type(KrononAltsDB) == "table" then
    KrononAltsDB.showGold = false
    KrononAltsDB.showProfessions = false
    KrononAltsDB.loginReminder = true
    KrononAltsDB.hideCompleted = false
  end
  if KA.SetGroupBy then KA.SetGroupBy("none") end
  KA.bus:Fire()
  print("|cff33ff33KrononAlts|r: " .. L.CFG_RESET_DONE)
end

StaticPopupDialogs["KRONONALTS_RESETCFG"] = {
  text = L.CFG_RESET_CONFIRM,
  button1 = YES,
  button2 = NO,
  OnAccept = function() cfgResetDefaults() end,
  timeout = 0, whileDead = true, hideOnEscape = true, showAlert = true, preferredIndex = 3,
}

local function BuildConfig()
  if cfgFrame then return end

  local CFG = CreateFrame("Frame", "KrononAltsConfig", UIParent, "BackdropTemplate")
  CFG:SetSize(560, 440)
  CFG:SetFrameStrata("DIALOG")
  CFG:SetToplevel(true)
  CFG:SetClampedToScreen(true)
  CFG:SetMovable(true); CFG:EnableMouse(true)
  cfgFlat(CFG, CFG_BG, 0.98, 0.85)
  cfgFrame = CFG

  CFG.panels = {}      -- [key] = scrollframe
  CFG.childs = {}      -- [key] = scroll child
  CFG.tabButtons = {}  -- [key] = botão da sidebar
  CFG.controls = {}    -- registro de controles (refresh / dependência)

  -- posição salva
  local st = cfgSettings()
  local pos = st and st.cfgPos
  CFG:ClearAllPoints()
  if type(pos) == "table" and pos.point then
    CFG:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
  else
    CFG:SetPoint("CENTER")
  end

  tinsert(UISpecialFrames, "KrononAltsConfig") -- ESC fecha

  -- ===== Barra de título =====
  local titlebar = CreateFrame("Frame", nil, CFG, "BackdropTemplate")
  titlebar:SetPoint("TOPLEFT", 1, -1); titlebar:SetPoint("TOPRIGHT", -1, -1)
  titlebar:SetHeight(34)
  cfgFlat(titlebar, CFG_TITLEBG, 1, 0.50)
  titlebar:EnableMouse(true)
  titlebar:RegisterForDrag("LeftButton")
  titlebar:SetScript("OnDragStart", function() CFG:StartMoving() end)
  titlebar:SetScript("OnDragStop", function()
    CFG:StopMovingOrSizing()
    local p, _, rp, x, y = CFG:GetPoint()
    local s = cfgSettings()
    if s and p then s.cfgPos = { point = p, relPoint = rp, x = x, y = y } end
  end)

  local clogo = titlebar:CreateTexture(nil, "ARTWORK")
  clogo:SetSize(18, 18); clogo:SetPoint("LEFT", 10, 0)
  clogo:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  clogo:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local title = titlebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("LEFT", clogo, "RIGHT", 8, 0)
  title:SetText(L.CFG_TITLE); title:SetTextColor(CFG_GOLD[1], CFG_GOLD[2], CFG_GOLD[3])

  local ver = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("KrononAlts", "Version")) or ""
  if ver ~= "" then
    local verFS = titlebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    verFS:SetPoint("LEFT", title, "RIGHT", 8, -1); verFS:SetText("v" .. ver)
  end

  local close = CreateFrame("Button", nil, CFG, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- ===== Seletor de MODO no topo (PvE / PvP / Ambos) — filtra o detalhe =====
  local modeBar = CreateFrame("Frame", nil, CFG)
  modeBar:SetPoint("TOPLEFT", titlebar, "BOTTOMLEFT", 0, -6)
  modeBar:SetPoint("TOPRIGHT", titlebar, "BOTTOMRIGHT", 0, -6)
  modeBar:SetHeight(28)
  local mlbl = modeBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  mlbl:SetPoint("LEFT", 12, 0); mlbl:SetText(L.CFG_MODE_LABEL .. ":")
  mlbl:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3])

  local MODES = {
    { k = "pve",  t = L.CFG_MODE_PVE  },
    { k = "pvp",  t = L.CFG_MODE_PVP  },
    { k = "both", t = L.CFG_MODE_BOTH },
  }
  CFG.modeButtons = {}
  local prevAnchor = mlbl
  for i, m in ipairs(MODES) do
    local b = CreateFrame("Button", nil, modeBar)
    b:SetSize(72, 22)
    if i == 1 then
      b:SetPoint("LEFT", prevAnchor, "RIGHT", 10, 0)
    else
      b:SetPoint("LEFT", prevAnchor, "RIGHT", 4, 0)
    end
    prevAnchor = b
    local selbg = b:CreateTexture(nil, "BACKGROUND")
    selbg:SetAllPoints(); selbg:SetTexture(CFG_WHITE8)
    selbg:SetVertexColor(CFG_ACCENT[1], CFG_ACCENT[2], CFG_ACCENT[3], 0.16); selbg:Hide()
    b.selbg = selbg
    local bar = b:CreateTexture(nil, "ARTWORK")
    bar:SetHeight(2); bar:SetPoint("BOTTOMLEFT", 0, 0); bar:SetPoint("BOTTOMRIGHT", 0, 0)
    bar:SetTexture(CFG_WHITE8); bar:SetVertexColor(CFG_ACCENT[1], CFG_ACCENT[2], CFG_ACCENT[3], 1); bar:Hide()
    b.bar = bar
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture(CFG_WHITE8); hl:SetVertexColor(1, 1, 1, 0.05)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints(); fs:SetJustifyH("CENTER"); fs:SetText(m.t)
    b.fs = fs
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetText(L.CFG_MODE_LABEL, 1, 1, 1)
      GameTooltip:AddLine(L.CFG_MODE_HINT, 0.8, 0.8, 0.8, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function()
      if KA.SetMode then KA.SetMode(m.k) end
      if CFG.paintMode then CFG.paintMode() end
    end)
    CFG.modeButtons[m.k] = b
  end
  function CFG.paintMode()
    local cur = (KA.GetMode and KA.GetMode()) or "pve"
    for k, b in pairs(CFG.modeButtons) do
      local active = (k == cur)
      b.selbg:SetShown(active); b.bar:SetShown(active)
      if active then b.fs:SetTextColor(CFG_GOLD[1], CFG_GOLD[2], CFG_GOLD[3])
      else b.fs:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3]) end
    end
  end

  -- ===== Sidebar (esquerda) =====
  local sidebar = CreateFrame("Frame", nil, CFG, "BackdropTemplate")
  sidebar:SetPoint("TOPLEFT", modeBar, "BOTTOMLEFT", 1, -6)
  sidebar:SetPoint("BOTTOMLEFT", 1, 1)
  sidebar:SetWidth(150)
  cfgFlat(sidebar, CFG_SIDE, 1, 0.40)

  local vdiv = CFG:CreateTexture(nil, "ARTWORK")
  vdiv:SetColorTexture(1, 1, 1, 0.06); vdiv:SetWidth(1)
  vdiv:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
  vdiv:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)

  -- área de conteúdo (à direita da sidebar)
  local content = CreateFrame("Frame", nil, CFG)
  content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 7, -2)
  content:SetPoint("BOTTOMRIGHT", -8, 10)

  -- ========= FÁBRICA DE CONTROLES =========
  -- header de seção: dourado + filete 1px
  local function Section(ctx, text)
    local h = ctx.parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 12, ctx.y)
    h:SetText(text); h:SetTextColor(CFG_GOLD[1], CFG_GOLD[2], CFG_GOLD[3])
    local d = ctx.parent:CreateTexture(nil, "ARTWORK")
    d:SetHeight(1)
    d:SetPoint("LEFT", h, "RIGHT", 10, 0)
    d:SetPoint("RIGHT", ctx.parent, "RIGHT", -6, 0)
    d:SetPoint("TOP", h, "CENTER", 0, 0)
    d:SetColorTexture(CFG_GOLD[1], CFG_GOLD[2], CFG_GOLD[3], 0.30)
    ctx.y = ctx.y - 24
  end

  -- registra controle (refresh + dependência)
  local function register(ctx, entry)
    entry.tab = ctx.tab
    table.insert(CFG.controls, entry)
  end

  -- toggle estilo switch (verde ligado / cinza desligado) + label colorida + descrição
  local function Check(ctx, label, getf, setf, desc, depGet)
    local row = CreateFrame("Button", nil, ctx.parent)
    row:SetPoint("TOPLEFT", 8, ctx.y)
    row:SetPoint("RIGHT", ctx.parent, "RIGHT", -6, 0)
    row:SetHeight(44)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture(CFG_WHITE8); hl:SetVertexColor(1, 1, 1, 0.05)
    -- switch
    local sw = CreateFrame("Frame", nil, row)
    sw:SetSize(38, 18); sw:SetPoint("TOPLEFT", 8, -2)
    local track = sw:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(); track:SetTexture(CFG_WHITE8)
    local knob = sw:CreateTexture(nil, "ARTWORK")
    knob:SetSize(14, 14); knob:SetTexture(CFG_WHITE8); knob:SetVertexColor(0.96, 0.96, 0.97, 1)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", sw, "TOPRIGHT", 12, -1); lbl:SetJustifyH("LEFT"); lbl:SetText(label)
    local dsc = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    dsc:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -3)
    dsc:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    dsc:SetJustifyH("LEFT"); dsc:SetWordWrap(true)
    if desc then dsc:SetText(desc) end
    local function paint(on)
      if on then
        track:SetVertexColor(CFG_ON[1], CFG_ON[2], CFG_ON[3], 0.85)
        knob:ClearAllPoints(); knob:SetPoint("RIGHT", -2, 0)
        lbl:SetTextColor(CFG_ON[1], CFG_ON[2], CFG_ON[3])
      else
        track:SetVertexColor(CFG_OFF[1], CFG_OFF[2], CFG_OFF[3], 0.55)
        knob:ClearAllPoints(); knob:SetPoint("LEFT", 2, 0)
        lbl:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3])
      end
    end
    paint(getf() and true or false)
    row:SetScript("OnClick", function()
      local nv = not (getf() and true or false)
      setf(nv); paint(nv)
      if CFG.updateDependents then CFG.updateDependents() end
    end)
    local entry = { label = label, frame = row, depGet = depGet }
    entry.refresh = function() paint(getf() and true or false) end
    entry.setEnabled = function(en)
      row:SetAlpha(en and 1 or 0.4)
      row:EnableMouse(en and true or false)
    end
    register(ctx, entry)
    ctx.y = ctx.y - 48
    return entry
  end

  -- botão de menu (dropdown) usando MenuUtil — usado pelo critério de agrupamento
  local function MenuButton(ctx, label, getTextf, buildf, depGet)
    local row = CreateFrame("Frame", nil, ctx.parent)
    row:SetPoint("TOPLEFT", 8, ctx.y)
    row:SetPoint("RIGHT", ctx.parent, "RIGHT", -6, 0)
    row:SetHeight(42)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", 8, -2); lbl:SetText(label)
    lbl:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3])
    local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btn:SetSize(180, 22); btn:SetPoint("TOPLEFT", 10, -19)
    local function upd() btn:SetText(getTextf()) end
    upd()
    btn:SetScript("OnClick", function(self)
      if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
      MenuUtil.CreateContextMenu(self, function(owner, root) buildf(owner, root, upd) end)
    end)
    local entry = { label = label, frame = row, depGet = depGet }
    entry.refresh = upd
    entry.setEnabled = function(en)
      row:SetAlpha(en and 1 or 0.4)
      if en then btn:Enable() else btn:Disable() end
    end
    register(ctx, entry)
    ctx.y = ctx.y - 46
    return entry
  end

  -- ===== mostra/oculta painel + destaca o botão da sidebar =====
  local function ShowConfigTab(key)
    for k, p in pairs(CFG.panels) do p:SetShown(k == key) end
    for k, b in pairs(CFG.tabButtons) do
      local active = (k == key)
      if b.selbg then b.selbg:SetShown(active) end
      if b.bar then b.bar:SetShown(active) end
      if b.fs then
        if active then b.fs:SetTextColor(CFG_GOLD[1], CFG_GOLD[2], CFG_GOLD[3])
        else b.fs:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3]) end
      end
    end
    local sf, child = CFG.panels[key], CFG.childs[key]
    if sf and child and sf.GetWidth then child:SetWidth(sf:GetWidth()) end
    CFG.activeTab = key
    local s = cfgSettings(); if s then s.cfgLastTab = key end
  end
  CFG.ShowTab = ShowConfigTab

  -- cria um painel ROLÁVEL (scrollframe + child) e devolve o child + ctx
  local function makeScrollPanel(key)
    local sf = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", -22, 0)
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(10, 10)
    sf:SetScrollChild(child)
    sf:SetScript("OnSizeChanged", function(self, w) if w and w > 0 then child:SetWidth(w) end end)
    sf:Hide()
    CFG.panels[key] = sf
    CFG.childs[key] = child
    return child, { parent = child, tab = key, y = -10 }
  end
  local function finishPanel(child, ctx)
    child:SetHeight(math.max(10, -ctx.y + 14))
  end

  -- ===== ordem + ícones das categorias da sidebar =====
  local TABS = {
    { key = "general", label = L.CFG_CAT_GENERAL, icon = "Interface\\ICONS\\INV_Misc_Gear_01" },
    { key = "display", label = L.CFG_CAT_DISPLAY, icon = "Interface\\ICONS\\INV_Misc_PaintBrush" },
    { key = "about",   label = L.CFG_CAT_ABOUT,   icon = "Interface\\ICONS\\INV_Misc_QuestionMark" },
  }
  for i, t in ipairs(TABS) do
    local b = CreateFrame("Button", nil, sidebar)
    b:SetSize(138, 30)
    b:SetPoint("TOPLEFT", 6, -8 - (i - 1) * 32)
    b.tabKey = t.key
    local selbg = b:CreateTexture(nil, "BACKGROUND")
    selbg:SetAllPoints(); selbg:SetTexture(CFG_WHITE8)
    selbg:SetVertexColor(CFG_ACCENT[1], CFG_ACCENT[2], CFG_ACCENT[3], 0.13); selbg:Hide()
    b.selbg = selbg
    local bar = b:CreateTexture(nil, "ARTWORK")
    bar:SetSize(3, 30); bar:SetPoint("LEFT", 0, 0); bar:SetTexture(CFG_WHITE8)
    bar:SetVertexColor(CFG_ACCENT[1], CFG_ACCENT[2], CFG_ACCENT[3], 1); bar:Hide()
    b.bar = bar
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture(CFG_WHITE8); hl:SetVertexColor(1, 1, 1, 0.05)
    local ic = b:CreateTexture(nil, "ARTWORK")
    ic:SetSize(16, 16); ic:SetPoint("LEFT", 12, 0); ic:SetTexture(t.icon)
    ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", ic, "RIGHT", 8, 0); fs:SetText(t.label)
    fs:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3])
    b.fs = fs
    b:SetScript("OnClick", function() ShowConfigTab(t.key) end)
    CFG.tabButtons[t.key] = b
  end

  -- "Restaurar padrões" no rodapé da sidebar
  local resetBtn = CreateFrame("Button", nil, sidebar)
  resetBtn:SetSize(134, 24); resetBtn:SetPoint("BOTTOM", 0, 10)
  local rbBG = resetBtn:CreateTexture(nil, "BACKGROUND")
  rbBG:SetAllPoints(); rbBG:SetTexture(CFG_WHITE8); rbBG:SetVertexColor(1, 1, 1, 0.05)
  local rbHL = resetBtn:CreateTexture(nil, "HIGHLIGHT")
  rbHL:SetAllPoints(); rbHL:SetTexture(CFG_WHITE8); rbHL:SetVertexColor(0.85, 0.30, 0.30, 0.25)
  local rbFS = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  rbFS:SetPoint("CENTER"); rbFS:SetText(L.CFG_RESET); rbFS:SetTextColor(0.9, 0.6, 0.6)
  resetBtn:SetScript("OnClick", function() StaticPopup_Show("KRONONALTS_RESETCFG") end)

  -- ========= GERAL =========
  do
    local child, ctx = makeScrollPanel("general")
    Section(ctx, L.CFG_SEC_BEHAVIOR)
    Check(ctx, L.OPT_REMINDER,
      function() return KrononAltsDB and KrononAltsDB.loginReminder ~= false end,
      function(v) if KrononAltsDB then KrononAltsDB.loginReminder = v and true or false end end,
      L.OPT_REMINDER_DESC)
    Check(ctx, L.HIDE_COMPLETED,
      function() return KA.GetHideCompleted and KA.GetHideCompleted() end,
      function(v) if KA.SetHideCompleted then KA.SetHideCompleted(v) end end,
      L.OPT_HIDE_DESC)

    Section(ctx, L.CFG_SEC_ORGANIZE)
    -- cascata pai→filho: "agrupar" liga/desliga; "agrupar por" (reino/facção) só ativo se ligado
    Check(ctx, L.OPT_GROUP,
      function() return (KA.GetGroupBy and KA.GetGroupBy() or "none") ~= "none" end,
      function(v)
        if not KA.SetGroupBy then return end
        if v then
          local cur = KA.GetGroupBy and KA.GetGroupBy() or "none"
          if cur ~= "realm" and cur ~= "faction" then cur = "realm" end
          KA.SetGroupBy(cur)
        else
          KA.SetGroupBy("none")
        end
      end,
      L.OPT_GROUP_DESC)
    MenuButton(ctx, L.OPT_GROUP_BY,
      function()
        local cur = KA.GetGroupBy and KA.GetGroupBy() or "none"
        return (cur == "faction") and L.GROUP_FACTION or L.GROUP_REALM
      end,
      function(_, root, upd)
        local function opt(val, text)
          local cur = KA.GetGroupBy and KA.GetGroupBy() or "none"
          root:CreateRadio(text, function() return cur == val end, function()
            if KA.SetGroupBy then KA.SetGroupBy(val) end
            if upd then upd() end
            if CFG.updateDependents then CFG.updateDependents() end
          end)
        end
        opt("realm", L.GROUP_REALM)
        opt("faction", L.GROUP_FACTION)
      end,
      function() return (KA.GetGroupBy and KA.GetGroupBy() or "none") ~= "none" end)
    finishPanel(child, ctx)
  end

  -- ========= EXIBIÇÃO =========
  do
    local child, ctx = makeScrollPanel("display")
    Section(ctx, L.CFG_SEC_COLUMNS)
    Check(ctx, L.OPT_GOLD,
      function() return KA.GetShowGold and KA.GetShowGold() end,
      function() if KA.ToggleShowGold then KA.ToggleShowGold() end end,
      L.OPT_GOLD_DESC)
    Check(ctx, L.OPT_PROF,
      function() return KA.GetShowProfessions and KA.GetShowProfessions() end,
      function() if KA.ToggleProfessions then KA.ToggleProfessions() end end,
      L.OPT_PROF_DESC)
    finishPanel(child, ctx)
  end

  -- ========= SOBRE =========
  do
    local child, ctx = makeScrollPanel("about")
    Section(ctx, L.CFG_CAT_ABOUT)
    local desc = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 12, ctx.y); desc:SetPoint("RIGHT", child, "RIGHT", -10, 0)
    desc:SetJustifyH("LEFT"); desc:SetWordWrap(true); desc:SetText(L.CFG_ABOUT_DESC)
    desc:SetTextColor(CFG_TEXT[1], CFG_TEXT[2], CFG_TEXT[3])
    ctx.y = ctx.y - 36
    if ver ~= "" then
      local vfs = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      vfs:SetPoint("TOPLEFT", 12, ctx.y)
      vfs:SetText("|cffcfcfcf" .. L.CFG_ABOUT_VERSION .. ":|r  v" .. ver)
      ctx.y = ctx.y - 24
    end
    Section(ctx, L.CFG_ABOUT_COMMANDS)
    local cmds = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cmds:SetPoint("TOPLEFT", 12, ctx.y); cmds:SetPoint("RIGHT", child, "RIGHT", -10, 0)
    cmds:SetJustifyH("LEFT"); cmds:SetWordWrap(true); cmds:SetText(L.CFG_ABOUT_CMD_LIST)
    ctx.y = ctx.y - 40
    finishPanel(child, ctx)
  end

  -- aplica dependências (cascata pai→filho)
  function CFG.updateDependents()
    for _, c in ipairs(CFG.controls) do
      if c.depGet and c.setEnabled then c.setEnabled(c.depGet() and true or false) end
    end
  end
  -- re-sincroniza todos os controles + modo (ao abrir e quando o bus dispara)
  function CFG.refreshAll()
    for _, c in ipairs(CFG.controls) do if c.refresh then c.refresh() end end
    if CFG.paintMode then CFG.paintMode() end
    CFG.updateDependents()
  end

  CFG.paintMode()
  CFG.refreshAll()
  local startTab = (st and st.cfgLastTab) or "general"
  if not CFG.panels[startTab] then startTab = "general" end
  ShowConfigTab(startTab)
  CFG:Hide()
end

-- API pública de config (globais KrononAlts.*)
function KA.OpenConfig()
  if not cfgFrame then BuildConfig() end
  if cfgFrame then
    if cfgFrame.refreshAll then cfgFrame.refreshAll() end
    local s = cfgSettings()
    if cfgFrame.ShowTab then cfgFrame.ShowTab((s and s.cfgLastTab) or "general") end
    cfgFrame:Show()
  end
end

function KA.ToggleConfig()
  if not cfgFrame then BuildConfig() end
  if cfgFrame and cfgFrame:IsShown() then
    cfgFrame:Hide()
  else
    KA.OpenConfig()
  end
end

-- mantém a config aberta em sincronia quando algo muda (ex.: /kalts gold)
KA.bus:Register(function()
  if cfgFrame and cfgFrame:IsShown() and cfgFrame.refreshAll then cfgFrame.refreshAll() end
end)

-- ---------------------------------------------------------------------------
-- Botão de minimapa CUSTOM (sem libs) — ângulo salvo em DB
-- ---------------------------------------------------------------------------
local minimapBtn

local function UpdateMinimapPosition()
  if not minimapBtn then return end
  local db = KrononAltsDB and KrononAltsDB.minimap
  local angle = (db and db.angle) or 215
  local rad = math.rad(angle)
  local r = 80
  minimapBtn:ClearAllPoints()
  minimapBtn:SetPoint("CENTER", Minimap, "CENTER", r * math.cos(rad), r * math.sin(rad))
end

local function MinimapDragUpdate()
  local mx, my = Minimap:GetCenter()
  if not (mx and my) then return end
  local scale = Minimap:GetEffectiveScale()
  if not scale or scale == 0 then scale = 1 end
  local cx, cy = GetCursorPosition()
  cx, cy = cx / scale, cy / scale
  local atan2 = math.atan2 or math.atan
  local angle = math.deg(atan2(cy - my, cx - mx))
  if KrononAltsDB and type(KrononAltsDB.minimap) == "table" then
    KrononAltsDB.minimap.angle = angle
  end
  UpdateMinimapPosition()
end

function KA.InitMinimap()
  if minimapBtn then UpdateMinimapPosition(); return end
  if not Minimap then return end
  local db = KrononAltsDB and KrononAltsDB.minimap
  if db and db.hide then return end

  local b = CreateFrame("Button", "KrononAltsMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
  b:RegisterForClicks("LeftButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetMovable(true)

  local icon = b:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  icon:SetPoint("CENTER", b, "CENTER", -1, 1)
  b.icon = icon

  local overlay = b:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(53, 53)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)

  b:SetScript("OnClick", function()
    if KA.Toggle then KA.Toggle() end
  end)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", MinimapDragUpdate)
  end)
  b:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.MM_TITLE, ACCENT[1], ACCENT[2], ACCENT[3])
    local s = KA.GetCounts and KA.GetCounts() or nil
    if s then
      if (s.full or 0) > 0 then
        GameTooltip:AddLine(string.format(L.MM_FULL, s.full), 0.40, 0.85, 0.40)
      end
      if (s.rewards or 0) > 0 then
        GameTooltip:AddLine(string.format(L.MM_REWARDS, s.rewards), 1, 0.82, 0)
      end
    end
    -- Catalisador (Warband-wide: igual em todo char → mostrado 1x aqui)
    local cat = KA.GetCatalyst and KA.GetCatalyst() or nil
    if type(cat) == "table" and ((cat.max or 0) > 0 or (cat.quantity or 0) > 0) then
      GameTooltip:AddLine(string.format(L.MM_CATALYST, cat.quantity or 0, cat.max or 0), 0.70, 0.70, 0.80)
    end
    -- Ouro total da conta (a coluna por char é opcional/escondida)
    local okA, acc = pcall(KA.GetAccountSummary)
    if okA and type(acc) == "table" and (acc.goldCopper or 0) > 0 then
      local gtot = FormatGold(acc.goldCopper)
      if gtot then GameTooltip:AddLine(string.format(L.MM_GOLD, gtot), 0.80, 0.80, 0.62) end
    end
    GameTooltip:AddLine(L.MM_HINT, 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  minimapBtn = b
  UpdateMinimapPosition()
end
