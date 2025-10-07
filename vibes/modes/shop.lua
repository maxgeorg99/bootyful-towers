---@class vibes.ShopMode : vibes.BaseMode
---@field ui components.shop.UI
local shop_mode = {
  name = ModeName.SHOP,
  random = require("vibes.engine.random").new { name = "shop" },
}

function shop_mode:update() end

function shop_mode:draw() end

function shop_mode:enter()
  local ShopUI = require "ui.components.shop"
  self.ui = ShopUI.new {}
  UI.root:append_child(self.ui)
  State.debug = true
end

function shop_mode:exit()
  self:reset_state()
  UI.root:remove_child(self.ui)
end

--- Reset the shop state completely
function shop_mode:reset_state() end
function shop_mode:textinput(text) _ = text end
function shop_mode:mousemoved() end
function shop_mode:mousepressed() end
function shop_mode:mousereleased() end

return require("vibes.base-mode").wrap(shop_mode)
