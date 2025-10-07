local Hooks = require "vibes.hooks"

---@class vibes.EffectCard : vibes.Card
---@field new fun(opts: vibes.EffectCardOptions): vibes.EffectCard
---@field init fun(self: self, opts: vibes.EffectCardOptions)
---@field _type "vibes.effect-card"
---@field super vibes.Card
---@field duration EffectDuration
---@field hooks vibes.Hooks
local EffectCard = class("vibes.effect-card", { super = Card })
Encodable(
  EffectCard,
  "vibes.effect-card",
  "vibes.card.base",
  ---@param self vibes.EffectCard
  ---@return table<string, string>
  function(self)
    return {
      duration = tostring(self.duration),
    }
  end,
  ---@param self vibes.EffectCard
  ---@param data table<string, string>
  function(self, data) self.duration = EffectDuration[data.duration] end
)

---@class (exact) vibes.EffectCardOptions
---@field kind CardKind
---@field name string
---@field description string|function
---@field energy number
---@field texture vibes.Texture
---@field duration EffectDuration
---@field hooks vibes.effect.HookParams
---@field rarity Rarity
---@field after_play_kind? CardAfterPlay

--- Creates a new BaseEffectCard
---@param opts vibes.EffectCardOptions
function EffectCard:init(opts)
  opts.after_play_kind = opts.after_play_kind or CardAfterPlay.EXHAUST

  validate(opts, {
    kind = CardKind,
    name = "string",
    description = Either { "string", "function" },
    energy = "number",
    texture = "userdata",
    duration = EffectDuration,
    hooks = "table",
    rarity = Rarity,
    after_play_kind = CardAfterPlay,
  })

  Card.init(self, {
    kind = opts.kind,
    name = opts.name,
    description = opts.description,
    energy = opts.energy,
    texture = opts.texture,
    rarity = opts.rarity,
    after_play_kind = opts.after_play_kind or CardAfterPlay.EXHAUST,
  })

  self.duration = opts.duration
  self.hooks = Hooks.new(opts.hooks)
end

--- Called when an effect card is played
--- Override this method in subclasses to perform immediate actions when the card is played
function EffectCard:play_effect_card()
  -- Default implementation does nothing
  -- Subclasses can override this to perform actions when played
end

return EffectCard
