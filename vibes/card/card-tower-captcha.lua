local sprites = require("vibes.asset").sprites

local TowerCard = require "vibes.card.base-tower-card"

---@class (exact) vibes.TowerCaptchaCardOptions

---@class vibes.TowerCaptchaCard : vibes.TowerCard
---@field new fun(opts: vibes.TowerCaptchaCardOptions): vibes.TowerCaptchaCard
---@field init fun(self: vibes.TowerCaptchaCard, opts: vibes.TowerCaptchaCardOptions)
---@field tower vibes.CaptchaTower
local TowerCaptchaCard =
  class("vibes.tower-captcha-card", { super = TowerCard })

--- Creates a new Captcha Tower card
---@return vibes.TowerCaptchaCard
function TowerCaptchaCard:init(opts)
  validate(opts, {})

  TowerCard.init(self, {
    name = "Captcha Tower",
    description = "Click to emit a blast that damages nearby enemies.",
    energy = 1,
    texture = sprites.card_tower_archer,
    rarity = Rarity.UNCOMMON,
    tower = require("vibes.tower.tower-captcha").new(),
  })
end

return TowerCaptchaCard
