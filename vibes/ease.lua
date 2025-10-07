-- easing.lua
-- Tiny, fast easing library for games: return a table of t->eased(t) functions.

local E = {}

-- localize math
local m = math
local sin, cos, pow, sqrt, abs, pi = m.sin, m.cos, m.pow, m.sqrt, m.abs, m.pi

-- Clamp helper (keeps fns robust to slight under/overshoot like dt accumulation)
local function clamp01(x)
  if x < 0 then
    return 0
  end
  if x > 1 then
    return 1
  end
  return x
end

-- Linear ----------------------------------------------------------
--- Straight line; constant speed. Use for debugging or blends that shouldn't ease.
--- @param t number @return number
function E.linear(t)
  t = clamp01(t)
  return t
end

-- Quadratic -------------------------------------------------------
--- Ease In Quad: accelerates with t^2; soft start, snappy end. Use for UI pop-ins.
--- @param t number @return number
function E.quadIn(t)
  t = clamp01(t)
  return t * t
end

--- Ease Out Quad: decelerates; fast start, gentle settle. Good for exits/snaps.
--- @param t number @return number
function E.quadOut(t)
  t = clamp01(t)
  return 1 - (1 - t) * (1 - t)
end

--- Ease InOut Quad: slow→fast→slow; common default for movement/opacity.
--- @param t number @return number
function E.quadInOut(t)
  t = clamp01(t)
  if t < 0.5 then
    return 2 * t * t
  end
  t = 1 - t
  return 1 - 2 * t * t
end

-- Cubic -----------------------------------------------------------
--- In Cubic: stronger accel (t^3). Use when Quad feels too gentle.
--- @param t number @return number
function E.cubicIn(t)
  t = clamp01(t)
  return t * t * t
end

--- Out Cubic: stronger decel; widely used for smooth finishes.
--- @param t number @return number
function E.cubicOut(t)
  t = clamp01(t)
  t = 1 - t
  return 1 - t * t * t
end

--- InOut Cubic: classic “ease” feel; great general-purpose motion.
--- @param t number @return number
function E.cubicInOut(t)
  t = clamp01(t)
  if t < 0.5 then
    return 4 * t * t * t
  end
  t = 1 - t
  return 1 - 4 * t * t * t
end

-- Quartic ---------------------------------------------------------
--- In Quart: very quick ramp-up.
--- @param t number @return number
function E.quartIn(t)
  t = clamp01(t)
  local t2 = t * t
  return t2 * t2
end

--- Out Quart: very gentle landings.
--- @param t number @return number
function E.quartOut(t)
  t = clamp01(t)
  t = 1 - t
  local t2 = t * t
  return 1 - t2 * t2
end

--- InOut Quart: punchy but smooth midpoint.
--- @param t number @return number
function E.quartInOut(t)
  t = clamp01(t)
  if t < 0.5 then
    local x = 2 * t
    local x2 = x * x
    return 0.5 * x2 * x2
  else
    local x = 2 * (1 - t)
    local x2 = x * x
    return 1 - 0.5 * x2 * x2
  end
end

-- Quintic ---------------------------------------------------------
--- In Quint: very aggressive accel; use for “whoosh” intros.
--- @param t number @return number
function E.quintIn(t)
  t = clamp01(t)
  local t2 = t * t
  return t2 * t2 * t
end

--- Out Quint: very soft final ease; premium feel.
--- @param t number @return number
function E.quintOut(t)
  t = clamp01(t)
  t = 1 - t
  local t2 = t * t
  return 1 - t2 * t2 * t
end

--- InOut Quint: strong S-curve with silky ends.
--- @param t number @return number
function E.quintInOut(t)
  t = clamp01(t)
  if t < 0.5 then
    local x = 2 * t
    local x2 = x * x
    return 0.5 * x2 * x2 * x
  else
    local x = 2 * (1 - t)
    local x2 = x * x
    return 1 - 0.5 * x2 * x2 * x
  end
end

-- Sine ------------------------------------------------------------
--- In Sine: cosine-based slow start; natural, subtle.
--- @param t number @return number
function E.sineIn(t)
  t = clamp01(t)
  return 1 - cos((t * pi) / 2)
end

--- Out Sine: sine-based soft landing; great for UI fades.
--- @param t number @return number
function E.sineOut(t)
  t = clamp01(t)
  return sin((t * pi) / 2)
end

--- InOut Sine: gentle S-curve; safe default for many cases.
--- @param t number @return number
function E.sineInOut(t)
  t = clamp01(t)
  return 0.5 * (1 - cos(pi * t))
end

-- Exponential -----------------------------------------------------
--- In Expo: almost zero, then rockets; dramatic reveals.
--- @param t number @return number
function E.expoIn(t)
  t = clamp01(t)
  if t == 0 then
    return 0
  end
  return pow(2, 10 * (t - 1))
end

--- Out Expo: blazes then coasts; impactful exits.
--- @param t number @return number
function E.expoOut(t)
  t = clamp01(t)
  if t == 1 then
    return 1
  end
  return 1 - pow(2, -10 * t)
end

--- InOut Expo: extreme S-curve; cinematic motions.
--- @param t number @return number
function E.expoInOut(t)
  t = clamp01(t)
  if t == 0 then
    return 0
  end
  if t == 1 then
    return 1
  end
  if t < 0.5 then
    return 0.5 * pow(2, 20 * t - 10)
  end
  return 1 - 0.5 * pow(2, -20 * t + 10)
end

-- Circular --------------------------------------------------------
--- In Circ: follows circle arc; softly ramps up.
--- @param t number @return number
function E.circIn(t)
  t = clamp01(t)
  return 1 - sqrt(1 - t * t)
end

--- Out Circ: long gentle decel tail.
--- @param t number @return number
function E.circOut(t)
  t = clamp01(t)
  t = t - 1
  return sqrt(1 - t * t)
end

--- InOut Circ: natural S-curve, heavier middle speed.
--- @param t number @return number
function E.circInOut(t)
  t = clamp01(t)
  if t < 0.5 then
    local x = 1 - 4 * t * t
    return 0.5 * (1 - sqrt(x))
  else
    local u = 2 * t - 2
    return 0.5 * (sqrt(1 - u * u) + 1)
  end
end

-- Back (overshoot once) ------------------------------------------
-- k controls overshoot; classic is ~1.70158 (s = 1.70158).
local k = 1.70158

--- In Back: dips backward then accelerates; playful starts.
--- @param t number @return number
function E.backIn(t)
  t = clamp01(t)
  return t * t * ((k + 1) * t - k)
end

--- Out Back: overshoots then settles; bouncy finishes without oscillation.
--- @param t number @return number
function E.backOut(t)
  t = clamp01(t)
  t = t - 1
  return 1 + t * t * ((k + 1) * t + k)
end

--- InOut Back: overshoot both ends; expressive UI moves.
--- @param t number @return number
function E.backInOut(t)
  t = clamp01(t)
  local s = k * 1.525
  if t < 0.5 then
    local x = 2 * t
    return 0.5 * (x * x * ((s + 1) * x - s))
  else
    local x = 2 * t - 2
    return 0.5 * (x * x * ((s + 1) * x + s) + 2)
  end
end

-- Elastic (oscillates) -------------------------------------------
-- Tuned for a good default wobble without params.
--- In Elastic: springy start; use sparingly for attention.
--- @param t number @return number
function E.elasticIn(t)
  t = clamp01(t)
  if t == 0 or t == 1 then
    return t
  end
  return -pow(2, 10 * (t - 1)) * sin((t - 1.075) * (2 * pi) / 0.3)
end

--- Out Elastic: overshoots with oscillations; playful drops.
--- @param t number @return number
function E.elasticOut(t)
  t = clamp01(t)
  if t == 0 or t == 1 then
    return t
  end
  return 1 + pow(2, -10 * t) * sin((t - 0.075) * (2 * pi) / 0.3)
end

--- InOut Elastic: strong spring both sides.
--- @param t number @return number
function E.elasticInOut(t)
  t = clamp01(t)
  if t == 0 or t == 1 then
    return t
  end
  t = t * 2
  if t < 1 then
    return -0.5 * pow(2, 10 * (t - 1)) * sin((t - 1.1125) * (2 * pi) / 0.45)
  else
    t = t - 1
    return 1 + 0.5 * pow(2, -10 * t) * sin((t - 0.1125) * (2 * pi) / 0.45)
  end
end

-- Bounce (piecewise) ---------------------------------------------
-- Helper for bounce shape (out variant)
local function bounceOutCore(t)
  local n1, d1 = 7.5625, 2.75
  if t < 1 / d1 then
    return n1 * t * t
  elseif t < 2 / d1 then
    t = t - 1.5 / d1
    return n1 * t * t + 0.75
  elseif t < 2.5 / d1 then
    t = t - 2.25 / d1
    return n1 * t * t + 0.9375
  else
    t = t - 2.625 / d1
    return n1 * t * t + 0.984375
  end
end

--- In Bounce: reverse of out; quick stiction then pops.
--- @param t number @return number
function E.bounceIn(t)
  t = clamp01(t)
  return 1 - bounceOutCore(1 - t)
end

--- Out Bounce: classic cartoony bounces; impacts/landings.
--- @param t number @return number
function E.bounceOut(t)
  t = clamp01(t)
  return bounceOutCore(t)
end

--- InOut Bounce: bounce at both ends; stylized transitions.
--- @param t number @return number
function E.bounceInOut(t)
  t = clamp01(t)
  if t < 0.5 then
    return 0.5 * (1 - bounceOutCore(1 - 2 * t))
  else
    return 0.5 * bounceOutCore(2 * t - 1) + 0.5
  end
end

-- Aliases (common shorthand)
E.inQuad, E.outQuad, E.inOutQuad = E.quadIn, E.quadOut, E.quadInOut
E.inCubic, E.outCubic, E.inOutCubic = E.cubicIn, E.cubicOut, E.cubicInOut
E.inQuart, E.outQuart, E.inOutQuart = E.quartIn, E.quartOut, E.quartInOut
E.inQuint, E.outQuint, E.inOutQuint = E.quintIn, E.quintOut, E.quintInOut
E.inSine, E.outSine, E.inOutSine = E.sineIn, E.sineOut, E.sineInOut
E.inExpo, E.outExpo, E.inOutExpo = E.expoIn, E.expoOut, E.expoInOut
E.inCirc, E.outCirc, E.inOutCirc = E.circIn, E.circOut, E.circInOut
E.inBack, E.outBack, E.inOutBack = E.backIn, E.backOut, E.backInOut
E.inElastic, E.outElastic, E.inOutElastic =
  E.elasticIn, E.elasticOut, E.elasticInOut
E.inBounce, E.outBounce, E.inOutBounce = E.bounceIn, E.bounceOut, E.bounceInOut

return E
