-- KrononAlts — painel cross-character de objetivos semanais do ecossistema Kronon.
-- Mostra, numa tabela, Grande Cofre, Mítica+ e lockouts de raide de cada personagem.
-- Core: i18n, SavedVariables, snapshot do char logado, detecção de reset e eventos.

local ADDON = "KrononAlts"
local KA_PREFIX = "|cff33ff33KrononAlts|r: "
local WEEK = 7 * 24 * 60 * 60
local SNAPSHOT_DELAY = 1 -- coalescência de snapshots (segundos)

-- ---------------------------------------------------------------------------
-- KrononLib: i18n (NewLocale) + EventBus (NewEventBus)
-- ---------------------------------------------------------------------------
local K = LibStub("KrononLib-1.0")

local EN = {
  TITLE            = "KrononAlts",
  COL_CHAR         = "Character",
  COL_VAULT        = "Vault",
  COL_MPLUS        = "M+",
  COL_KEY          = "Keystone",
  COL_RATING       = "Rating",
  COL_RAID         = "Raid",
  RESET_WEEKLY     = "Weekly reset:",
  RESET_DAILY      = "Daily reset:",
  ABBR_D           = "d",
  ABBR_H           = "h",
  ABBR_M           = "m",
  TRACK_MPLUS      = "Mythic+",
  TRACK_RAID       = "Raid",
  TRACK_WORLD      = "World",
  TT_VAULT_TITLE   = "Great Vault",
  VAULT_HAS_REWARDS= "Rewards waiting to be claimed!",
  TT_SLOT_ILVL     = "item level %d",
  TT_SLOT_READY    = "reward ready",
  TT_MPLUS_TITLE   = "Mythic+ this week",
  TT_RUNS          = "%d runs completed",
  TT_BEST          = "Best key: +%d",
  TT_NO_KEY        = "No keystone in bags",
  TT_RATING        = "Mythic+ rating: %d",
  TT_RAID_TITLE    = "Raid lockouts",
  TT_NO_RAID       = "No raid lockouts",
  TT_LEVEL_ILVL    = "Level %d  •  ilvl %d",
  TT_UPDATED       = "Updated %s ago",
  TT_REMOVE_HINT   = "Right-click to remove this character",
  STALE            = "Snapshot is older than the current reset — log in on this character to refresh.",
  EMPTY            = "No characters yet. Log in on your alts to fill in the table.",
  NONE             = "—",
  DIFF_LFR         = "LFR",
  DIFF_N           = "N",
  DIFF_H           = "H",
  DIFF_M           = "M",
  REMOVE_CONFIRM   = "Remove %s from KrononAlts?",
  MSG_SNAPSHOT     = "snapshot updated.",
}

local PT = {
  COL_CHAR         = "Personagem",
  COL_VAULT        = "Cofre",
  COL_KEY          = "Chave",
  COL_RATING       = "Rating",
  COL_RAID         = "Raide",
  RESET_WEEKLY     = "Reset semanal:",
  RESET_DAILY      = "Reset diário:",
  TRACK_MPLUS      = "Mítica+",
  TRACK_RAID       = "Raide",
  TRACK_WORLD      = "Mundo",
  TT_VAULT_TITLE   = "Grande Cofre",
  VAULT_HAS_REWARDS= "Há recompensas esperando para serem coletadas!",
  TT_SLOT_ILVL     = "nível de item %d",
  TT_SLOT_READY    = "recompensa pronta",
  TT_MPLUS_TITLE   = "Mítica+ desta semana",
  TT_RUNS          = "%d runs concluídas",
  TT_BEST          = "Maior chave: +%d",
  TT_NO_KEY        = "Sem chave nas bolsas",
  TT_RATING        = "Rating de Mítica+: %d",
  TT_RAID_TITLE    = "Lockouts de raide",
  TT_NO_RAID       = "Nenhum lockout de raide",
  TT_LEVEL_ILVL    = "Nível %d  •  ilvl %d",
  TT_UPDATED       = "Atualizado há %s",
  TT_REMOVE_HINT   = "Clique-direito para remover este personagem",
  STALE            = "O snapshot é anterior ao reset atual — logue neste personagem para atualizar.",
  EMPTY            = "Nenhum personagem ainda. Logue nos seus alts para preencher a tabela.",
  REMOVE_CONFIRM   = "Remover %s do KrononAlts?",
  MSG_SNAPSHOT     = "snapshot atualizado.",
}

local ES = {
  COL_CHAR         = "Personaje",
  COL_VAULT        = "Cámara",
  COL_KEY          = "Piedra",
  COL_RATING       = "Punt.",
  COL_RAID         = "Banda",
  RESET_WEEKLY     = "Reinicio semanal:",
  RESET_DAILY      = "Reinicio diario:",
  TRACK_MPLUS      = "Mítica+",
  TRACK_RAID       = "Banda",
  TRACK_WORLD      = "Mundo",
  TT_VAULT_TITLE   = "Gran Cámara",
  VAULT_HAS_REWARDS= "¡Hay recompensas esperando a ser reclamadas!",
  TT_SLOT_ILVL     = "nivel de objeto %d",
  TT_SLOT_READY    = "recompensa lista",
  TT_MPLUS_TITLE   = "Mítica+ de esta semana",
  TT_RUNS          = "%d carreras completadas",
  TT_BEST          = "Mejor piedra: +%d",
  TT_NO_KEY        = "Sin piedra angular en las bolsas",
  TT_RATING        = "Puntuación de Mítica+: %d",
  TT_RAID_TITLE    = "Bloqueos de banda",
  TT_NO_RAID       = "Sin bloqueos de banda",
  TT_LEVEL_ILVL    = "Nivel %d  •  ilvl %d",
  TT_UPDATED       = "Actualizado hace %s",
  TT_REMOVE_HINT   = "Clic derecho para eliminar este personaje",
  STALE            = "La instantánea es anterior al reinicio actual — entra con este personaje para actualizar.",
  EMPTY            = "Aún no hay personajes. Entra con tus alts para llenar la tabla.",
  REMOVE_CONFIRM   = "¿Eliminar %s de KrononAlts?",
  MSG_SNAPSHOT     = "instantánea actualizada.",
}

local L = K:NewLocale(EN, { ptBR = PT, esES = ES })

-- ---------------------------------------------------------------------------
-- Namespace público + barramento de eventos (notifica a UI)
-- ---------------------------------------------------------------------------
KrononAlts = KrononAlts or {}
local KA = KrononAlts
KA.L = L
KA.bus = K.NewEventBus()

-- ---------------------------------------------------------------------------
-- SavedVariables (account-wide)
--   KrononAltsDB = { version = 1, chars = { [charKey] = {...} } }
-- ---------------------------------------------------------------------------
local DB
local function InitDB()
  if type(KrononAltsDB) ~= "table" then KrononAltsDB = {} end
  KrononAltsDB.version = 1
  if type(KrononAltsDB.chars) ~= "table" then KrononAltsDB.chars = {} end
  DB = KrononAltsDB
end

-- ---------------------------------------------------------------------------
-- Identidade / utilidades
-- ---------------------------------------------------------------------------
local function CurrentKey()
  local name = UnitName("player")
  local realm = GetNormalizedRealmName()
  if not name or name == "" or not realm or realm == "" then return nil end
  return name .. "-" .. realm
end
KA.CurrentKey = CurrentKey

-- pcall que só aceita retorno numérico (defensivo p/ APIs que podem não ter carregado)
local function safeNum(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  if ok and type(v) == "number" then return v end
  return nil
end

local function GetWeeklySeconds()
  return safeNum(C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset) or 0
end

local function GetDailySeconds()
  return safeNum(C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) or 0
end

local function GetSeason()
  local s = safeNum(C_MythicPlus and C_MythicPlus.GetCurrentSeason)
  if s and s >= 0 then return s end
  return nil
end

-- Reset info ao vivo (usado pela UI no countdown e na detecção de "precisa logar")
function KA.GetResetInfo()
  local now = time()
  local w = GetWeeklySeconds()
  local d = GetDailySeconds()
  return {
    weeklySeconds = w,
    dailySeconds  = d,
    weeklyResetAt = now + w,
    dailyResetAt  = now + d,
  }
end

-- Snapshot anterior ao reset semanal atual? (alt offline → não dá pra reler)
function KA.IsStale(rec)
  if type(rec) ~= "table" then return true end
  local info = KA.GetResetInfo()
  return (rec.updatedAt or 0) < (info.weeklyResetAt - WEEK)
end

-- ---------------------------------------------------------------------------
-- Coletores de snapshot (cada um totalmente defensivo)
-- ---------------------------------------------------------------------------
local function SnapshotVault()
  local vault = { mplus = nil, raid = nil, world = nil, hasRewards = false }
  if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then return vault end

  local ok, activities = pcall(C_WeeklyRewards.GetActivities)
  if not ok or type(activities) ~= "table" then return vault end

  local groups = {} -- [type] = { filled, total, slots = { {progress, threshold, unlocked, ilvl, level} } }
  for _, a in ipairs(activities) do
    if type(a) == "table" and type(a.threshold) == "number" and a.threshold > 0 then
      local t = a.type
      if t ~= nil then
        local g = groups[t]
        if not g then
          g = { filled = 0, total = 0, slots = {} }
          groups[t] = g
        end
        local progress = a.progress or 0
        local unlocked = progress >= a.threshold
        local ilvl = nil
        if unlocked and a.id and C_WeeklyRewards.GetExampleRewardItemHyperlinks then
          local ok2, link = pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, a.id)
          if ok2 and link and C_Item and C_Item.GetDetailedItemLevelInfo then
            local ok3, ilv = pcall(C_Item.GetDetailedItemLevelInfo, link)
            if ok3 and type(ilv) == "number" and ilv > 0 then ilvl = ilv end
          end
        end
        g.total = g.total + 1
        if unlocked then g.filled = g.filled + 1 end
        g.slots[#g.slots + 1] = {
          progress  = progress,
          threshold = a.threshold,
          unlocked  = unlocked,
          ilvl      = ilvl,
          level     = a.level,
        }
      end
    end
  end

  for _, g in pairs(groups) do
    table.sort(g.slots, function(s1, s2) return (s1.threshold or 0) < (s2.threshold or 0) end)
  end

  local TYPE = Enum and Enum.WeeklyRewardChestThresholdType
  local function pick(enumKey, fallback)
    local idx = fallback
    if TYPE and TYPE[enumKey] ~= nil then idx = TYPE[enumKey] end
    return groups[idx]
  end
  vault.mplus = pick("Activities", 1)
  vault.raid  = pick("Raid", 3)
  vault.world = pick("World", 6)

  if C_WeeklyRewards.HasAvailableRewards then
    local okr, hr = pcall(C_WeeklyRewards.HasAvailableRewards)
    vault.hasRewards = (okr and hr) and true or false
  end

  return vault
end

local function SnapshotMythicPlus()
  local m = { runs = 0, best = 0, rating = 0, keystoneLevel = nil, keystoneMap = nil }

  local rating = safeNum(C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore)
  if rating then m.rating = rating end

  if C_MythicPlus and C_MythicPlus.GetRunHistory then
    -- (semana atual, só concluídas)
    local ok, runs = pcall(C_MythicPlus.GetRunHistory, false, false)
    if ok and type(runs) == "table" then
      m.runs = #runs
      for _, r in ipairs(runs) do
        if type(r) == "table" and type(r.level) == "number" and r.level > m.best then
          m.best = r.level
        end
      end
    end
  end

  local lvl = safeNum(C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel)
  if lvl and lvl > 0 then
    m.keystoneLevel = lvl
    local mapID = safeNum(C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID)
    if mapID and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
      local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
      if ok and type(name) == "string" and name ~= "" then m.keystoneMap = name end
    end
  end

  return m
end

local function SnapshotRaids()
  local raids = {}
  if type(GetNumSavedInstances) ~= "function" or type(GetSavedInstanceInfo) ~= "function" then
    return raids
  end
  local okN, n = pcall(GetNumSavedInstances)
  if not okN or type(n) ~= "number" then return raids end

  for i = 1, n do
    local ok, name, lockoutId, reset, difficultyId, locked, extended,
          instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress
          = pcall(GetSavedInstanceInfo, i)
    if ok and isRaid and name and (numEncounters or 0) > 0 and (encounterProgress or 0) > 0 then
      raids[#raids + 1] = {
        name           = name,
        difficultyId   = difficultyId,
        difficultyName = difficultyName,
        total          = numEncounters or 0,
        progress       = encounterProgress or 0,
        maxPlayers     = maxPlayers,
      }
    end
  end

  table.sort(raids, function(a, b)
    local da, db = a.difficultyId or 0, b.difficultyId or 0
    if da ~= db then return da > db end
    return (a.name or "") < (b.name or "")
  end)
  return raids
end

-- ---------------------------------------------------------------------------
-- Zeragem (reset semanal e virada de season)
-- ---------------------------------------------------------------------------
local function ZeroWeekly(c)
  c.vault = nil
  if type(c.mplus) == "table" then
    c.mplus.runs = 0
    c.mplus.best = 0
  end
  c.raids = {}
end

local function ZeroSeason(c)
  c.vault = nil
  c.mplus = { runs = 0, best = 0, rating = 0 }
  c.raids = {}
end

-- No login: varre TODOS os chars e zera a semana dos vencidos (logar em 1 zera a semana de todos)
local function ApplyWeeklyResets()
  if not (DB and DB.chars) then return end
  local w = GetWeeklySeconds()
  if w <= 0 then return end -- API de reset ainda não pronta no login; não zerar a semana prematuramente
  local now = time()
  local weeklyResetAt = now + w
  for _, c in pairs(DB.chars) do
    if type(c) == "table" and c.weeklyResetAt and now >= c.weeklyResetAt then
      ZeroWeekly(c)
      c.weeklyResetAt = weeklyResetAt
    end
  end
end

-- Virada de season: zera vault/runs/rating dos chars cuja season salva difere da atual
local function ApplySeasonResets(season, currentKey)
  if not season or not (DB and DB.chars) then return end
  for key, c in pairs(DB.chars) do
    if type(c) == "table" and key ~= currentKey and c.season and c.season ~= season then
      ZeroSeason(c)
      c.season = season
    end
  end
end

-- ---------------------------------------------------------------------------
-- Snapshot idempotente do char logado
-- ---------------------------------------------------------------------------
local function Snapshot()
  if not DB then InitDB() end
  local key = CurrentKey()
  if not key then return end

  local name  = UnitName("player")
  local realm = GetNormalizedRealmName()
  local _, classFile = UnitClass("player")
  local level = UnitLevel("player")
  local overall, equipped = GetAverageItemLevel()

  local season = GetSeason()
  ApplySeasonResets(season, key)

  local now = time()
  local rec = DB.chars[key] or {}
  rec.name  = name
  rec.realm = realm
  rec.class = classFile
  if type(level) == "number" and level > 0 then rec.level = level end
  local il = equipped or overall
  if type(il) == "number" and il > 0 then rec.ilvl = math.floor(il + 0.5) end

  rec.vault = SnapshotVault()
  rec.mplus = SnapshotMythicPlus()
  rec.raids = SnapshotRaids()
  if season then rec.season = season end
  local wsec = GetWeeklySeconds(); if wsec > 0 then rec.weeklyResetAt = now + wsec end -- só grava com a API pronta (evita reset prematuro)
  local dsec = GetDailySeconds(); if dsec > 0 then rec.dailyResetAt = now + dsec end
  rec.updatedAt     = now

  DB.chars[key] = rec
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- API interna p/ a UI
-- ---------------------------------------------------------------------------
-- Lista ordenada: char logado primeiro, depois maior nível / maior ilvl / nome.
function KA.GetChars()
  local list = {}
  if not (DB and DB.chars) then return list end
  local cur = CurrentKey()
  for key, c in pairs(DB.chars) do
    if type(c) == "table" then
      list[#list + 1] = { key = key, data = c, isCurrent = (key == cur) }
    end
  end
  table.sort(list, function(a, b)
    if a.isCurrent ~= b.isCurrent then return a.isCurrent end
    local la, lb = a.data.level or 0, b.data.level or 0
    if la ~= lb then return la > lb end
    local ia, ib = a.data.ilvl or 0, b.data.ilvl or 0
    if ia ~= ib then return ia > ib end
    return (a.data.name or "") < (b.data.name or "")
  end)
  return list
end

function KA.RemoveChar(key)
  if DB and DB.chars and key then
    DB.chars[key] = nil
    KA.bus:Fire()
  end
end

-- ---------------------------------------------------------------------------
-- Eventos + debounce (snapshots coalescidos com C_Timer)
-- ---------------------------------------------------------------------------
local pending = false
local function ScheduleSnapshot()
  if pending then return end
  pending = true
  C_Timer.After(SNAPSHOT_DELAY, function()
    pending = false
    pcall(Snapshot)
  end)
end

local function RequestData()
  if C_MythicPlus then
    if C_MythicPlus.RequestMapInfo then pcall(C_MythicPlus.RequestMapInfo) end
    if C_MythicPlus.RequestRewards then pcall(C_MythicPlus.RequestRewards) end
  end
  if type(RequestRaidInfo) == "function" then pcall(RequestRaidInfo) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("WEEKLY_REWARDS_UPDATE")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
f:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("UPDATE_INSTANCE_INFO")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON then InitDB() end
  elseif event == "PLAYER_LOGIN" then
    InitDB()
    ApplyWeeklyResets()
    RequestData()
    ScheduleSnapshot()
  elseif event == "PLAYER_LOGOUT" then
    pcall(Snapshot)
  else
    ScheduleSnapshot()
  end
end)

-- ---------------------------------------------------------------------------
-- Slash: /kalts e /ka (abre/fecha a janela; "snapshot" força uma releitura)
-- ---------------------------------------------------------------------------
SLASH_KRONONALTS1 = "/kalts"
SLASH_KRONONALTS2 = "/ka"
SlashCmdList["KRONONALTS"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "snapshot" or msg == "refresh" then
    pcall(Snapshot)
    print(KA_PREFIX .. L.MSG_SNAPSHOT)
    return
  end
  if KA.Toggle then KA.Toggle() end
end
