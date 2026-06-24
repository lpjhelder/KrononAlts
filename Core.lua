-- KrononAlts — painel cross-character de objetivos semanais do ecossistema Kronon.
-- Mostra, numa tabela, Grande Cofre, Mítica+ e lockouts de raide de cada personagem.
-- Core: i18n, SavedVariables, snapshot do char logado, detecção de reset e eventos.

local ADDON = "KrononAlts"
local KA_PREFIX = "|cff33ff33KrononAlts|r: "
local WEEK = 7 * 24 * 60 * 60
local SNAPSHOT_DELAY = 1 -- coalescência de snapshots (segundos)

-- ---------------------------------------------------------------------------
-- Moedas da season (EDITE AQUI a cada patch/season — bloco hardcoded fácil)
--   kind: "crest" (crests de upgrade, cap semanal) | "delve" (chave/fragmentos)
--   Validação em runtime: se GetCurrencyInfo der nil/sem nome, a moeda é ignorada.
--   Use `/kalts curr` in-game para LISTAR e confirmar os IDs desta season.
--   Midnight Season 1 (Interface 120007): Valorstones foram REMOVIDAS;
--   upgrade agora usa Dawncrest + ouro. São 5 tiers de crest (não 4).
-- ---------------------------------------------------------------------------
local SEASON_CURRENCIES = {
  { id = 3383, kind = "crest" }, -- Adventurer Dawncrest
  { id = 3341, kind = "crest" }, -- Veteran Dawncrest
  { id = 3343, kind = "crest" }, -- Champion Dawncrest
  { id = 3345, kind = "crest" }, -- Hero Dawncrest
  { id = 3347, kind = "crest" }, -- Myth Dawncrest
  { id = 3310, kind = "delve" }, -- Coffer Key Shards (cap semanal de Delve)
  { id = 3028, kind = "delve" }, -- Restored Coffer Key
}
-- Faixa varrida pelo `/kalts curr` p/ descobrir IDs de moeda nova (rede de segurança).
local CURRENCY_SCAN_MIN, CURRENCY_SCAN_MAX = 3300, 3400

-- ---------------------------------------------------------------------------
-- i18n inline (base EN + overlay ptBR/esES) — addon autocontido, sem libs
-- ---------------------------------------------------------------------------
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
  TT_REMOVE_HINT   = "Right-click for options (nickname, remove)",
  STALE            = "Snapshot is older than the current reset — log in on this character to refresh.",
  EMPTY            = "No characters yet. Log in on your alts to fill in the table.",
  NONE             = "—",
  DIFF_LFR         = "LFR",
  DIFF_N           = "N",
  DIFF_H           = "H",
  DIFF_M           = "M",
  REMOVE_CONFIRM   = "Remove %s from KrononAlts?",
  MSG_SNAPSHOT     = "snapshot updated.",
  COL_CREST        = "Crests",
  NEXT_TITLE       = "What's left:",
  NEXT_DONE        = "All vault slots filled.",
  NEXT_LINE        = "+%d to slot %d",
  HIDE_COMPLETED   = "Hide completed",
  MENU_SET_NICK    = "Set nickname",
  MENU_REMOVE      = "Remove",
  NICK_PROMPT      = "Nickname for %s:",
  TT_CREST_TITLE   = "Season currencies",
  TT_CREST_NONE    = "No tracked currencies yet — log in on this character.",
  TT_CREST_WEEKLY  = "this week",
  TT_SORT_HINT     = "Click to sort by this column",
  MM_TITLE         = "KrononAlts",
  MM_FULL          = "%d with a full vault",
  MM_REWARDS       = "%d with rewards waiting",
  MM_HINT          = "Left-click to open  •  drag to move",
  COL_ILVL         = "ilvl",
  COL_GOLD         = "Gold",
  SUMMARY          = "%d/%d vaults full  \194\183  %d with a reward waiting  \194\183  %d characters",
  SUMMARY_EMPTY    = "No characters yet — log in on your alts",
  DETAIL_VAULT     = "Great Vault",
  DETAIL_MPLUS     = "Mythic+ by dungeon",
  MPLUS_TODO       = "to do",
  DETAIL_RAID      = "Raid lockouts",
  DETAIL_CURR      = "Currencies & Crests",
  DETAIL_WEEKLY    = "Weeklies",
  DETAIL_PROF      = "Professions",
  WEEKLY_CONQUEST  = "Conquest",
  WEEKLY_CATALYST  = "Catalyst charges",
  PROF_KNOWLEDGE   = "Knowledge",
  PROF_OPEN_HINT   = "open the profession in-game to refresh",
  SLOT_FILLED      = "ilvl %d",
  SLOT_NEED        = "needs +%d",
  CLICK_EXPAND     = "Click a row to expand  \194\183  right-click for options",
  NO_DATA          = "No data yet — log in on this character.",
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
  TT_REMOVE_HINT   = "Clique-direito: opções (apelido, remover)",
  STALE            = "O snapshot é anterior ao reset atual — logue neste personagem para atualizar.",
  EMPTY            = "Nenhum personagem ainda. Logue nos seus alts para preencher a tabela.",
  REMOVE_CONFIRM   = "Remover %s do KrononAlts?",
  MSG_SNAPSHOT     = "snapshot atualizado.",
  NEXT_TITLE       = "O que falta:",
  NEXT_DONE        = "Todos os slots do cofre preenchidos.",
  NEXT_LINE        = "+%d p/ slot %d",
  HIDE_COMPLETED   = "Ocultar concluídos",
  MENU_SET_NICK    = "Definir apelido",
  MENU_REMOVE      = "Remover",
  NICK_PROMPT      = "Apelido para %s:",
  TT_CREST_TITLE   = "Moedas da season",
  TT_CREST_NONE    = "Nenhuma moeda rastreada ainda — logue neste personagem.",
  TT_CREST_WEEKLY  = "esta semana",
  TT_SORT_HINT     = "Clique para ordenar por esta coluna",
  MM_FULL          = "%d com cofre cheio",
  MM_REWARDS       = "%d com recompensa pendente",
  MM_HINT          = "Clique-esquerdo abre  •  arraste para mover",
  COL_GOLD         = "Ouro",
  SUMMARY          = "%d/%d cofres prontos  \194\183  %d com recompensa esperando  \194\183  %d personagens",
  SUMMARY_EMPTY    = "Nenhum personagem ainda — logue nos seus alts",
  DETAIL_VAULT     = "Grande Cofre",
  DETAIL_MPLUS     = "Mítica+ por masmorra",
  MPLUS_TODO       = "a fazer",
  DETAIL_RAID      = "Lockouts de raide",
  DETAIL_CURR      = "Moedas & Crests",
  DETAIL_WEEKLY    = "Semanais",
  DETAIL_PROF      = "Profissões",
  WEEKLY_CONQUEST  = "Conquista",
  WEEKLY_CATALYST  = "Cargas de Catalisador",
  PROF_KNOWLEDGE   = "Conhecimento",
  PROF_OPEN_HINT   = "abra a profissão no jogo para atualizar",
  SLOT_NEED        = "falta +%d",
  CLICK_EXPAND     = "Clique numa linha para expandir  \194\183  clique-direito: opções",
  NO_DATA          = "Sem dados ainda — logue neste personagem.",
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
  TT_REMOVE_HINT   = "Clic derecho: opciones (apodo, eliminar)",
  STALE            = "La instantánea es anterior al reinicio actual — entra con este personaje para actualizar.",
  EMPTY            = "Aún no hay personajes. Entra con tus alts para llenar la tabla.",
  REMOVE_CONFIRM   = "¿Eliminar %s de KrononAlts?",
  MSG_SNAPSHOT     = "instantánea actualizada.",
  NEXT_TITLE       = "Lo que falta:",
  NEXT_DONE        = "Todas las ranuras de la cámara llenas.",
  NEXT_LINE        = "+%d para ranura %d",
  HIDE_COMPLETED   = "Ocultar completados",
  MENU_SET_NICK    = "Definir apodo",
  MENU_REMOVE      = "Eliminar",
  NICK_PROMPT      = "Apodo para %s:",
  TT_CREST_TITLE   = "Monedas de la temporada",
  TT_CREST_NONE    = "Aún no hay monedas rastreadas — entra con este personaje.",
  TT_CREST_WEEKLY  = "esta semana",
  TT_SORT_HINT     = "Clic para ordenar por esta columna",
  MM_FULL          = "%d con cámara llena",
  MM_REWARDS       = "%d con recompensas pendientes",
  MM_HINT          = "Clic izquierdo abre  •  arrastra para mover",
  COL_GOLD         = "Oro",
  SUMMARY          = "%d/%d cámaras listas  \194\183  %d con recompensa esperando  \194\183  %d personajes",
  SUMMARY_EMPTY    = "Aún no hay personajes — entra con tus alts",
  DETAIL_VAULT     = "Gran Cámara",
  DETAIL_MPLUS     = "Mítica+ por mazmorra",
  MPLUS_TODO       = "por hacer",
  DETAIL_RAID      = "Bloqueos de banda",
  DETAIL_CURR      = "Monedas y Crests",
  DETAIL_WEEKLY    = "Semanales",
  DETAIL_PROF      = "Profesiones",
  WEEKLY_CONQUEST  = "Conquista",
  WEEKLY_CATALYST  = "Cargas de Catalizador",
  PROF_KNOWLEDGE   = "Conocimiento",
  PROF_OPEN_HINT   = "abre la profesión en el juego para actualizar",
  SLOT_NEED        = "falta +%d",
  CLICK_EXPAND     = "Clic en una fila para expandir  \194\183  clic derecho: opciones",
  NO_DATA          = "Aún sin datos — entra con este personaje.",
}

-- Base EN + overlay do locale do cliente; esMX cai em esES; chave inexistente
-- retorna a própria chave.
local L = {}
for k, v in pairs(EN) do L[k] = v end
local loc = GetLocale()
if loc == "esMX" then loc = "esES" end
local ov = (loc == "ptBR" and PT) or (loc == "esES" and ES) or nil
if ov then for k, v in pairs(ov) do L[k] = v end end
setmetatable(L, { __index = function(_, k) return k end })

-- ---------------------------------------------------------------------------
-- EventBus inline (mesma API: bus:Register(fn) / bus:Fire(...)) — notifica a UI
-- ---------------------------------------------------------------------------
local function NewEventBus()
  local cbs = {}
  return {
    Register = function(self, fn)
      if type(fn) == "function" then cbs[#cbs + 1] = fn end
    end,
    Fire = function(self, ...)
      for i = 1, #cbs do pcall(cbs[i], ...) end
    end,
  }
end

-- ---------------------------------------------------------------------------
-- Namespace público + barramento de eventos (notifica a UI)
-- ---------------------------------------------------------------------------
KrononAlts = KrononAlts or {}
local KA = KrononAlts
KA.L = L
KA.bus = NewEventBus()

-- ---------------------------------------------------------------------------
-- SavedVariables (account-wide)
--   KrononAltsDB = { version = 1, chars = { [charKey] = {...} } }
-- ---------------------------------------------------------------------------
local DB
local function InitDB()
  if type(KrononAltsDB) ~= "table" then KrononAltsDB = {} end
  if type(KrononAltsDB.chars) ~= "table" then KrononAltsDB.chars = {} end
  -- migração v2: a captura antiga de profissões pegava TODAS as do jogo; limpa as
  -- listas corrompidas (>2 entradas) pra re-capturar só as 2 do char ao logar nele.
  if KrononAltsDB.version ~= 2 then
    for _, c in pairs(KrononAltsDB.chars) do
      if type(c) == "table" and type(c.professions) == "table" and #c.professions > 2 then
        c.professions = nil
      end
    end
  end
  KrononAltsDB.version = 2
  if type(KrononAltsDB.minimap) ~= "table" then KrononAltsDB.minimap = { angle = 215, hide = false } end
  if KrononAltsDB.hideCompleted == nil then KrononAltsDB.hideCompleted = false end
  -- KrononAltsDB.sort = { key, dir } — nil = ordenação padrão (logado primeiro)
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

-- Moedas da season (account-wide por char): validadas em runtime, defensivas.
local function SnapshotCurrencies()
  local out = {}
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return out end
  for _, def in ipairs(SEASON_CURRENCIES) do
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, def.id)
    if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
      out[#out + 1] = {
        id        = def.id,
        kind      = def.kind,
        name      = info.name,
        quantity  = info.quantity or 0,
        max       = info.maxQuantity or 0,
        total     = info.totalEarned or 0,
        weekly    = info.quantityEarnedThisWeek or 0,
        weeklyMax = info.maxWeeklyQuantity or 0,
      }
    end
  end
  return out
end

-- Ouro do char (em cobre). PLAYER_MONEY força recaptura; 0 é tratado como
-- "ainda não pronto" e NÃO sobrescreve o valor salvo (evita zerar o alt).
local function SnapshotGold()
  if type(GetMoney) ~= "function" then return nil end
  local ok, money = pcall(GetMoney)
  if ok and type(money) == "number" and money > 0 then return money end
  return nil
end

-- Nome da spec ativa (defensivo — usado no painel de detalhe)
local function SnapshotSpec()
  if type(GetSpecialization) ~= "function" or type(GetSpecializationInfo) ~= "function" then
    return nil
  end
  local ok, idx = pcall(GetSpecialization)
  if not ok or type(idx) ~= "number" then return nil end
  local ok2, _, name = pcall(GetSpecializationInfo, idx)
  if ok2 and type(name) == "string" and name ~= "" then return name end
  return nil
end

-- Melhor chave POR MASMORRA NESTA SEMANA (não o recorde da season). Uma masmorra
-- sem run concluída na semana fica SEM nível (a UI mostra como "falta fazer"), pra
-- o jogador saber o que ainda dá pra correr antes do reset.
local function SnapshotMythicPlusByMap()
  local out = {}
  if not (C_ChallengeMode and C_ChallengeMode.GetMapTable) then return out end
  local ok, maps = pcall(C_ChallengeMode.GetMapTable)
  if not ok or type(maps) ~= "table" then return out end

  -- melhor nível CONCLUÍDO por masmorra NESTA SEMANA — GetRunHistory(false=só esta semana)
  local weekBest = {}
  if C_MythicPlus and C_MythicPlus.GetRunHistory then
    local ok0, runs = pcall(C_MythicPlus.GetRunHistory, false, false)
    if ok0 and type(runs) == "table" then
      for _, r in ipairs(runs) do
        if type(r) == "table" and type(r.mapChallengeModeID) == "number" and type(r.level) == "number" then
          local id = r.mapChallengeModeID
          if not weekBest[id] or r.level > weekBest[id] then weekBest[id] = r.level end
        end
      end
    end
  end

  for _, mapID in ipairs(maps) do
    if type(mapID) == "number" then
      local entry = { mapID = mapID }
      if C_ChallengeMode.GetMapUIInfo then
        local ok2, name, _, _, texture = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
        if ok2 then
          if type(name) == "string" and name ~= "" then entry.name = name end
          if type(texture) == "number" and texture > 0 then entry.texture = texture end
        end
      end
      local lvl = weekBest[mapID]
      if type(lvl) == "number" and lvl > 0 then entry.level = lvl; entry.done = true end
      out[#out + 1] = entry
    end
  end
  -- as que FALTAM (sem nível esta semana) primeiro, depois por nível desc, depois nome
  table.sort(out, function(a, b)
    local la, lb = a.level or 0, b.level or 0
    if (la == 0) ~= (lb == 0) then return la == 0 end
    if la ~= lb then return la > lb end
    return (a.name or "") < (b.name or "")
  end)
  return out
end

-- Semanais lidas a frio (leitura via C_CurrencyInfo). Defensivo: só grava o que
-- vier com nome válido. IDs do Midnight S1 podem variar — validar com /kalts curr.
local function SnapshotWeeklies()
  local out = {}
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return out end
  local function read(id)
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
      return info
    end
  end
  local conq = read(1602) -- Conquest (cap semanal de PvP)
  if conq then
    out.conquest = {
      name   = conq.name,
      earned = conq.quantityEarnedThisWeek or 0,
      cap    = conq.maxWeeklyQuantity or 0,
      total  = conq.quantity or 0,
    }
  end
  local cat = read(2167) -- Catalyst Charges (Warband-wide)
  if cat then
    out.catalyst = {
      name     = cat.name,
      quantity = cat.quantity or 0,
      max      = cat.maxQuantity or 0,
    }
  end
  return out
end

-- Profissões: nível + conhecimento não-gasto (leitura fria) e concentração
-- quando disponível. Só lê se as tradeskills estiverem carregadas; caso vazio,
-- mantém o snapshot anterior (não sobrescreve). Totalmente defensivo.
local function SnapshotProfessions()
  local out = {}
  if not (GetProfessions and GetProfessionInfo) then return out end
  -- GetProfessions() devolve os índices SÓ das profissões que o personagem TEM
  -- (prof1, prof2, arqueologia, pesca, culinária). Pegamos só as 2 PRINCIPAIS.
  local profIdx = { GetProfessions() }
  for i = 1, 2 do
    local idx = profIdx[i]
    if type(idx) == "number" then
      local name, _, skillLevel, maxSkillLevel, _, _, skillLine = GetProfessionInfo(idx)
      if type(name) == "string" and name ~= "" then
        local entry = { name = name, skillLine = skillLine }
        if type(skillLevel) == "number" then entry.skillLevel = skillLevel end
        if type(maxSkillLevel) == "number" then entry.maxSkillLevel = maxSkillLevel end
        -- Conhecimento não-gasto da season (currency oculta por profissão) — defensivo
        if type(skillLine) == "number" and C_ProfSpecs and C_ProfSpecs.GetCurrencyInfoForSkillLine then
          local ok3, ci = pcall(C_ProfSpecs.GetCurrencyInfoForSkillLine, skillLine)
          if ok3 and type(ci) == "table" then
            local cid = ci.currencyID or ci.numKnowledgeID or ci.currencyType
            if type(cid) == "number" and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
              local ok4, kinfo = pcall(C_CurrencyInfo.GetCurrencyInfo, cid)
              if ok4 and type(kinfo) == "table" and type(kinfo.quantity) == "number" then
                entry.knowledge = kinfo.quantity
              end
            end
          end
        end
        out[#out + 1] = entry
      end
    end
  end
  return out
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
  -- progresso semanal das moedas (crests/shards) também zera no reset
  if type(c.currencies) == "table" then
    for _, cur in ipairs(c.currencies) do
      if type(cur) == "table" then cur.weekly = 0 end
    end
  end
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
  rec.currencies = SnapshotCurrencies()

  -- Campos que dependem de dados que podem não estar carregados ainda:
  -- só sobrescrevem o snapshot anterior quando há valor novo (não zeram o alt).
  local gold = SnapshotGold(); if gold then rec.gold = gold end
  local spec = SnapshotSpec(); if spec then rec.spec = spec end
  local maps = SnapshotMythicPlusByMap(); if #maps > 0 then rec.mplusMaps = maps end
  rec.professions = SnapshotProfessions() -- sempre reflete o char logado (limpa lista antiga)
  local weeklies = SnapshotWeeklies(); if next(weeklies) then rec.weeklies = weeklies end

  if season then rec.season = season end
  local wsec = GetWeeklySeconds(); if wsec > 0 then rec.weeklyResetAt = now + wsec end -- só grava com a API pronta (evita reset prematuro)
  local dsec = GetDailySeconds(); if dsec > 0 then rec.dailyResetAt = now + dsec end
  rec.updatedAt     = now

  DB.chars[key] = rec
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- Derivações para a UI (próxima ação, conclusão, resumo, métricas de sort)
-- ---------------------------------------------------------------------------
local function vaultFull(d)
  local v = d and d.vault
  if type(v) ~= "table" then return false end
  local function full(t) return t and (t.filled or 0) >= 3 end
  return full(v.mplus) and full(v.raid) and full(v.world)
end

-- "Completo" = cofre 3/3/3 e sem recompensa pendente (usado pelo "ocultar concluídos")
function KA.IsComplete(d)
  if type(d) ~= "table" then return false end
  if d.vault and d.vault.hasRewards then return false end
  return vaultFull(d)
end

-- Próxima ação por trilha: 1º slot ainda não desbloqueado → quanto falta + nº do slot
function KA.GetNextActions(v)
  local out = {}
  if type(v) ~= "table" then return out end
  local function scan(t, label)
    if type(t) ~= "table" or type(t.slots) ~= "table" then return end
    for i, s in ipairs(t.slots) do
      if not s.unlocked then
        local need = (s.threshold or 0) - (s.progress or 0)
        if need < 0 then need = 0 end
        out[#out + 1] = { track = label, need = need, slot = i }
        return
      end
    end
  end
  scan(v.mplus, L.TRACK_MPLUS)
  scan(v.raid,  L.TRACK_RAID)
  scan(v.world, L.TRACK_WORLD)
  return out
end

-- Resumo p/ o tooltip do botão de minimapa
function KA.GetSummary()
  local full, rewards, total = 0, 0, 0
  if DB and DB.chars then
    for _, c in pairs(DB.chars) do
      if type(c) == "table" then
        total = total + 1
        if vaultFull(c) then full = full + 1 end
        if c.vault and c.vault.hasRewards then rewards = rewards + 1 end
      end
    end
  end
  return { full = full, rewards = rewards, total = total }
end

local function crestSum(d)
  local s = 0
  if type(d.currencies) == "table" then
    for _, c in ipairs(d.currencies) do
      if c.kind == "crest" and type(c.quantity) == "number" then s = s + c.quantity end
    end
  end
  return s
end

local function vaultFilledSum(d)
  local v = d.vault
  if type(v) ~= "table" then return 0 end
  local function f(t) return (t and t.filled) or 0 end
  return f(v.mplus) + f(v.raid) + f(v.world)
end

local function raidMetric(d)
  local top = d.raids and d.raids[1]
  if not top then return -1 end
  return (top.difficultyId or 0) * 1000 + (top.progress or 0)
end

-- ---------------------------------------------------------------------------
-- Preferências persistidas (ordenação + ocultar concluídos)
-- ---------------------------------------------------------------------------
function KA.GetSort() return (DB and DB.sort) or nil end

function KA.SetSort(key)
  if not (DB and key) then return end
  local s = DB.sort
  if type(s) ~= "table" then s = {}; DB.sort = s end
  if s.key == key then
    s.dir = (s.dir == "asc") and "desc" or "asc"
  else
    s.key = key
    s.dir = (key == "name") and "asc" or "desc"
  end
  KA.bus:Fire()
end

function KA.GetHideCompleted() return DB and DB.hideCompleted end

function KA.SetHideCompleted(on)
  if not DB then return end
  DB.hideCompleted = on and true or false
  KA.bus:Fire()
end

function KA.SetNick(key, nick)
  if not (DB and DB.chars and DB.chars[key]) then return end
  if type(nick) == "string" then nick = nick:gsub("^%s+", ""):gsub("%s+$", "") end
  if not nick or nick == "" then nick = nil end
  DB.chars[key].nick = nick
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- API interna p/ a UI
-- ---------------------------------------------------------------------------
local SortMetrics = {
  vault  = function(d) return vaultFilledSum(d) end,
  mplus  = function(d) return (d.mplus and d.mplus.runs) or 0 end,
  rating = function(d) return (d.mplus and d.mplus.rating) or 0 end,
  crest  = function(d) return crestSum(d) end,
  raid   = function(d) return raidMetric(d) end,
  ilvl   = function(d) return d.ilvl or 0 end,
  gold   = function(d) return d.gold or 0 end,
}

-- Ordenação padrão (sem critério escolhido): char logado primeiro, depois nível/ilvl/nome
local function legacyLess(a, b)
  if a.isCurrent ~= b.isCurrent then return a.isCurrent end
  local la, lb = a.data.level or 0, b.data.level or 0
  if la ~= lb then return la > lb end
  local ia, ib = a.data.ilvl or 0, b.data.ilvl or 0
  if ia ~= ib then return ia > ib end
  return (a.data.name or "") < (b.data.name or "")
end

-- Lista filtrada (ocultar concluídos) + ordenada pelo critério salvo.
-- O char logado nunca é ocultado e mantém o destaque visual (na UI).
function KA.GetChars()
  local list = {}
  if not (DB and DB.chars) then return list end
  local cur = CurrentKey()
  local hide = DB.hideCompleted
  for key, c in pairs(DB.chars) do
    if type(c) == "table" then
      local isCurrent = (key == cur)
      if not (hide and not isCurrent and KA.IsComplete(c)) then
        list[#list + 1] = { key = key, data = c, isCurrent = isCurrent }
      end
    end
  end

  local sort = DB.sort
  if type(sort) == "table" and sort.key then
    local asc = (sort.dir == "asc")
    if sort.key == "name" then
      table.sort(list, function(a, b)
        local na = (a.data.nick or a.data.name or ""):lower()
        local nb = (b.data.nick or b.data.name or ""):lower()
        if na == nb then return legacyLess(a, b) end
        if asc then return na < nb end
        return na > nb
      end)
    else
      local metric = SortMetrics[sort.key]
      if metric then
        table.sort(list, function(a, b)
          local va, vb = metric(a.data), metric(b.data)
          if va == vb then return legacyLess(a, b) end
          if asc then return va < vb end
          return va > vb
        end)
      else
        table.sort(list, legacyLess)
      end
    end
  else
    table.sort(list, legacyLess)
  end
  return list
end

function KA.RemoveChar(key)
  if DB and DB.chars and key then
    DB.chars[key] = nil
    KA.bus:Fire()
  end
end

-- Lista as moedas configuradas + varredura de descoberta (debug: /kalts curr)
function KA.PrintCurrencies()
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
    print(KA_PREFIX .. "C_CurrencyInfo indisponível.")
    return
  end
  print(KA_PREFIX .. "SEASON_CURRENCIES (configuradas):")
  for _, def in ipairs(SEASON_CURRENCIES) do
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, def.id)
    if ok and type(info) == "table" and info.name and info.name ~= "" then
      print(string.format("  [%d] %s — %s/%s  (semana %s/%s) <%s>",
        def.id, info.name,
        tostring(info.quantity or 0), tostring(info.maxQuantity or 0),
        tostring(info.quantityEarnedThisWeek or 0), tostring(info.maxWeeklyQuantity or 0),
        def.kind or "?"))
    else
      print(string.format("  [%d] sem dados — ID pode estar errado nesta season", def.id))
    end
  end
  print(string.format("%sDescoberta (IDs %d-%d com cap semanal):",
    KA_PREFIX, CURRENCY_SCAN_MIN, CURRENCY_SCAN_MAX))
  local found = 0
  for id = CURRENCY_SCAN_MIN, CURRENCY_SCAN_MAX do
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok and type(info) == "table" and info.name and info.name ~= ""
       and (info.maxWeeklyQuantity or 0) > 0 then
      print(string.format("  [%d] %s — %s/%s (semana %s/%s)",
        id, info.name,
        tostring(info.quantity or 0), tostring(info.maxQuantity or 0),
        tostring(info.quantityEarnedThisWeek or 0), tostring(info.maxWeeklyQuantity or 0)))
      found = found + 1
    end
  end
  if found == 0 then print("  (nada encontrado nessa faixa)") end
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
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON then InitDB() end
  elseif event == "PLAYER_LOGIN" then
    InitDB()
    ApplyWeeklyResets()
    RequestData()
    ScheduleSnapshot()
    if KA.InitMinimap then pcall(KA.InitMinimap) end
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
  elseif msg == "curr" or msg == "currency" or msg == "currencies" then
    KA.PrintCurrencies()
    return
  end
  if KA.Toggle then KA.Toggle() end
end
