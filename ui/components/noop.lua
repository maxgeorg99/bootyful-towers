---@class (exact) ui.components.NoopElement : Element
---@field new fun(box: ui.components.Box): ui.components.NoopElement
---@field init fun(self: ui.components.NoopElement, box: ui.components.Box)
local NoopElement = class("ui.components.NoopElement", { super = Element })

--- @param box ui.components.Box
function NoopElement:init(box) Element.init(self, box) end

function NoopElement:_render() end
function NoopElement:_update() end

return NoopElement
