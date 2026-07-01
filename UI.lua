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

-- Cores por tier de trilha de loot (aba Chaves): Campeão verde · Herói azul ·
-- Mítico dourado/laranja. Reusa a paleta do Alts pra ficar coerente.
local TRACK_TIER_COLOR = {
  V = { 0.62, 0.66, 0.72 }, -- Veterano (prata) — LFR
  C = { 0.20, 0.82, 0.48 }, -- Campeão (verde)
  H = { 0.20, 0.55, 1.00 }, -- Herói (azul)
  M = { 1.00, 0.65, 0.10 }, -- Mítico (dourado/laranja)
}
local function TrackName(code)
  if code == "V" then return L.TRACK_VET end
  if code == "C" then return L.TRACK_CHAMP end
  if code == "H" then return L.TRACK_HERO end
  if code == "M" then return L.TRACK_MYTH end
  return "?"
end

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

-- Design system (KA.STYLE) — leitura defensiva de um token {r,g,b,a} com fallback.
local function StyleColor(key, fb)
  local c = (KA.STYLE and KA.STYLE[key]) or fb
  return c or { 0, 0, 0, 0 }
end
-- aplica SetColorTexture numa textura a partir de um token de estilo (defensivo).
local function ApplyStyleTex(tex, key, fb)
  if not tex then return end
  local c = StyleColor(key, fb)
  tex:SetColorTexture(c[1] or 0, c[2] or 0, c[3] or 0, c[4])
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

-- Cor por faixa de rating de PvP (escala simples, independente da API de M+):
-- <1400 cinza · <1800 verde · <2100 azul · <2400 roxo · >=2400 laranja.
local function PvpRatingColor(r)
  r = r or 0
  if r >= 2400 then return { 1.00, 0.50, 0.00 } end -- laranja
  if r >= 2100 then return { 0.64, 0.21, 0.93 } end -- roxo
  if r >= 1800 then return { 0.00, 0.44, 0.87 } end -- azul
  if r >= 1400 then return { 0.12, 1.00, 0.00 } end -- verde
  return COLOR_MISSING                              -- cinza (<1400 / sem rating)
end

-- Maior rating de PvP do char (max de d.pvp.ratings[*].rating); nil se sem dado.
local function PvpBestRating(d)
  local pvp = d and d.pvp
  if type(pvp) ~= "table" or type(pvp.ratings) ~= "table" then return nil end
  local best = nil
  for _, r in ipairs(pvp.ratings) do
    if type(r) == "table" and (r.rating or 0) > 0 then
      if not best or r.rating > best then best = r.rating end
    end
  end
  return best
end

-- Conquista da semana do char: retorna earned, cap; nil se sem dado de PvP.
local function PvpConquest(d)
  local pvp = d and d.pvp
  if type(pvp) ~= "table" or type(pvp.conquest) ~= "table" then return nil end
  local c = pvp.conquest
  if (c.cap or 0) <= 0 and (c.earned or 0) <= 0 then return nil end
  return c.earned or 0, c.cap or 0
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

-- Formata um número com 1 casa decimal; usa vírgula como separador em pt/es.
local function FormatDecimal(n)
  local s = string.format("%.1f", n or 0)
  local locq = (type(GetLocale) == "function" and GetLocale()) or "enUS"
  if locq == "ptBR" or locq == "esES" or locq == "esMX" then
    s = (s:gsub("%.", ","))
  end
  return s
end

-- ilvl EQUIPADO do char logado (2º retorno de GetAverageItemLevel). Defensivo:
-- nil se a API não respondeu/valor inválido. Cai no overall se equipado vier 0.
local function PlayerEquippedIlvl()
  if type(GetAverageItemLevel) ~= "function" then return nil end
  local ok, overall, equipped = pcall(GetAverageItemLevel)
  if not ok then return nil end
  local il = equipped or overall
  if type(il) == "number" and il > 0 then return math.floor(il + 0.5) end
  return nil
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
local Refresh   -- forward
local ApplyView -- forward (alterna a view Personagens ↔ Chaves)

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

  -- divisória fina no rodapé da linha (design system) — só visual
  row.divider = row:CreateTexture(nil, "BORDER")
  row.divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
  row.divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
  row.divider:SetHeight(1)
  ApplyStyleTex(row.divider, "divider", { 1, 1, 1, 0.07 })

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
    if KA.GetMode() == "pvp" then
      -- modo PvP: o hover mostra rating por modalidade + Conquista + honra (espelha a coluna/detalhe)
      local pvp = d.pvp
      if type(pvp) == "table" then
        if type(pvp.ratings) == "table" then
          for _, r in ipairs(pvp.ratings) do
            if (r.rating or 0) > 0 then
              local col = RatingColor(r.rating)
              GameTooltip:AddLine((L[r.key] or r.key or "?") .. ": " .. r.rating, col[1], col[2], col[3])
            end
          end
        end
        if type(pvp.conquest) == "table" and ((pvp.conquest.cap or 0) > 0 or (pvp.conquest.earned or 0) > 0) then
          local cap, earned = pvp.conquest.cap or 0, pvp.conquest.earned or 0
          GameTooltip:AddLine(L.WEEKLY_CONQUEST .. ": " .. earned .. (cap > 0 and ("/" .. cap) or ""), 0.7, 0.7, 0.7)
        end
        if type(pvp.honorLevel) == "number" and pvp.honorLevel > 0 then
          GameTooltip:AddLine(L.PVP_HONOR .. ": " .. pvp.honorLevel, 0.7, 0.7, 0.7)
        end
      end
    else
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

  -- modo ativo: no modo PvP a LINHA RECOLHIDA troca 2 colunas (M+→Rating, Crest→
  -- Conquista). Em "pve"/"both" as colunas ficam exatamente como antes.
  local mode = (KA.GetMode and KA.GetMode()) or "pve"

  -- fundo / acento
  if entry.isCurrent then
    row.bg:SetColorTexture(ACCENT_BLUE[1], ACCENT_BLUE[2], ACCENT_BLUE[3], 0.10)
    row.accent:SetColorTexture(ACCENT_BLUE[1], ACCENT_BLUE[2], ACCENT_BLUE[3], 1); row.accent:Show()
  elseif hasRewards then
    row.bg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.12)
    row.accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1); row.accent:Show()
  elseif index % 2 == 0 then
    ApplyStyleTex(row.bg, "bgRow", { 0, 0, 0, 0.16 }); row.accent:Hide() -- zebra
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

  -- COLUNA "mplus": no modo PvP mostra o MAIOR rating de PvP do char (colorido pela
  -- faixa de PvP); nos outros modos, o "+N" da chave de M+ fundido com o rating.
  if mode == "pvp" then
    local best = PvpBestRating(d)
    if best and best > 0 then
      row.cells.mplus:SetText(colored(PvpRatingColor(best), tostring(best)))
    else
      row.cells.mplus:SetText(colored(COLOR_MISSING, L.NONE))
    end
  else
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

  -- COLUNA "crest": no modo PvP vira a CONQUISTA da semana (earned/cap, ✓ no cap);
  -- nos outros modos, o indicador de cap semanal de crest.
  if mode == "pvp" then
    local earned, cap = PvpConquest(d)
    if earned ~= nil then
      if (cap or 0) > 0 and earned >= cap then
        row.cells.crest:SetText(CHECK_ICON)
      else
        row.cells.crest:SetText(colored(COLOR_NEUTRAL, earned .. ((cap or 0) > 0 and ("/" .. cap) or "")))
      end
    else
      row.cells.crest:SetText(colored(COLOR_MISSING, L.NONE))
    end
  else
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
  -- no modo PvP os cabeçalhos "mplus"/"crest" viram Rating/Conquista (a coluna passa
  -- a mostrar dados de PvP na linha recolhida). A seta de ordenação segue h.sortKey.
  local mode = (KA.GetMode and KA.GetMode()) or "pve"
  for key, h in pairs(frame.headers) do
    local label = h.baseLabel or key
    if mode == "pvp" then
      if key == "mplus" then label = L.COL_RATING
      elseif key == "crest" then label = L.COL_CONQUEST end
    end
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

-- ===========================================================================
-- VIEW "CHAVES" — tabela de recompensas de Mítica+ por nível de chave (estática,
-- dados em KA.KEY_REWARDS). Frame filho do frame principal; alterna com a tabela
-- de personagens via ApplyView. Sem dependência de API (só o ilvl do char p/ as
-- marcações de upgrade, lido defensivamente).
-- ===========================================================================
local KEY_ROW_H = 26
local KEY_COL   = { key = 8,  endc = 82,  vault = 244, crest = 408 } -- offsets rel. à linha
local KEY_COL_W = { key = 50, endc = 156, vault = 158, crest = 150 }

-- Célula "ilvl + trilha + rank" colorida por tier; ✓ quando é upgrade pro char.
local function keyCell(ilvl, tcode, rank, isUp)
  local col = TRACK_TIER_COLOR[tcode] or COLOR_NEUTRAL
  local s = colored(col, string.format("%d  %s %s", ilvl, TrackName(tcode), rank))
  if isUp then s = s .. "  " .. CHECK_ICON end
  return s
end

-- ===========================================================================
-- COACH DE PROGRESSÃO ("O que fazer agora") — helpers da 3ª aba "Progresso".
-- Lê o gear equipado + brasões (C_CurrencyInfo) + favoritos BiS do KeystoneLoot
-- (integração OPCIONAL) e gera 3 sugestões acionáveis. 100% defensivo: sem
-- KeystoneLoot a trilha do gear vem do fallback KA.UPGRADE_BONUS e a sugestão de
-- BiS degrada com uma dica; nada lança erro. A view fica em BuildCoachView.
-- ===========================================================================
-- Slots equipados varridos: cabeça(1)..mão secundária(17); pula camisa(4) e tabardo(19).
local COACH_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }

-- Mapa trilha (dungeon) -> código de tier do Alts (C/H/M) + currencyID do brasão.
-- Os IDs dos Dawncrest são os mesmos do bloco SEASON_CURRENCIES do Core.lua.
local COACH_TRACKS = {
  { kl = "champion",   code = "C", crestId = 3343 }, -- Champion Dawncrest
  { kl = "hero",       code = "H", crestId = 3345 }, -- Hero Dawncrest
  { kl = "greatvault", code = "M", crestId = 3347 }, -- Myth Dawncrest
}

-- Ícones das sugestões (escapes de textura; caminho inválido só mostra placeholder,
-- nunca lança erro Lua). Trocáveis facilmente in-game se algum não renderizar.
local COACH_ICON_SPEND = "|TInterface\\Icons\\inv_misc_coin_01:14:14:0:0|t"
local COACH_ICON_KEY   = "|TInterface\\Icons\\inv_misc_key_03:14:14:0:0|t"
local COACH_ICON_BIS   = "|TInterface\\Icons\\inv_misc_gem_diamond_03:14:14:0:0|t"
-- ícone de aviso (X vermelho nativo; conhecido-bom) p/ o alerta de cap de brasão
local COACH_ICON_WARN  = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t"

-- Mapa código de tier (C/H/M) → chave das tabelas KA.TRACK_* (champion/hero/myth).
local CODE_TO_TRACK = { C = "champion", H = "hero", M = "myth" }

-- Ordem das trilhas (Campeão < Herói < Mítico); 0 p/ desconhecido.
local function TrackOrder(code)
  if code == "M" then return 3 end
  if code == "H" then return 2 end
  if code == "C" then return 1 end
  return 0
end

-- Globais de nome de slot do cliente (já localizadas) por INVSLOT.
local COACH_SLOT_GLOBAL = {
  [1] = "HEADSLOT", [2] = "NECKSLOT", [3] = "SHOULDERSLOT", [5] = "CHESTSLOT",
  [6] = "WAISTSLOT", [7] = "LEGSSLOT", [8] = "FEETSLOT", [9] = "WRISTSLOT",
  [10] = "HANDSSLOT", [11] = "FINGER0SLOT", [12] = "FINGER1SLOT",
  [13] = "TRINKET0SLOT", [14] = "TRINKET1SLOT", [15] = "BACKSLOT",
  [16] = "MAINHANDSLOT", [17] = "SECONDARYHANDSLOT",
}
-- Nome localizado do slot (via global do WoW); fallback p/ o número do slot.
local function SlotName(slot)
  local g = COACH_SLOT_GLOBAL[slot]
  local s = g and rawget(_G, g)
  if type(s) == "string" and s ~= "" then return s end
  return tostring(slot)
end

-- KeystoneLoot NÃO expõe a tabela do addon como global na build atual (vem do
-- vararg `local _, KeystoneLoot = ...`, privada). Buscamos via rawget p/ acender a
-- integração automaticamente caso uma versão futura a exponha; senão, degrada.
local function KLAddon()
  local kl = rawget(_G, "KeystoneLoot")
  if type(kl) == "table" then return kl end
  return nil
end

-- split por ":" preservando campos vazios (p/ parse robusto de itemLink).
local function SplitColon(s)
  local t, last = {}, 1
  while true do
    local i = string.find(s, ":", last, true)
    if not i then t[#t + 1] = string.sub(s, last); break end
    t[#t + 1] = string.sub(s, last, i - 1)
    last = i + 1
  end
  return t
end

-- Extrai os bonusIds de um itemLink. Layout do item:
--   item:itemId:ench:g1:g2:g3:g4:suffix:uniq:lvl:spec:mask:ctx:numBonus:b1:b2:...
-- f[1]=itemId ... f[13]=numBonusIDs ... f[14..]=bonusIDs. Defensivo: nil se não casar.
local function ExtractBonusIds(itemLink)
  if type(itemLink) ~= "string" then return nil end
  local body = string.match(itemLink, "|Hitem:([%-%d:]+)|h")
    or string.match(itemLink, "item:([%-%d:]+)")
  if not body then return nil end
  local f = SplitColon(body)
  local num = tonumber(f[13])
  if not num or num <= 0 then return nil end
  local ids = {}
  for i = 1, num do
    local b = tonumber(f[13 + i])
    if b then ids[#ids + 1] = b end
  end
  if #ids == 0 then return nil end
  return ids
end

-- Lookup bonusId -> { code, rank, maxRank, ilvl }. Prefere a tabela viva do
-- KeystoneLoot; senão usa o fallback hardcoded KA.UPGRADE_BONUS (Core.lua).
local function BuildTrackLookup()
  local kl = KLAddon()
  if kl and type(kl.UpgradeTracks) == "table" and type(kl.UpgradeTracks.dungeon) == "table" then
    local dn = kl.UpgradeTracks.dungeon
    local lk, any = {}, false
    for _, t in ipairs(COACH_TRACKS) do
      local list = dn[t.kl]
      if type(list) == "table" then
        local maxRank = #list
        for rank, entry in ipairs(list) do
          local b = (type(entry) == "table") and tonumber(entry.bonusId) or nil
          if b then
            lk[b] = { code = t.code, rank = rank, maxRank = maxRank, ilvl = entry.ilvl }
            any = true
          end
        end
      end
    end
    if any then return lk end
  end
  if type(KA.UPGRADE_BONUS) == "table" then return KA.UPGRADE_BONUS end
  return nil
end

-- Uma peça `a` é mais FRACA que `b`? Ordem: menor track, depois menor rank, depois
-- menor ilvl. Usado p/ o diagnóstico "elo mais fraco" (onde focar primeiro).
local function WeakerPiece(a, b)
  if not b then return true end
  local oa, ob = TrackOrder(a.code), TrackOrder(b.code)
  if oa ~= ob then return oa < ob end
  if (a.rank or 0) ~= (b.rank or 0) then return (a.rank or 0) < (b.rank or 0) end
  return (a.ilvl or 0) < (b.ilvl or 0)
end

-- Varre o gear equipado e agrega contagem por trilha + peças abaixo do máximo +
-- guarda a peça mais fraca (res.weak = { slot, code, rank, maxRank, ilvl }).
local function ScanGear(lookup)
  local res = {
    counts  = { C = 0, H = 0, M = 0 },
    notMax  = { C = 0, H = 0, M = 0 },
    missing = { C = 0, H = 0, M = 0 }, -- soma de (maxRank-rank) das peças não-maxadas
    pieces = 0, tracked = 0, weak = nil,
  }
  if type(GetInventoryItemLink) ~= "function" then return res end
  for _, slot in ipairs(COACH_SLOTS) do
    local ok, link = pcall(GetInventoryItemLink, "player", slot)
    if ok and type(link) == "string" then
      res.pieces = res.pieces + 1
      if lookup then
        local ids = ExtractBonusIds(link)
        local m
        if ids then
          for _, b in ipairs(ids) do
            if lookup[b] then m = lookup[b]; break end
          end
        end
        if m and m.code then
          res.tracked = res.tracked + 1
          res.counts[m.code] = (res.counts[m.code] or 0) + 1
          if (m.rank or 0) < (m.maxRank or 0) then
            res.notMax[m.code] = (res.notMax[m.code] or 0) + 1
            res.missing[m.code] = (res.missing[m.code] or 0) + ((m.maxRank or 0) - (m.rank or 0)) -- níveis faltantes (× perRank = brasões pra maxar)
          end
          local cand = { slot = slot, code = m.code, rank = m.rank or 0,
                         maxRank = m.maxRank or 6, ilvl = m.ilvl or 0 }
          if WeakerPiece(cand, res.weak) then res.weak = cand end
        end
      end
    end
  end
  return res
end

-- Mapa { [itemID] = código de trilha (C/H/M) } do gear EQUIPADO (guarda a MAIOR
-- trilha por itemID, p/ anéis/berloques duplicados). Usado pela tabela de prioridade
-- p/ marcar favoritos que você JÁ tem — Mítico = "done". Defensivo: sem API → vazio.
local function EquippedTracks(lookup)
  local out = {}
  if type(GetInventoryItemLink) ~= "function" or not lookup then return out end
  local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if type(instant) ~= "function" then return out end
  for _, slot in ipairs(COACH_SLOTS) do
    local ok, link = pcall(GetInventoryItemLink, "player", slot)
    if ok and type(link) == "string" then
      local okI, itemId = pcall(instant, link)
      if okI and type(itemId) == "number" then
        local ids = ExtractBonusIds(link)
        local code
        if ids then
          for _, b in ipairs(ids) do
            if lookup[b] then code = lookup[b].code; break end
          end
        end
        if code then
          local prev = out[itemId]
          if not prev or TrackOrder(code) > TrackOrder(prev) then out[itemId] = code end
        end
      end
    end
  end
  return out
end

-- Info de um brasão (currencyID): quantidade total + progresso do cap SEMANAL.
-- Os nomes de campo podem variar entre builds; lidos defensivamente. O cap semanal
-- tem CATCH-UP (acumula), então usa-se o maxWeeklyQuantity REAL da API, não 100 fixo.
local function CrestInfo(id)
  if type(id) ~= "number" then return nil end
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
  local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
  if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
    local weekly    = tonumber(info.quantityEarnedThisWeek)
    local weeklyMax = tonumber(info.maxWeeklyQuantity)
    return {
      qty       = tonumber(info.quantity) or 0,
      weekly    = weekly,
      weeklyMax = (weeklyMax and weeklyMax > 0) and weeklyMax or nil,
    }
  end
  return nil
end

-- specId da spec ATUAL do char. Espelha como o KeystoneLoot resolve a spec
-- (C_SpecializationInfo), com fallback p/ as globais antigas. nil se indisponível.
local function CurrentSpecId()
  local C = C_SpecializationInfo
  if type(C) == "table" and type(C.GetSpecialization) == "function"
     and type(C.GetSpecializationInfo) == "function" then
    local ok, idx = pcall(C.GetSpecialization)
    if ok and type(idx) == "number" then
      local ok2, specId = pcall(C.GetSpecializationInfo, idx)
      if ok2 and type(specId) == "number" and specId > 0 then return specId end
    end
  end
  if type(GetSpecialization) == "function" and type(GetSpecializationInfo) == "function" then
    local ok, idx = pcall(GetSpecialization)
    if ok and type(idx) == "number" then
      local ok2, specId = pcall(GetSpecializationInfo, idx)
      if ok2 and type(specId) == "number" and specId > 0 then return specId end
    end
  end
  return nil
end

-- characterKey EXATAMENTE como o KeystoneLoot (character.lua): "realm-nome-classId",
-- classId = select(3, UnitClass("player")). Usa o char ATUAL (logado). nil se faltar API.
local function KLCharacterKey()
  if type(GetRealmName) ~= "function" or type(UnitName) ~= "function"
     or type(UnitClass) ~= "function" then return nil end
  local ok1, realm = pcall(GetRealmName)
  local ok2, name  = pcall(UnitName, "player")
  local ok3, _, _, classId = pcall(UnitClass, "player")
  if ok1 and ok2 and ok3 and type(realm) == "string" and realm ~= ""
     and type(name) == "string" and name ~= "" and type(classId) == "number" then
    return string.format("%s-%s-%d", realm, name, classId)
  end
  return nil
end

-- Nome localizado da dungeon (challengeModeId). nil se indisponível.
local function DungeonName(cmId)
  if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
    local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, cmId)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  return nil
end

-- Ícone da dungeon (4º retorno de GetMapUIInfo: texture). nil se indisponível.
local function DungeonIcon(cmId)
  if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
    local ok, _, _, _, texture = pcall(C_ChallengeMode.GetMapUIInfo, cmId)
    if ok and texture then return texture end
  end
  return nil
end

-- Banner de fundo da dungeon: usa o fileID hardcoded (KA.DUNGEON_BG, igual ao
-- KeystoneLoot); senão a texture do GetMapUIInfo (ícone). nil = sem banner.
local function DungeonBanner(cmId)
  local map = KA.DUNGEON_BG
  if type(map) == "table" and cmId and map[cmId] then return map[cmId] end
  return DungeonIcon(cmId)
end

-- Ícone (fileID) de um item — via GetItemInfoInstant (SÍNCRONO, sem cache). Fallback
-- p/ o ponto de interrogação. Não precisa de async (só a qualidade/nome precisam).
local function ItemIcon(itemId)
  local gi = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if type(gi) == "function" then
    local ok, _, _, _, _, icon = pcall(gi, itemId)
    if ok and icon then return icon end
  end
  return 134400 -- Interface\Icons\INV_Misc_QuestionMark
end

-- Cor de qualidade de item (tabela {r,g,b}). Fallback neutro.
local function QualityColor(q)
  if type(q) ~= "number" then return COLOR_NEUTRAL end
  if C_Item and C_Item.GetItemQualityColor then
    local ok, r, g, b = pcall(C_Item.GetItemQualityColor, q)
    if ok and type(r) == "number" then return { r, g, b } end
  end
  if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] and ITEM_QUALITY_COLORS[q].r then
    local c = ITEM_QUALITY_COLORS[q]
    return { c.r, c.g, c.b }
  end
  return COLOR_NEUTRAL
end

-- Nome do item + cor de qualidade. Se ainda não cacheado, pede o carregamento
-- (aparece no próximo refresh, disparado por ITEM_DATA_LOAD_RESULT) e retorna nil.
local function ItemName(itemId)
  if type(itemId) ~= "number" then return nil end
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if type(getInfo) == "function" then
    local ok, name, _, quality = pcall(getInfo, itemId)
    if ok and type(name) == "string" and name ~= "" then
      return name, QualityColor(quality)
    end
  end
  if C_Item and C_Item.RequestLoadItemDataByID then
    pcall(C_Item.RequestLoadItemDataByID, itemId)
  end
  return nil
end

-- LISTA de dungeons priorizadas pelos favoritos da spec atual, p/ a mini-tabela.
-- Prioriza BiS (tier 3); se NÃO houver nenhum BiS em dungeon alguma, faz FALLBACK
-- pra "essenciais" (tier 2 = Must have). Retorna (rows, tierUsed):
--   rows = { { sourceId, name, count, items = { itemId, ... } }, ... } ordenado por
--   count DESC (desempate por nome); tierUsed = 3 (BiS) ou 2 (essenciais). nil = degrada.
-- Caminho PRINCIPAL: SavedVariable GLOBAL `KeystoneLootDB.favorites`. sourceId de
-- dungeon = challengeModeId (tem nome via GetMapUIInfo); raid/catalyst/custom são
-- PULADOS. Fallback secundário: namespace privado, se uma build futura o expuser.
local function BisDungeonPriority(specId, equipped)
  if not specId then return nil end

  local rows3, rows2 = {}, {}

  -- 1) SavedVariable global (caminho principal)
  local db = rawget(_G, "KeystoneLootDB")
  local handled = false
  if type(db) == "table" and type(db.favorites) == "table" then
    local key  = KLCharacterKey()
    local favs = key and db.favorites[key] or nil
    if type(favs) == "table" then
      handled = true
      for sourceId, specMap in pairs(favs) do
        if type(specMap) == "table" and type(specMap[specId]) == "table" then
          local name = DungeonName(sourceId)
          if name then
            local i3, i2 = {}, {}
            for itemId, info in pairs(specMap[specId]) do
              local id = tonumber(itemId)
              if id and type(info) == "table" then
                if info.tier == 3 then i3[#i3 + 1] = id
                elseif info.tier == 2 then i2[#i2 + 1] = id end
              end
            end
            if #i3 > 0 then rows3[#rows3 + 1] = { sourceId = sourceId, name = name, items = i3 } end
            if #i2 > 0 then rows2[#rows2 + 1] = { sourceId = sourceId, name = name, items = i2 } end
          end
        end
      end
    end
  end

  -- 2) Fallback: namespace privado (só se exposto por uma versão futura)
  if not handled then
    local kl = KLAddon()
    if kl and type(kl.Favorites) == "table" and type(kl.DungeonDatabase) == "table"
       and type(kl.Favorites.GetList) == "function" and type(kl.Favorites.GetTier) == "function" then
      local Fav = kl.Favorites
      for _, dungeon in ipairs(kl.DungeonDatabase) do
        local cmId = (type(dungeon) == "table") and dungeon.challengeModeId or nil
        if cmId then
          local name = DungeonName(cmId)
          if name then
            local i3, i2 = {}, {}
            local ok, list = pcall(Fav.GetList, Fav, cmId, specId)
            if ok and type(list) == "table" then
              for _, entry in ipairs(list) do
                local id = (type(entry) == "table") and tonumber(entry.itemId) or nil
                if id then
                  local ok2, tier = pcall(Fav.GetTier, Fav, id, specId)
                  if ok2 and tier == 3 then i3[#i3 + 1] = id
                  elseif ok2 and tier == 2 then i2[#i2 + 1] = id end
                end
              end
            end
            if #i3 > 0 then rows3[#rows3 + 1] = { sourceId = cmId, name = name, items = i3 } end
            if #i2 > 0 then rows2[#rows2 + 1] = { sourceId = cmId, name = name, items = i2 } end
          end
        end
      end
    end
  end

  -- escolhe BiS se houver qualquer; senão essenciais (tier 2)
  local rows, tier
  if #rows3 > 0 then rows, tier = rows3, 3
  elseif #rows2 > 0 then rows, tier = rows2, 2
  else return nil end

  for _, r in ipairs(rows) do
    r.count = #r.items
    -- "needed" = favoritos que você ainda NÃO tem no Mítico (os no Mítico = done,
    -- saem da contagem → a dungeon desce na prioridade)
    local needed = r.count
    if equipped then
      needed = 0
      for _, id in ipairs(r.items) do
        if equipped[id] ~= "M" then needed = needed + 1 end
      end
    end
    r.needed = needed
  end
  table.sort(rows, function(a, b)
    if a.needed ~= b.needed then return a.needed > b.needed end -- mais a farmar primeiro
    if a.count ~= b.count then return a.count > b.count end
    return (a.name or "") < (b.name or "") -- desempate estável por nome
  end)
  return rows, tier
end

-- Monta "N Campeão  ·  N Herói  ·  N Mítico" colorindo cada token pela trilha.
-- includeZero=true mantém tracks com valor 0 (usado na linha de brasões).
local function TrackBreakdown(getN, includeZero)
  local parts = {}
  for _, t in ipairs(COACH_TRACKS) do
    local n = getN(t.code)
    if type(n) == "number" and (n > 0 or includeZero) then
      local col = TRACK_TIER_COLOR[t.code] or COLOR_NEUTRAL
      parts[#parts + 1] = colored(col, n .. " " .. TrackName(t.code))
    end
  end
  return table.concat(parts, "  \194\183  ")
end

-- Trilha PREDOMINANTE do gear (mais peças). Empate: a MENOR trilha (pra mirar mais
-- alto). nil se nenhuma peça rastreada.
local function PredominantTrack(gear)
  local best, bestN
  for _, code in ipairs({ "C", "H", "M" }) do -- ordem crescente → empate fica no menor
    local n = (gear and gear.counts and gear.counts[code]) or 0
    if n > 0 and (not bestN or n > bestN) then bestN = n; best = code end
  end
  return best
end

local function BuildKeysView(parent)
  local kv = CreateFrame("Frame", nil, parent)
  kv:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -(TOP_TITLE + 1))
  kv:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1, 1)
  kv:Hide()

  -- título (esquerda) + ilvl do char (direita)
  local title = kv:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", kv, "TOPLEFT", 16, -12)
  title:SetText(L.KEYS_TITLE)
  title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

  local ilvlFS = kv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ilvlFS:SetPoint("TOPRIGHT", kv, "TOPRIGHT", -16, -14)
  ilvlFS:SetJustifyH("RIGHT"); ilvlFS:SetWordWrap(false)
  kv.ilvlFS = ilvlFS

  -- guia (texto curto derivado do ilvl)
  local guide = kv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  guide:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  guide:SetPoint("RIGHT", kv, "RIGHT", -16, 0)
  guide:SetJustifyH("LEFT"); guide:SetWordWrap(false)
  guide:SetTextColor(COLOR_NEUTRAL[1], COLOR_NEUTRAL[2], COLOR_NEUTRAL[3])
  kv.guide = guide

  -- cabeçalho de colunas
  local headerBar = CreateFrame("Frame", nil, kv)
  headerBar:SetPoint("TOPLEFT", guide, "BOTTOMLEFT", -8, -8)
  headerBar:SetPoint("RIGHT", kv, "RIGHT", -8, 0)
  headerBar:SetHeight(TOP_HEADER)
  local hbbg = headerBar:CreateTexture(nil, "BACKGROUND")
  hbbg:SetAllPoints(); hbbg:SetColorTexture(0, 0, 0, 0.30)
  local function colHeader(off, w, justify, text)
    local fs = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", headerBar, "LEFT", off, 0)
    fs:SetWidth(w); fs:SetJustifyH(justify); fs:SetWordWrap(false)
    fs:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
    fs:SetText(text)
  end
  colHeader(KEY_COL.key,   KEY_COL_W.key,   "CENTER", L.KEYS_COL_KEY)
  colHeader(KEY_COL.endc,  KEY_COL_W.endc,  "LEFT",   L.KEYS_COL_END)
  colHeader(KEY_COL.vault, KEY_COL_W.vault, "LEFT",   L.KEYS_COL_VAULT)
  colHeader(KEY_COL.crest, KEY_COL_W.crest, "LEFT",   L.KEYS_COL_CREST)

  -- linhas estáticas (1 por nível de chave) — texto preenchido em kv.refresh
  kv.rows = {}
  local data = KA.KEY_REWARDS or {}
  for i = 1, #data do
    local r = CreateFrame("Frame", nil, kv)
    r:SetHeight(KEY_ROW_H)
    r:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -((i - 1) * KEY_ROW_H))
    r:SetPoint("RIGHT", headerBar, "RIGHT", 0, 0)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    -- divisória fina (design system) — só visual
    r.divider = r:CreateTexture(nil, "BORDER")
    r.divider:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 4, 0)
    r.divider:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -4, 0)
    r.divider:SetHeight(1)
    ApplyStyleTex(r.divider, "divider", { 1, 1, 1, 0.07 })
    r.accent = r:CreateTexture(nil, "ARTWORK")
    r.accent:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.accent:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    r.accent:SetWidth(3); r.accent:Hide()
    local function cell(off, w, justify)
      local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetPoint("LEFT", r, "LEFT", off, 0)
      fs:SetWidth(w); fs:SetJustifyH(justify); fs:SetJustifyV("MIDDLE")
      fs:SetWordWrap(false)
      return fs
    end
    r.cKey   = cell(KEY_COL.key,   KEY_COL_W.key,   "CENTER")
    r.cEnd   = cell(KEY_COL.endc,  KEY_COL_W.endc,  "LEFT")
    r.cVault = cell(KEY_COL.vault, KEY_COL_W.vault, "LEFT")
    r.cCrest = cell(KEY_COL.crest, KEY_COL_W.crest, "LEFT")
    kv.rows[i] = r
  end

  -- rodapé: custo de upgrade + dica derivada da linha de maior chave
  local foot1 = kv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  foot1:SetPoint("BOTTOMLEFT", kv, "BOTTOMLEFT", 16, 26)
  foot1:SetPoint("RIGHT", kv, "RIGHT", -16, 0)
  foot1:SetJustifyH("LEFT"); foot1:SetWordWrap(true)
  foot1:SetTextColor(COLOR_NEUTRAL[1], COLOR_NEUTRAL[2], COLOR_NEUTRAL[3])
  kv.foot1 = foot1
  local foot2 = kv:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  foot2:SetPoint("BOTTOMLEFT", kv, "BOTTOMLEFT", 16, 8)
  foot2:SetPoint("RIGHT", kv, "RIGHT", -16, 0)
  foot2:SetJustifyH("LEFT"); foot2:SetWordWrap(false)
  kv.foot2 = foot2

  -- (re)preenche tudo o que depende do char logado (ilvl) — chamado ao abrir a
  -- view e quando o bus dispara (snapshot novo pode mudar o ilvl equipado).
  kv.refresh = function()
    local ilvl = PlayerEquippedIlvl()

    -- cabeçalho: "Seu ilvl: X" (ou — se indisponível)
    if ilvl then
      kv.ilvlFS:SetText(colored(COLOR_NEUTRAL, string.format(L.KEYS_YOUR_ILVL, ilvl)))
    else
      local lbl = (L.KEYS_YOUR_ILVL:gsub("%%d", "%%s"))
      kv.ilvlFS:SetText(colored(COLOR_MISSING, string.format(lbl, L.NONE)))
    end

    -- guia: a partir de qual chave Fim/Cofre viram upgrade pro char
    if not ilvl then
      kv.guide:SetText(L.KEYS_GUIDE_NONE)
    else
      local x, y
      for _, dRow in ipairs(data) do
        if not y and dRow.vaultI > ilvl then y = dRow.key end
        if not x and dRow.endI > ilvl then x = dRow.key end
      end
      if x then
        kv.guide:SetText(string.format(L.KEYS_GUIDE, x, y or x))
      else
        kv.guide:SetText(L.KEYS_GUIDE_CAP)
      end
    end

    -- linhas
    for i, dRow in ipairs(data) do
      local r = kv.rows[i]
      if r then
        local prev = data[i - 1]
        local crestJump = prev and (prev.crestT ~= dRow.crestT) or false
        local vaultJump = prev and (prev.vaultT ~= dRow.vaultT) or false
        local isJump = crestJump or vaultJump

        -- fundo: alterna (zebra do design system); realça as linhas de "salto" de tier
        if isJump then
          r.bg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.07)
        elseif i % 2 == 0 then
          ApplyStyleTex(r.bg, "bgRow", { 0, 0, 0, 0.16 })
        else
          r.bg:SetColorTexture(0, 0, 0, 0)
        end
        -- acento à esquerda na cor do NOVO tier (brasão tem prioridade; senão cofre)
        if isJump then
          local jc = TRACK_TIER_COLOR[(crestJump and dRow.crestT) or dRow.vaultT] or COLOR_NEUTRAL
          r.accent:SetColorTexture(jc[1], jc[2], jc[3], 1); r.accent:Show()
        else
          r.accent:Hide()
        end

        r.cKey:SetText(colored(COLOR_NEUTRAL, "+" .. dRow.key))
        r.cEnd:SetText(keyCell(dRow.endI, dRow.endT, dRow.endR, ilvl and dRow.endI > ilvl))
        r.cVault:SetText(keyCell(dRow.vaultI, dRow.vaultT, dRow.vaultR, ilvl and dRow.vaultI > ilvl))
        r.cCrest:SetText(colored(TRACK_TIER_COLOR[dRow.crestT] or COLOR_NEUTRAL,
          dRow.crest .. " " .. TrackName(dRow.crestT)))
        r:Show()
      end
    end

    -- rodapé
    local uc = KA.UPGRADE_COST or { perRank = 20, perItem = 120, weeklyCap = 100 }
    kv.foot1:SetText(string.format(L.KEYS_UPGRADE_COST,
      uc.perRank or 20, uc.perItem or 120, uc.weeklyCap or 100))
    local tipRow = data[#data]
    if tipRow and (uc.perRank or 0) > 0 then
      local ratio = tipRow.crest / uc.perRank
      kv.foot2:SetText(colored(TRACK_TIER_COLOR[tipRow.crestT] or COLOR_NEUTRAL,
        string.format(L.KEYS_UPGRADE_TIP, tipRow.key, tipRow.crest,
          TrackName(tipRow.crestT), FormatDecimal(ratio))))
    else
      kv.foot2:SetText("")
    end
  end

  return kv
end

-- ===========================================================================
-- VIEW "RAIDS" — tabela de recompensas de raid por DIFICULDADE (dados em
-- KA.RAID_REWARDS). Mesma cara/colunas da aba Chaves; alterna via ApplyView.
-- ===========================================================================
local RAID_COL   = { diff = 8,  drop = 92,  vault = 250, crest = 408 }
local RAID_COL_W = { diff = 80, drop = 154, vault = 154, crest = 150 }

-- Célula "faixa de ilvl + trilha" colorida por tier; ✓ quando o topo é upgrade.
local function raidDropCell(lo, hi, tcode, isUp)
  local col = TRACK_TIER_COLOR[tcode] or COLOR_NEUTRAL
  local s = colored(col, string.format("%d\226\128\147%d  %s", lo, hi, TrackName(tcode)))
  if isUp then s = s .. "  " .. CHECK_ICON end
  return s
end

-- Célula "ilvl + trilha" (Cofre); ✓ quando é upgrade pro char.
local function raidVaultCell(ival, tcode, isUp)
  local col = TRACK_TIER_COLOR[tcode] or COLOR_NEUTRAL
  local s = colored(col, string.format("%d  %s", ival, TrackName(tcode)))
  if isUp then s = s .. "  " .. CHECK_ICON end
  return s
end

local function BuildRaidsView(parent)
  local rv = CreateFrame("Frame", nil, parent)
  rv:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -(TOP_TITLE + 1))
  rv:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1, 1)
  rv:Hide()

  -- título (esquerda) + ilvl do char (direita)
  local title = rv:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", rv, "TOPLEFT", 16, -12)
  title:SetText(L.RAIDS_TITLE)
  title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

  local ilvlFS = rv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ilvlFS:SetPoint("TOPRIGHT", rv, "TOPRIGHT", -16, -14)
  ilvlFS:SetJustifyH("RIGHT"); ilvlFS:SetWordWrap(false)
  rv.ilvlFS = ilvlFS

  -- cabeçalho de colunas
  local headerBar = CreateFrame("Frame", nil, rv)
  headerBar:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -8, -12)
  headerBar:SetPoint("RIGHT", rv, "RIGHT", -8, 0)
  headerBar:SetHeight(TOP_HEADER)
  local hbbg = headerBar:CreateTexture(nil, "BACKGROUND")
  hbbg:SetAllPoints(); hbbg:SetColorTexture(0, 0, 0, 0.30)
  local function colHeader(off, w, justify, text)
    local fs = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", headerBar, "LEFT", off, 0)
    fs:SetWidth(w); fs:SetJustifyH(justify); fs:SetWordWrap(false)
    fs:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
    fs:SetText(text)
  end
  colHeader(RAID_COL.diff,  RAID_COL_W.diff,  "LEFT", L.RAIDS_COL_DIFF)
  colHeader(RAID_COL.drop,  RAID_COL_W.drop,  "LEFT", L.RAIDS_COL_DROP)
  colHeader(RAID_COL.vault, RAID_COL_W.vault, "LEFT", L.KEYS_COL_VAULT)
  colHeader(RAID_COL.crest, RAID_COL_W.crest, "LEFT", L.KEYS_COL_CREST)

  -- linhas estáticas (1 por dificuldade)
  rv.rows = {}
  local data = KA.RAID_REWARDS or {}
  for i = 1, #data do
    local r = CreateFrame("Frame", nil, rv)
    r:SetHeight(KEY_ROW_H)
    r:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -((i - 1) * KEY_ROW_H))
    r:SetPoint("RIGHT", headerBar, "RIGHT", 0, 0)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.divider = r:CreateTexture(nil, "BORDER")
    r.divider:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 4, 0)
    r.divider:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -4, 0)
    r.divider:SetHeight(1)
    ApplyStyleTex(r.divider, "divider", { 1, 1, 1, 0.07 })
    r.accent = r:CreateTexture(nil, "ARTWORK")
    r.accent:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.accent:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    r.accent:SetWidth(3); r.accent:Hide()
    local function cell(off, w, justify)
      local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      fs:SetPoint("LEFT", r, "LEFT", off, 0)
      fs:SetWidth(w); fs:SetJustifyH(justify); fs:SetJustifyV("MIDDLE")
      fs:SetWordWrap(false)
      return fs
    end
    r.cDiff  = cell(RAID_COL.diff,  RAID_COL_W.diff,  "LEFT")
    r.cDrop  = cell(RAID_COL.drop,  RAID_COL_W.drop,  "LEFT")
    r.cVault = cell(RAID_COL.vault, RAID_COL_W.vault, "LEFT")
    r.cCrest = cell(RAID_COL.crest, RAID_COL_W.crest, "LEFT")
    rv.rows[i] = r
  end

  -- nota de rodapé
  local note = rv:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  note:SetPoint("BOTTOMLEFT", rv, "BOTTOMLEFT", 16, 12)
  note:SetPoint("RIGHT", rv, "RIGHT", -16, 0)
  note:SetJustifyH("LEFT"); note:SetWordWrap(true)
  note:SetText(L.RAIDS_NOTE)
  rv.note = note

  -- (re)preenche o que depende do char logado (ilvl p/ marcar upgrades).
  rv.refresh = function()
    local ilvl = PlayerEquippedIlvl()
    if ilvl then
      rv.ilvlFS:SetText(colored(COLOR_NEUTRAL, string.format(L.KEYS_YOUR_ILVL, ilvl)))
    else
      local lbl = (L.KEYS_YOUR_ILVL:gsub("%%d", "%%s"))
      rv.ilvlFS:SetText(colored(COLOR_MISSING, string.format(lbl, L.NONE)))
    end

    for i, dRow in ipairs(data) do
      local r = rv.rows[i]
      if r then
        local tc = TRACK_TIER_COLOR[dRow.crestT] or COLOR_NEUTRAL
        -- fundo zebra simples
        if i % 2 == 0 then
          ApplyStyleTex(r.bg, "bgRow", { 0, 0, 0, 0.16 })
        else
          r.bg:SetColorTexture(0, 0, 0, 0)
        end
        -- acento esquerdo SEMPRE na cor do tier da dificuldade (color-code por linha)
        r.accent:SetColorTexture(tc[1], tc[2], tc[3], 1); r.accent:Show()
        r.cDiff:SetText(colored(tc, L[dRow.diff] or dRow.diff))
        r.cDrop:SetText(raidDropCell(dRow.endLo, dRow.endHi, dRow.endT, ilvl and dRow.endHi > ilvl))
        r.cVault:SetText(raidVaultCell(dRow.vaultI, dRow.vaultT, ilvl and dRow.vaultI > ilvl))
        r.cCrest:SetText(colored(tc, TrackName(dRow.crestT)))
        r:Show()
      end
    end
  end

  return rv
end

-- ===========================================================================
-- VIEW "PROGRESSO" (coach) — 3ª aba. Renderiza o coach numa frame própria (gear,
-- brasões com cap semanal, 3 sugestões). Lógica idêntica ao que seria embutido na
-- aba Chaves; aqui isolada. Sem dependência rígida do KeystoneLoot.
-- ===========================================================================
local function BuildCoachView(parent)
  local cv = CreateFrame("Frame", nil, parent)
  cv:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -(TOP_TITLE + 1))
  cv:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1, 1)
  cv:Hide()

  -- fundo "card" sutil (escurece levemente a área do coach p/ dar profundidade)
  local cardBg = cv:CreateTexture(nil, "BACKGROUND")
  cardBg:SetAllPoints()
  cardBg:SetColorTexture(0, 0, 0, 0.12)

  -- título (esquerda) + ilvl do char (direita) — espelha o cabeçalho da aba Chaves
  local title = cv:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", cv, "TOPLEFT", 16, -12)
  title:SetText(L.KEYS_COACH_TITLE)
  title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

  local ilvlFS = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ilvlFS:SetPoint("TOPRIGHT", cv, "TOPRIGHT", -16, -14)
  ilvlFS:SetJustifyH("RIGHT"); ilvlFS:SetWordWrap(false)
  cv.ilvlFS = ilvlFS

  -- linha Gear + linha Brasões (resumo)
  local gearFS = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  gearFS:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
  gearFS:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  gearFS:SetJustifyH("LEFT"); gearFS:SetWordWrap(true)
  cv.gearFS = gearFS

  local crestFS = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  crestFS:SetPoint("TOPLEFT", gearFS, "BOTTOMLEFT", 0, -8)
  crestFS:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  crestFS:SetJustifyH("LEFT"); crestFS:SetWordWrap(true)
  cv.crestFS = crestFS

  -- aviso de cap de brasão (vazio quando nenhum está perto do teto semanal)
  local capWarn = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  capWarn:SetPoint("TOPLEFT", crestFS, "BOTTOMLEFT", 0, -6)
  capWarn:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  capWarn:SetJustifyH("LEFT"); capWarn:SetWordWrap(true)
  cv.capWarn = capWarn

  -- diagnóstico "elo mais fraco" (onde focar primeiro); vazio sem gear rastreado
  local weakFS = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  weakFS:SetPoint("TOPLEFT", capWarn, "BOTTOMLEFT", 0, -6)
  weakFS:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  weakFS:SetJustifyH("LEFT"); weakFS:SetWordWrap(false)
  cv.weakFS = weakFS

  -- separador sutil antes das sugestões
  local sep = cv:CreateTexture(nil, "ARTWORK")
  sep:SetPoint("TOPLEFT", weakFS, "BOTTOMLEFT", 0, -10)
  sep:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  sep:SetHeight(1)
  sep:SetColorTexture(1, 1, 1, 0.08)

  -- SUG1 "GASTAR BRASÕES": até 3 linhas (uma por track com peças). Reservadas fixas
  -- p/ a sug2 ancorar estável; preenchidas/vazias no refresh.
  cv.spend = {}
  do
    local anchor, gap = sep, -12
    for i = 1, 3 do
      local fs = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, gap)
      fs:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
      fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
      cv.spend[i] = fs
      anchor, gap = fs, -3
    end
  end

  -- SUG2 "QUAL CHAVE": uma linha, abaixo das 3 de brasões
  cv.sug2 = cv:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  cv.sug2:SetPoint("TOPLEFT", cv.spend[3], "BOTTOMLEFT", 0, -8)
  cv.sug2:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  cv.sug2:SetJustifyH("LEFT"); cv.sug2:SetWordWrap(true)

  -- rodapé: nota da integração opcional com o KeystoneLoot (criado antes p/ a área de
  -- prioridade se estender até logo acima dele)
  local foot = cv:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  foot:SetPoint("BOTTOMLEFT", cv, "BOTTOMLEFT", 16, 10)
  foot:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  foot:SetJustifyH("LEFT"); foot:SetWordWrap(true)
  cv.foot = foot

  -- cabeçalho da tabela de prioridade de dungeons (texto muda BiS/essenciais)
  local priHeader = cv:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  priHeader:SetPoint("TOPLEFT", cv.sug2, "BOTTOMLEFT", 0, -12)
  priHeader:SetPoint("RIGHT", cv, "RIGHT", -16, 0)
  priHeader:SetJustifyH("LEFT"); priHeader:SetWordWrap(false)
  priHeader:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
  cv.priHeader = priHeader

  -- área rolável: 1 BLOCO por dungeon (ícone + nome + count + itens como ícones)
  local priScroll = CreateFrame("ScrollFrame", nil, cv)
  priScroll:SetPoint("TOPLEFT", priHeader, "BOTTOMLEFT", 0, -4)
  priScroll:SetPoint("RIGHT", cv, "RIGHT", -24, 0)
  priScroll:SetPoint("BOTTOM", foot, "TOP", 0, 6)
  priScroll:EnableMouseWheel(true)
  priScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur  = self:GetVerticalScroll() or 0
    local maxs = self:GetVerticalScrollRange() or 0
    local new  = cur - (delta or 0) * 30
    if new < 0 then new = 0 elseif new > maxs then new = maxs end
    self:SetVerticalScroll(new)
  end)
  cv.priScroll = priScroll

  local PRI_W = FRAME_W - 64
  local priChild = CreateFrame("Frame", nil, priScroll)
  priChild:SetSize(PRI_W, 1)
  priScroll:SetScrollChild(priChild)
  cv.priChild = priChild
  cv.priWidth = PRI_W
  cv.priBlocks = {}

  -- botão-ícone de item (pool dentro de um bloco). Borda Quickslot2 + moldura de
  -- qualidade + estrela de tier; tooltip via SetItemByID. Defensivo.
  local function getItemBtn(block, j)
    local btn = block.items[j]
    if not btn then
      btn = CreateFrame("Button", nil, block)
      btn:SetSize(34, 34)
      btn.icon = btn:CreateTexture(nil, "ARTWORK")
      btn.icon:SetSize(28, 28); btn.icon:SetPoint("CENTER")
      btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      btn.qual = btn:CreateTexture(nil, "OVERLAY", nil, 1)
      btn.qual:SetTexture("Interface\\Common\\WhiteIconFrame")
      btn.qual:SetSize(34, 34); btn.qual:SetPoint("CENTER")
      btn.border = btn:CreateTexture(nil, "OVERLAY", nil, 2)
      btn.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
      btn.border:SetSize(52, 52); btn.border:SetPoint("CENTER", 0, -1)
      btn.star = btn:CreateTexture(nil, "OVERLAY", nil, 3)
      btn.star:SetTexture("Interface\\Common\\ReputationStar")
      btn.star:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 4, 4)
      -- check de "já equipado no Mítico" (canto inferior direito); oculto por padrão
      btn.owned = btn:CreateTexture(nil, "OVERLAY", nil, 4)
      btn.owned:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
      btn.owned:SetSize(16, 16)
      btn.owned:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
      btn.owned:Hide()
      btn:SetScript("OnEnter", function(self)
        if not self.itemId then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetItemByID, GameTooltip, self.itemId)
        if self.ownedMyth then GameTooltip:AddLine(L.KEYS_COACH_BIS_OWNED, 0.2, 0.82, 0.48) end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
      block.items[j] = btn
    end
    return btn
  end

  -- bloco (linha) de uma dungeon (pool). Cresce conforme os itens (wrap horizontal).
  local function getBlock(i)
    local b = cv.priBlocks[i]
    if not b then
      b = CreateFrame("Frame", nil, priChild)
      b:SetPoint("LEFT", priChild, "LEFT", 0, 0)
      b:SetPoint("RIGHT", priChild, "RIGHT", 0, 0)
      -- zebra (sublevel 1) + BANNER da dungeon (sublevel 2, alpha 0.5) com fade à
      -- direita via MaskTexture "perks-list-mask" — imita o KeystoneLoot (entry_frame
      -- + templates.xml). Tudo defensivo: atlas/máscara ausentes → sem fade/sem banner.
      b.zebra = b:CreateTexture(nil, "BACKGROUND", nil, 1)
      b.zebra:SetAllPoints()
      b.dungeonBG = b:CreateTexture(nil, "BACKGROUND", nil, 2)
      b.dungeonBG:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
      b.dungeonBG:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0)
      b.dungeonBG:SetWidth(325)
      b.dungeonBG:SetAlpha(0.5)
      b.dungeonBG:Hide()
      pcall(function()
        local mask = b:CreateMaskTexture()
        mask:SetAtlas("perks-list-mask", true) -- useAtlasSize
        mask:ClearAllPoints()
        mask:SetPoint("LEFT", b, "LEFT", -286, 0)
        b.dungeonBG:AddMaskTexture(mask)
        b.dungeonMask = mask
      end)
      b.icon = b:CreateTexture(nil, "ARTWORK")
      b.icon:SetSize(24, 24); b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 6, -5)
      b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      b.name:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
      b.name:SetJustifyH("LEFT"); b.name:SetWordWrap(false)
      b.divider = b:CreateTexture(nil, "ARTWORK")
      b.divider:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 4, 0)
      b.divider:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 0)
      b.divider:SetHeight(3)
      if not pcall(function() b.divider:SetAtlas("delves-companion-divider"); b.divider:SetAlpha(0.5) end) then
        b.divider:SetHeight(1); b.divider:SetColorTexture(1, 1, 1, 0.10)
      end
      b.items = {}
      cv.priBlocks[i] = b
    end
    return b
  end
  cv.getItemBtn = getItemBtn
  cv.getBlock   = getBlock

  -- estado vazio + "+N outras" (FontStrings reaproveitadas)
  cv.priEmpty = priChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cv.priEmpty:SetPoint("TOPLEFT", priChild, "TOPLEFT", 2, -2)
  cv.priEmpty:SetJustifyH("LEFT"); cv.priEmpty:SetWordWrap(true)
  cv.priEmpty:SetWidth(PRI_W - 8); cv.priEmpty:Hide()

  cv.priMore = priChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  cv.priMore:SetJustifyH("LEFT"); cv.priMore:SetWordWrap(false)
  cv.priMore:Hide()

  -- (re)calcula tudo do char logado: gear equipado, brasões, sugestões, prioridade.
  cv.refresh = function()
    local ilvl    = PlayerEquippedIlvl()
    local uc      = KA.UPGRADE_COST or { perRank = 20 }
    local perRank = uc.perRank or 20
    local data    = KA.KEY_REWARDS or {}

    -- cabeçalho: "Seu ilvl: X / 289 (teto da season)"
    local seasonMax = KA.SEASON_MAX_ILVL or 289
    if ilvl then
      cv.ilvlFS:SetText(colored(COLOR_NEUTRAL,
        string.format(L.KEYS_COACH_ILVL, ilvl, seasonMax)))
    else
      local lbl = (L.KEYS_COACH_ILVL:gsub("%%d", "%%s", 1))
      cv.ilvlFS:SetText(colored(COLOR_MISSING, string.format(lbl, L.NONE, seasonMax)))
    end

    local lookup = BuildTrackLookup()
    local gear   = ScanGear(lookup)
    local equipped = EquippedTracks(lookup) -- { [itemID] = trilha } p/ marcar favoritos que já tenho

    -- linha Gear: contagem por trilha (coloridas) + nº de peças abaixo do máximo
    if lookup and gear.tracked > 0 then
      local breakdown = TrackBreakdown(function(code) return gear.counts[code] end, false)
      local notMaxTotal = (gear.notMax.C or 0) + (gear.notMax.H or 0) + (gear.notMax.M or 0)
      cv.gearFS:SetText(string.format(L.KEYS_COACH_GEAR, breakdown, notMaxTotal))
    else
      cv.gearFS:SetText(colored(COLOR_NEUTRAL,
        string.format(L.KEYS_COACH_GEAR_NONE, gear.pieces)))
    end

    -- DIAGNÓSTICO "elo mais fraco": onde focar primeiro (peça de menor track/rank/ilvl)
    if gear.weak then
      local w   = gear.weak
      local col = TRACK_TIER_COLOR[w.code] or COLOR_NEUTRAL
      local info = colored(col, string.format("%s %d/%d", TrackName(w.code), w.rank or 0, w.maxRank or 6))
      cv.weakFS:SetText(string.format(L.KEYS_COACH_WEAK, SlotName(w.slot), info))
    else
      cv.weakFS:SetText("")
    end

    -- linha Brasões: quantidade por tier + progresso do cap SEMANAL real (catch-up)
    local crest = {}
    local haveCrest = false
    for _, t in ipairs(COACH_TRACKS) do
      local ci = CrestInfo(t.crestId)
      crest[t.code] = ci
      if ci then haveCrest = true end
    end
    if haveCrest then
      local tokens = {}
      for _, t in ipairs(COACH_TRACKS) do
        local ci   = crest[t.code]
        local col  = TRACK_TIER_COLOR[t.code] or COLOR_NEUTRAL
        local name = TrackName(t.code)
        local txt
        if ci and ci.weekly ~= nil and ci.weeklyMax then
          txt = string.format(L.KEYS_COACH_CREST_ITEM, name, ci.qty, ci.weekly, ci.weeklyMax)
        elseif ci then
          txt = string.format(L.KEYS_COACH_CREST_ITEM_NOWEEK, name, ci.qty)
        else
          txt = string.format(L.KEYS_COACH_CREST_ITEM_NOWEEK, name, 0)
        end
        tokens[#tokens + 1] = colored(col, txt)
      end
      cv.crestFS:SetText(string.format(L.KEYS_COACH_CRESTS,
        table.concat(tokens, "  \194\183  ")))
    else
      cv.crestFS:SetText(colored(COLOR_MISSING, L.KEYS_COACH_CRESTS_NONE))
    end

    -- AVISO DE CAP: se algum brasão passou de 85% do cap semanal, avisa p/ gastar
    -- antes do reset. Mostra o tier MAIS ALTO perto do cap. Vazio se nenhum.
    local warnTxt
    for i = #COACH_TRACKS, 1, -1 do
      local t  = COACH_TRACKS[i]
      local ci = crest[t.code]
      if ci and ci.weekly and ci.weeklyMax and ci.weeklyMax > 0
         and ci.weekly >= ci.weeklyMax * 0.85 then
        warnTxt = colored(TRACK_TIER_COLOR[t.code] or COLOR_ACTION,
          string.format(L.KEYS_COACH_CAP_WARN, TrackName(t.code), ci.weekly, ci.weeklyMax))
        break
      end
    end
    cv.capWarn:SetText(warnTxt and (COACH_ICON_WARN .. " " .. warnTxt) or "")

    -- (a) GASTAR BRASÕES: uma linha por track com peças (Mítico > Herói > Campeão).
    -- N = peças não-maxadas; faltam (níveis*perRank) p/ maxar; X = brasões do tier.
    -- X>=perRank → upgrades já + faltam (destaque); X<perRank → "junte +(perRank-X)".
    local slot = 0
    for i = #COACH_TRACKS, 1, -1 do -- Mítico primeiro (prioridade visual ao tier alto)
      local t  = COACH_TRACKS[i]
      local nm = gear.notMax[t.code] or 0
      if lookup and nm > 0 and slot < 3 then
        slot = slot + 1
        local fs   = cv.spend[slot]
        local ci   = crest[t.code]
        local x    = (ci and ci.qty) or 0
        local need = (gear.missing[t.code] or 0) * perRank -- brasões pra maxar o track
        local col  = TRACK_TIER_COLOR[t.code] or COLOR_ACTION
        local name = TrackName(t.code)
        local txt
        if x >= perRank then
          local upg  = math.floor(x / perRank)
          local left = need - x
          if left > 0 then
            txt = COACH_ICON_SPEND .. " " .. colored(col,
              string.format(L.KEYS_COACH_SPEND_HAS, name, nm, upg, x, left))
          else
            txt = COACH_ICON_SPEND .. " " .. colored(col,
              string.format(L.KEYS_COACH_SPEND_MAXALL, name, nm, x))
          end
        else
          txt = colored(COLOR_NEUTRAL,
            string.format(L.KEYS_COACH_SPEND_LOW, name, nm, perRank - x, need - x))
        end
        fs:SetText(txt)
        fs:Show()
      end
    end
    if slot == 0 then -- nenhum track com peças não-maxadas
      cv.spend[1]:SetText(COACH_ICON_SPEND .. " " ..
        colored(COLOR_NEUTRAL, L.KEYS_COACH_SPEND_NONE))
      cv.spend[1]:Show()
      slot = 1
    end
    for k = slot + 1, 3 do cv.spend[k]:SetText(""); cv.spend[k]:Hide() end

    -- (b) QUAL CHAVE — recomendação CONTEXTUAL ao track predominante do gear
    -- (KA.TRACK_NEXT_KEY) + objetivo fixo +10 (Cofre Mítico). Sem gear rastreado →
    -- 'none' (começar por Mítica 0). Não depende de ilvl.
    local pred = PredominantTrack(gear) -- "C"/"H"/"M" ou nil
    local trackName = (pred and CODE_TO_TRACK[pred]) or "none"
    local nk = (KA.TRACK_NEXT_KEY or {})[trackName] or (KA.TRACK_NEXT_KEY or {}).none
    local recTok
    if nk then
      local col = TRACK_TIER_COLOR[pred] or COLOR_ACTION
      recTok = colored(col, L[nk.keyL]) .. " \226\128\148 " .. colored(COLOR_NEUTRAL, L[nk.msgL])
    else
      recTok = colored(COLOR_NEUTRAL, "?")
    end
    local goalTok = colored(TRACK_TIER_COLOR.M or COLOR_ACTION, "+10")
      .. " " .. colored(COLOR_MISSING, "(" .. L.KEYS_COACH_KEY_GOAL .. ")")
    cv.sug2:SetText(COACH_ICON_KEY .. " " ..
      string.format(L.KEYS_COACH_KEYS, recTok, goalTok))

    -- (c) PRIORIDADE DE DUNGEONS (mini-tabela em árvore: dungeon + itens favoritados).
    -- Prioriza BiS (tier 3); fallback p/ essenciais (tier 2). Limita às top dungeons
    -- (o resto vira "+N outras") e usa o scroll p/ o overflow vertical.
    local prio, prioTier = BisDungeonPriority(CurrentSpecId(), equipped)
    cv.priHeader:SetText(COACH_ICON_BIS .. " " ..
      ((prioTier == 2) and L.KEYS_COACH_PRIO_ESS or L.KEYS_COACH_PRIO_BIS))

    local MAX_DUNGEONS = 6 -- teto de dungeons; resto vira "+N outras"
    local HEADER_H, BTN, GAP, PAD = 24, 34, 10, 6
    local W = cv.priWidth or (FRAME_W - 64)
    local perRow = math.max(1, math.floor((W - 2 * PAD + GAP) / (BTN + GAP)))
    local bi, y = 0, 0

    if prio and #prio > 0 then
      cv.priEmpty:Hide()
      local shown = math.min(#prio, MAX_DUNGEONS)
      for d = 1, shown do
        local dg = prio[d]
        bi = bi + 1
        local b = cv.getBlock(bi)

        -- BANNER de fundo da dungeon (com fade à direita pela máscara) — defensivo
        if b.dungeonBG then
          local banner = DungeonBanner(dg.sourceId)
          if banner then
            pcall(function() b.dungeonBG:SetTexture(banner) end)
            pcall(function() b.dungeonBG:SetDesaturated(false) end)
            b.dungeonBG:Show()
          else
            b.dungeonBG:Hide()
          end
        end

        -- ícone + nome + count da dungeon
        local tex = DungeonIcon(dg.sourceId)
        if tex then b.icon:SetTexture(tex); b.icon:Show() else b.icon:Hide() end
        b.name:SetText(string.format("%s  \194\183  %d", dg.name or "?", dg.count or 0))

        -- itens como ícones (wrap horizontal)
        local items = dg.items or {}
        local rows  = math.max(1, math.ceil(#items / perRow))
        for j, itemId in ipairs(items) do
          local btn = cv.getItemBtn(b, j)
          btn.itemId = itemId
          btn.icon:SetTexture(ItemIcon(itemId))
          local _, qcol = ItemName(itemId)
          local c = qcol or COLOR_NEUTRAL
          btn.qual:SetVertexColor(c[1], c[2], c[3])
          if prioTier == 2 then -- essencial: estrela prata, menor
            btn.star:SetVertexColor(0.75, 0.75, 0.78); btn.star:SetSize(14, 14)
          else                  -- BiS: estrela dourada
            btn.star:SetVertexColor(1.0, 0.82, 0.0); btn.star:SetSize(18, 18)
          end
          -- favorito que você JÁ tem equipado no Mítico = "done": dessatura + moldura verde + check
          local oc = equipped and equipped[itemId]
          if oc == "M" then
            btn.icon:SetDesaturated(true)
            btn.qual:SetVertexColor(COLOR_DONE[1], COLOR_DONE[2], COLOR_DONE[3])
            btn.ownedMyth = true
            if btn.owned then btn.owned:Show() end
          else
            btn.icon:SetDesaturated(false)
            btn.ownedMyth = false
            if btn.owned then btn.owned:Hide() end
          end
          local col = (j - 1) % perRow
          local row = math.floor((j - 1) / perRow)
          btn:ClearAllPoints()
          btn:SetPoint("TOPLEFT", b, "TOPLEFT",
            PAD + col * (BTN + GAP), -(HEADER_H + row * (BTN + GAP)))
          btn:Show()
        end
        for k = #items + 1, #b.items do b.items[k]:Hide(); b.items[k].itemId = nil end

        local bh = HEADER_H + rows * BTN + (rows - 1) * GAP + PAD
        b:SetHeight(bh)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", cv.priChild, "TOPLEFT", 0, -y)
        b:SetPoint("RIGHT", cv.priChild, "RIGHT", 0, 0)
        b.zebra:SetColorTexture(0, 0, 0, (d % 2 == 0) and 0.16 or 0.0)
        b.divider:Show()
        b:Show()
        y = y + bh
      end
      for k = bi + 1, #cv.priBlocks do cv.priBlocks[k]:Hide() end

      if #prio > shown then
        cv.priMore:ClearAllPoints()
        cv.priMore:SetPoint("TOPLEFT", cv.priChild, "TOPLEFT", PAD, -(y + 2))
        cv.priMore:SetText(colored(COLOR_NEUTRAL,
          string.format(L.KEYS_COACH_PRIO_MORE, #prio - shown)))
        cv.priMore:Show()
        y = y + 16
      else
        cv.priMore:Hide()
      end
    else
      for k = 1, #cv.priBlocks do cv.priBlocks[k]:Hide() end
      cv.priMore:Hide()
      cv.priEmpty:SetText(colored(COLOR_NEUTRAL, L.KEYS_COACH_BIS_NONE))
      cv.priEmpty:Show()
      y = 20
    end

    cv.priChild:SetHeight(math.max(y, 1))
    if cv.priScroll then cv.priScroll:SetVerticalScroll(0) end

    -- rodapé: integração ATIVA quando lemos prioridade da spec atual; senão, convite.
    if prio and #prio > 0 then
      cv.foot:SetText(L.KEYS_COACH_KL_ON)
    else
      cv.foot:SetText(L.KEYS_COACH_KL_OFF)
    end
  end

  return cv
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
-- Alterna entre as 3 views (Personagens | Chaves | Progresso) sem resíduo:
-- esconde os widgets das outras e mostra só a escolhida. "chars" repassa pro
-- Refresh normal; "keys" repinta a tabela de recompensas; "coach" recalcula o
-- painel de progresso. No modo só-PvP, "keys"/"coach" caem de volta pra "chars".
-- ---------------------------------------------------------------------------
ApplyView = function()
  if not frame then return end
  local mode = (KA.GetMode and KA.GetMode()) or "pve"
  local view = (KA.GetView and KA.GetView()) or "chars"
  -- modo SÓ-PvP: as abas "Chaves" e "Progresso" ficam escondidas (M+ não faz
  -- sentido p/ PvP puro); se a view ativa era uma delas, volta pra "chars" pra
  -- não prender numa aba oculta.
  if mode == "pvp" and (view == "keys" or view == "coach" or view == "raids") then
    -- KA.SetView dispara o bus → ApplyView reentra (se a janela está visível) já
    -- como "chars" e renderiza tudo; saímos aqui p/ não rodar Refresh() duas vezes.
    if KA.SetView then
      KA.SetView("chars")
      if frame:IsShown() then return end -- janela VISÍVEL: o bus já reentrou e renderizou "chars"; evita Refresh() duplo
    end
    view = "chars" -- janela OCULTA (ou sem setter): renderiza chars nesta mesma passada (sem depender do bus)
  end
  local keys  = (view == "keys")
  local coach = (view == "coach")
  local raids = (view == "raids")
  local chars = not (keys or coach or raids)
  if frame.summary     then frame.summary:SetShown(chars) end
  if frame.groupBtn    then frame.groupBtn:SetShown(chars) end
  if frame.hideCb      then frame.hideCb:SetShown(chars) end
  if frame.hideCbLabel then frame.hideCbLabel:SetShown(chars) end
  if frame.headerBar   then frame.headerBar:SetShown(chars) end
  if frame.scroll      then frame.scroll:SetShown(chars) end
  if frame.keysView    then frame.keysView:SetShown(keys) end
  if frame.coachView   then frame.coachView:SetShown(coach) end
  if frame.raidsView   then frame.raidsView:SetShown(raids) end
  if frame.paintView   then frame.paintView() end
  if keys then
    if frame.empty then frame.empty:Hide() end
    if frame.keysView and frame.keysView.refresh then frame.keysView.refresh() end
  elseif coach then
    if frame.empty then frame.empty:Hide() end
    if frame.coachView and frame.coachView.refresh then frame.coachView.refresh() end
  elseif raids then
    if frame.empty then frame.empty:Hide() end
    if frame.raidsView and frame.raidsView.refresh then frame.raidsView.refresh() end
  else
    Refresh()
  end
end

-- ---------------------------------------------------------------------------
-- Construção da janela
-- ---------------------------------------------------------------------------
local function BuildFrame()
  if frame then return end

  -- MOLDURA NATIVA: tenta o ButtonFrameTemplate (moldura dourada NineSlice + portrait
  -- circular + titlebar + CloseButton + Inset — tudo de graça do WoW). Se falhar,
  -- cai no frame manual (BackdropTemplate) com a moldura montada à mão. Defensivo.
  local usingTemplate = false
  do
    local ok = pcall(function()
      frame = CreateFrame("Frame", "KrononAltsFrame", UIParent, "ButtonFrameTemplate")
    end)
    if ok and frame and frame.Inset then
      usingTemplate = true
    else
      frame = CreateFrame("Frame", "KrononAltsFrame", UIParent, "BackdropTemplate")
    end
  end
  frame:SetSize(FRAME_W, FRAME_H)
  frame:SetFrameStrata("HIGH")
  frame:SetToplevel(true) -- vem INTEIRA pra frente ao clicar (não intercala com a bag/outras janelas)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  ApplyPosition(frame)

  -- host = onde TODO o conteúdo é ancorado: o Inset nativo (template) OU o próprio
  -- frame (manual). Assim os mesmos offsets servem aos dois modos.
  local host = (usingTemplate and frame.Inset) or frame
  frame.host = host

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

  -- UNDERLAY OPACO: fundo escuro e SÓLIDO atrás de tudo — garante que NADA da cena do
  -- jogo vaze atrás do texto (vale p/ os dois modos).
  local solidBg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  solidBg:SetAllPoints()
  solidBg:SetColorTexture(0.05, 0.05, 0.07, 1) -- escuro, alpha 1 (opaco)
  frame.solidBg = solidBg

  local tb -- toolbar do topo (abas/engrenagem/countdown) — definida abaixo

  if usingTemplate then
    -- TÍTULO / PORTRAIT / CLOSE nativos do template
    pcall(function()
      if frame.SetTitle then frame:SetTitle(L.TITLE)
      elseif frame.TitleText then frame.TitleText:SetText(L.TITLE) end
    end)
    pcall(function()
      local p = (frame.PortraitContainer and frame.PortraitContainer.portrait)
        or frame.portrait or frame.Portrait
      if p then
        -- logo do Kronon (mesma do KrononBags) recortada no portrait circular nativo
        p:SetTexture("Interface\\AddOns\\KrononAlts\\Media\\KrononLogo.tga")
        p:SetTexCoord(-0.08, 1.08, -0.08, 1.08)
      end
    end)
    -- CloseButton nativo → só esconder a janela (sem o sistema de UIPanel)
    if frame.CloseButton then
      frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    end
    -- ARRASTE: ButtonFrameTemplate não é movível por padrão → handle transparente
    -- sobre a barra de título nativa (deixa o X livre à direita).
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    drag:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, 0)
    drag:SetHeight(36)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() frame:StartMoving() end)
    drag:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePosition(frame) end)
  else
    -- FUNDO texturizado + MOLDURA ORNAMENTADA montados à mão (fallback).
    if frame.SetBackdrop then
      local okBg = pcall(frame.SetBackdrop, frame, {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1, tile = true, tileSize = 256,
      })
      if not okBg then
        pcall(frame.SetBackdrop, frame, {
          bgFile = "Interface\\Buttons\\WHITE8X8",
          edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        })
      end
      pcall(frame.SetBackdropColor, frame, 0.07, 0.08, 0.10, 1)
      pcall(frame.SetBackdropBorderColor, frame, 0, 0, 0, 1)
    end
    do
      local EXT = 14
      local ok, deco = pcall(CreateFrame, "Frame", nil, frame, "BackdropTemplate")
      if ok and deco and deco.SetBackdrop then
        deco:SetPoint("TOPLEFT", frame, "TOPLEFT", -EXT, EXT)
        deco:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", EXT, -EXT)
        pcall(deco.SetFrameLevel, deco, math.max(0, frame:GetFrameLevel()))
        local applied = pcall(deco.SetBackdrop, deco, {
          edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
        })
        if applied then
          pcall(deco.SetBackdropBorderColor, deco, 1, 1, 1, 1)
          frame.deco = deco
        else
          deco:Hide()
        end
      end
    end
  end

  tinsert(UISpecialFrames, "KrononAltsFrame") -- ESC fecha

  -- TOOLBAR DO TOPO (abas + engrenagem + countdown). Ancorada ao host (no template,
  -- topo do Inset; no manual, topo do frame). No modo manual também é a titlebar
  -- (fundo escuro, alça de arraste, título e portrait); no template é transparente.
  tb = CreateFrame("Frame", nil, host)
  tb:SetPoint("TOPLEFT", host, "TOPLEFT", usingTemplate and 2 or 1, usingTemplate and -2 or -1)
  tb:SetPoint("TOPRIGHT", host, "TOPRIGHT", usingTemplate and -2 or -1, usingTemplate and -2 or -1)
  tb:SetHeight(TOP_TITLE)

  local title -- só no modo manual
  if not usingTemplate then
    tb:EnableMouse(true)
    tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() frame:StartMoving() end)
    tb:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePosition(frame) end)
    local tbbg = tb:CreateTexture(nil, "BACKGROUND")
    tbbg:SetAllPoints()
    ApplyStyleTex(tbbg, "titlebar", { 0.10, 0.10, 0.10, 1 })

    local tbicon = tb:CreateTexture(nil, "ARTWORK")
    tbicon:SetSize(22, 22)
    tbicon:SetPoint("LEFT", tb, "LEFT", 6, 0)
    -- logo do Kronon; fallback p/ o ícone genérico se a textura falhar
    if not pcall(function()
      tbicon:SetTexture("Interface\\AddOns\\KrononAlts\\Media\\KrononLogo.tga")
      tbicon:SetTexCoord(-0.08, 1.08, -0.08, 1.08)
    end) then
      tbicon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
      tbicon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    local ring = tb:CreateTexture(nil, "OVERLAY")
    ring:SetSize(30, 30)
    ring:SetPoint("CENTER", tbicon, "CENTER", 0, 0)
    if not pcall(ring.SetTexture, ring, "Interface\\Minimap\\MiniMap-TrackingBorder") then
      ring:Hide()
    end

    title = tb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", tbicon, "RIGHT", 8, 0)
    title:SetText(L.TITLE)
    title:SetTextColor(1, 1, 1)
  end

  -- TOGGLE DE VIEW (abas): Personagens | Chaves — na titlebar, após o título.
  -- A aba ativa ganha um filete azul embaixo; clicar persiste via KA.SetView
  -- (dispara o bus → ApplyView alterna a view).
  frame.viewTabs = {}
  local function makeViewTab(text, viewKey, anchor, gap)
    local b = CreateFrame("Button", nil, tb)
    b:SetHeight(18)
    b:SetPoint("LEFT", anchor, "RIGHT", gap, 0)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", b, "LEFT", 6, 0)
    fs:SetText(text)
    b:SetWidth((fs:GetStringWidth() or 40) + 12)
    b.fs = fs
    -- realce de fundo da aba ativa (design system)
    local hl = b:CreateTexture(nil, "BACKGROUND")
    hl:SetPoint("TOPLEFT", b, "TOPLEFT", 2, 0)
    hl:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, -1)
    ApplyStyleTex(hl, "tabActive", { 1, 1, 1, 0.06 })
    hl:Hide()
    b.hl = hl
    local bar = b:CreateTexture(nil, "ARTWORK")
    bar:SetHeight(2)
    bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 4, -1)
    bar:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, -1)
    bar:SetColorTexture(ACCENT_BLUE[1], ACCENT_BLUE[2], ACCENT_BLUE[3], 1)
    bar:Hide()
    b.bar = bar
    b.viewKey = viewKey
    b:SetScript("OnClick", function() if KA.SetView then KA.SetView(viewKey) end end)
    b:SetScript("OnEnter", function(self) self.fs:SetTextColor(1, 1, 1) end)
    b:SetScript("OnLeave", function() if frame.paintView then frame.paintView() end end)
    frame.viewTabs[#frame.viewTabs + 1] = b
    return b
  end
  -- âncora inicial das abas: após o título (manual) ou no canto-esq da toolbar (template)
  local tabStart = CreateFrame("Frame", nil, tb)
  tabStart:SetSize(1, TOP_TITLE)
  if title then
    tabStart:SetPoint("LEFT", title, "RIGHT", 12, 0)
  else
    tabStart:SetPoint("LEFT", tb, "LEFT", 8, 0)
  end
  local tabChars = makeViewTab(L.VIEW_CHARS, "chars", tabStart, 4)
  local tabKeys  = makeViewTab(L.VIEW_KEYS, "keys", tabChars, 2)
  local tabRaids = makeViewTab(L.VIEW_RAIDS, "raids", tabKeys, 2)
  makeViewTab(L.VIEW_COACH, "coach", tabRaids, 2)
  frame.paintView = function()
    local mode = (KA.GetMode and KA.GetMode()) or "pve"
    local extraAllowed = (mode ~= "pvp") -- abas "Chaves"/"Progresso" somem no só-PvP
    local view = (KA.GetView and KA.GetView()) or "chars"
    for _, b in ipairs(frame.viewTabs) do
      if b.viewKey == "keys" or b.viewKey == "coach" or b.viewKey == "raids" then b:SetShown(extraAllowed) end
      local active = (b.viewKey == view)
      b.bar:SetShown(active)
      if b.hl then b.hl:SetShown(active) end
      if active then b.fs:SetTextColor(1, 1, 1)
      else b.fs:SetTextColor(0.6, 0.6, 0.6) end
    end
  end

  -- CLOSE: no template usa o CloseButton NATIVO; no manual cria o nosso.
  local closeAnchor
  if usingTemplate and frame.CloseButton then
    closeAnchor = frame.CloseButton
  else
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    close:SetFrameLevel(tb:GetFrameLevel() + 5)
    close:SetScript("OnClick", function() frame:Hide() end)
    closeAnchor = close
  end

  -- BOTÃO DE ENGRENAGEM (abre a janela de config). No template fica no canto-dir da
  -- toolbar; no manual, à esquerda do X.
  local gear = CreateFrame("Button", nil, tb)
  gear:SetSize(18, 18)
  if usingTemplate then
    gear:SetPoint("TOPRIGHT", tb, "TOPRIGHT", -4, -4)
  else
    gear:SetPoint("RIGHT", closeAnchor, "LEFT", -2, 0)
  end
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

  -- LINHA DE RESUMO — parenteada AO host (no template, o Inset é um frame filho; se
  -- ficasse parenteada ao frame, renderizaria ATRÁS do Inset e sumiria).
  local summary = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summary:SetPoint("TOPLEFT", host, "TOPLEFT", 12, -(TOP_TITLE + 4))
  summary:SetPoint("RIGHT", host, "RIGHT", -255, 0)
  summary:SetJustifyH("LEFT")
  summary:SetWordWrap(false)
  frame.summary = summary

  -- ocultar concluídos (canto direito da linha de resumo)
  local hideCb = CreateFrame("CheckButton", nil, host, "UICheckButtonTemplate")
  hideCb:SetSize(20, 20)
  hideCb:SetPoint("TOPRIGHT", host, "TOPRIGHT", -8, -(TOP_TITLE + 2))
  local cbLabel = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  cbLabel:SetPoint("RIGHT", hideCb, "LEFT", -2, 0)
  cbLabel:SetText(L.HIDE_COMPLETED)
  cbLabel:SetTextColor(COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3])
  frame.hideCbLabel = cbLabel
  hideCb:SetChecked(KA.GetHideCompleted and KA.GetHideCompleted() or false)
  hideCb:SetScript("OnClick", function(self)
    if KA.SetHideCompleted then KA.SetHideCompleted(self:GetChecked()) end
  end)
  frame.hideCb = hideCb

  -- BOTÃO AGRUPAR (3 estados: não / reino / facção) — à esquerda do "ocultar"
  local groupBtn = CreateFrame("Button", nil, host)
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

  -- CABEÇALHO DE COLUNAS (preto @30%) — parenteado AO host (z-order acima do Inset)
  local headerBar = CreateFrame("Frame", nil, host)
  headerBar:SetPoint("TOPLEFT", host, "TOPLEFT", 1, -(TOP_TITLE + TOP_SUMMARY))
  headerBar:SetPoint("TOPRIGHT", host, "TOPRIGHT", -1, -(TOP_TITLE + TOP_SUMMARY))
  headerBar:SetHeight(TOP_HEADER)
  local hbbg = headerBar:CreateTexture(nil, "BACKGROUND")
  hbbg:SetAllPoints()
  hbbg:SetColorTexture(0, 0, 0, 0.30)
  frame.headerBar = headerBar

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

  -- SCROLLFRAME — parenteado AO host (z-order acima do Inset no template)
  local scroll = CreateFrame("ScrollFrame", "KrononAltsScroll", host, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", host, "TOPLEFT", 4, -CONTENT_TOP)
  scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -26, 8)
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

  -- estado vazio — parenteado AO host (z-order acima do Inset no template)
  local empty = host:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  empty:SetPoint("TOP", scroll, "TOP", 0, -20)
  empty:SetWidth(FRAME_W - 60)
  empty:SetJustifyH("CENTER")
  empty:SetText(L.EMPTY)
  empty:Hide()
  frame.empty = empty

  -- VIEW DE RECOMPENSAS (aba "Chaves") — ancorada ao host; escondida por padrão.
  frame.keysView = BuildKeysView(host)

  -- VIEW "PROGRESSO" (coach) — ancorada ao host; escondida por padrão.
  frame.coachView = BuildCoachView(host)

  -- VIEW "RAIDS" — tabela de recompensas de raid; ancorada ao host; escondida por padrão.
  frame.raidsView = BuildRaidsView(host)

  -- Eventos que mudam o COACH (gear/brasões): recalcula só quando a aba Progresso
  -- está visível. Coalescido (0.3s) p/ não repintar a cada BAG_UPDATE.
  local coachEvents = CreateFrame("Frame")
  coachEvents:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  coachEvents:RegisterEvent("BAG_UPDATE")
  coachEvents:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
  coachEvents:RegisterEvent("ITEM_DATA_LOAD_RESULT") -- nomes de item da tabela de prioridade
  local coachPending = false
  local function coachRefreshNow()
    coachPending = false
    if frame and frame:IsShown() and frame.coachView and frame.coachView:IsShown()
       and frame.coachView.refresh then
      pcall(frame.coachView.refresh)
    end
  end
  coachEvents:SetScript("OnEvent", function()
    if coachPending then return end
    coachPending = true
    if C_Timer and C_Timer.After then
      C_Timer.After(0.3, coachRefreshNow)
    else
      coachRefreshNow()
    end
  end)

  -- ticker do countdown (1s)
  frame.elapsed = 1
  frame:SetScript("OnUpdate", function(self, e)
    self.elapsed = self.elapsed + e
    if self.elapsed < 1 then return end
    self.elapsed = 0
    local info = KA.GetResetInfo and KA.GetResetInfo()
    if not info or not self.countdown then return end
    -- só o reset SEMANAL (o diário foi cortado); valor em branco vivo p/ destaque.
    self.countdown:SetText(string.format("|cff888888%s|r |cffffffff%s|r",
      L.RESET_WEEKLY, FormatCountdown(info.weeklySeconds)))
  end)

  ApplyView() -- aplica a view salva (Personagens/Chaves) e faz o 1º Refresh
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
    ApplyView()
    frame:Show()
  end
end

--- KrononAlts.Open() — garante a janela ABERTA (nunca fecha). Reutiliza KA.Toggle.
function KA.Open()
  if not frame then BuildFrame() end
  if not frame:IsShown() then KA.Toggle() end
end

KA.bus:Register(function()
  if frame and frame:IsShown() then ApplyView() end
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
