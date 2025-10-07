---@class vibes.TestTeej : vibes.BaseMode
local test_teej = {}

function test_teej:enter() end
function test_teej:update(dt) end
function test_teej:draw() end

return require("vibes.base-mode").wrap(test_teej)
