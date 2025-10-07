---@diagnostic disable

-- anim.lua
-- Minimal animation system: keyframed clips + ad-hoc tweens, with weighted blending.
-- LuaLS annotations included.

---@alias EaseFunc fun(t:number):number
---@alias AnimValue number|boolean|table<string, number>|number[]

---@class AnimKeyframe
---@field time number
---@field value AnimValue
---@field ease EaseFunc|nil

---@class AnimChannel
---@field param string
---@field keys AnimKeyframe[]

---@class AnimClip
---@field name string
---@field length number
---@field channels table<string, AnimChannel>

---@class AnimTrack
---@field clip AnimClip
---@field time number
---@field speed number
---@field weight number
---@field loop boolean
---@field enabled boolean|nil

---@class AnimLerp
---@field param string
---@field start AnimValue
---@field target AnimValue
---@field elapsed number
---@field duration number
---@field ease EaseFunc|nil
---@field weight number

---@class AnimParamConfig
---@field initial AnimValue Initial value for the parameter
---@field rate number? Animation rate (units per second) - for proportional drive
---@field velocity number? Constant velocity (units per second) - for fixed-speed movement
---@field stabilize_threshold number? Threshold for snapping to target

---@class Animator
---@field params table<string, AnimValue>
---@field param_configs table<string, AnimParamConfig>
---@field tracks AnimTrack[]
---@field lerps AnimLerp[]

local anim = {}

-- Easing ----------------------------------------------------------------------

---@class Ease
local Ease = {
  linear = function(t) return t end,
  smoothstep = function(t) return t * t * (3 - 2 * t) end,
  easeInOutCubic = function(t)
    if t < 0.5 then
      return 4 * t * t * t
    end
    return 1 - ((-2 * t + 2) ^ 3) / 2
  end,
  easeOut = function(t, k)
    t = (t < 0) and 0 or (t > 1 and 1 or t)
    k = k or 2
    return 1 - (1 - t) ^ k
  end,
}
anim.Ease = Ease

-- Utils -----------------------------------------------------------------------

--- Interpolate between two animation values.
---@param a AnimValue: Start value
---@param b AnimValue: End value
---@param t number: Interpolation factor (0-1)
---@return AnimValue
local function lerp_value(a, b, t)
  local ta, tb = type(a), type(b)
  if tb == "number" then
    a = (ta == "number") and a or 0
    ---@cast a number
    return a + (b - a) * t
  end
  if tb == "table" then
    local out = {}
    local at = (ta == "table") and a or {}
    ---@cast at table

    -- First copy all existing fields from 'a' to preserve them
    for k, av in pairs(at) do
      out[k] = av
    end

    -- Then interpolate only the fields that exist in 'b' (target)
    for k, bv in pairs(b) do
      if bv ~= nil then -- Skip nil values in target
        local av = at[k] or 0
        -- Only interpolate numeric values, preserve non-numeric values
        if type(av) == "number" and type(bv) == "number" then
          out[k] = av + (bv - av) * t
        else
          -- For non-numeric values, use the target value directly
          out[k] = bv
        end
      end
    end
    return out
  end
  return b
end

--- Clone an animation value.
---@param v AnimValue: Value to clone
---@return AnimValue
local function clone_value(v)
  if type(v) ~= "table" then
    return v
  end
  local out = {}
  for k, x in pairs(v) do
    out[k] = x
  end
  return out
end

---@param v AnimValue
---@param w number
---@param acc AnimValue?
---@return AnimValue?
local function accum_weighted(v, w, acc)
  if v == nil or w == 0 then
    return acc or v
  end
  if type(v) == "number" then
    local base = (type(acc) == "number") and acc or 0
    return base + v * w
  end
  local out = (type(acc) == "table") and acc or {}
  ---@cast out table
  for k, c in pairs(v) do
    out[k] = (out[k] or 0) + c * w
  end
  return out
end

---@param v AnimValue?
---@param wsum number
---@return AnimValue?
local function divide_weight(v, wsum)
  if wsum == 0 or v == nil then
    return v
  end
  if type(v) == "number" then
    return v / wsum
  end
  local out = {}
  for k, c in pairs(v) do
    out[k] = c / wsum
  end
  return out
end

--- Sort keyframes by time in place.
---@param keys AnimKeyframe[]: Keyframes to sort
---@return AnimKeyframe[]
local function sort_keys_inplace(keys)
  table.sort(keys, function(a, b) return a.time < b.time end)
  return keys
end

-- Sampling --------------------------------------------------------------------

--- Sample a channel at a specific time.
---@param ch AnimChannel: Channel to sample
---@param t number: Time to sample at
---@return AnimValue
local function sample_channel(ch, t)
  local keys = ch.keys
  local n = #keys
  if n == 0 then
    return 0
  end
  if t <= keys[1].time then
    return keys[1].value
  end
  if t >= keys[n].time then
    return keys[n].value
  end

  for i = 1, n - 1 do
    local k1, k2 = keys[i], keys[i + 1]
    if t >= k1.time and t <= k2.time then
      local span = (k2.time - k1.time)
      local u = (span == 0) and 1 or (t - k1.time) / span
      local ease = k2.ease or Ease.linear
      return lerp_value(k1.value, k2.value, ease(u))
    end
  end
  return keys[n].value
end

--- Sample all channels in a clip at a specific time.
---@param clip AnimClip: Clip to sample
---@param t number: Time to sample at
---@return table<string, AnimValue>
local function sample_clip(clip, t)
  local out = {}
  for pname, ch in pairs(clip.channels) do
    out[pname] = sample_channel(ch, t)
  end
  return out
end

---@param param_name string
---@param config AnimParamConfig
---@return AnimValue initial
---@return AnimParamConfig normalized
local function prepare_param_config(param_name, config)
  if type(config) ~= "table" then
    error(
      ("anim: parameter '%s' must be configured with a table"):format(
        param_name
      )
    )
  end

  local function validate_initial(_, value)
    if value == nil then
      return
    end

    local value_type = type(value)
    if
      value_type == "number"
      or value_type == "boolean"
      or value_type == "table"
    then
      return
    end

    error(
      ("anim: parameter '%s' has unsupported initial type '%s'"):format(
        param_name,
        value_type
      )
    )
  end

  validate(config, {
    initial = validate_initial,
    rate = "number?",
    velocity = "number?",
    stabilize_threshold = "number?",
  })

  if config.initial == nil then
    error(
      ("anim: parameter '%s' requires an 'initial' value"):format(param_name)
    )
  end

  if config.rate == nil and config.velocity == nil then
    error(
      ("anim: parameter '%s' requires either 'rate' or 'velocity'"):format(
        param_name
      )
    )
  end

  if config.hysteresis_high ~= nil or config.hysteresis_low ~= nil then
    error(
      ("anim: parameter '%s' no longer supports hysteresis configuration"):format(
        param_name
      )
    )
  end

  local initial_clone = clone_value(config.initial)

  return initial_clone,
    {
      initial = clone_value(initial_clone),
      rate = config.rate,
      velocity = config.velocity,
      stabilize_threshold = config.stabilize_threshold,
    }
end

-- Builders --------------------------------------------------------------------

--- Create a channel.
---@param param string: Parameter name
---@param keys AnimKeyframe[]: Array of keyframes
---@return AnimChannel
function anim.channel(param, keys)
  return { param = param, keys = sort_keys_inplace(keys or {}) }
end

--- Create a clip.
---@param name string: Clip name
---@param length number: Clip length in seconds
---@param channels table<string, AnimChannel>: Channels by parameter name
---@return AnimClip
function anim.clip(name, length, channels)
  return { name = name, length = length, channels = channels or {} }
end

--- Create an Animator.
---@param config table<string, AnimParamConfig>? Parameter configurations keyed by parameter name
---@return Animator
function anim.new(config)
  local params = {}
  local param_configs = {}

  if config then
    for param_name, value in pairs(config) do
      local initial, normalized = prepare_param_config(param_name, value)
      params[param_name] = initial
      param_configs[param_name] = normalized
    end
  end

  return {
    params = params,
    param_configs = param_configs,
    tracks = {},
    lerps = {},
  }
end

--- Extend an existing animator with additional parameters.
--- This is useful for class inheritance where child classes want to add their own animated parameters.
---@param self Animator: The animator instance to extend
---@param config table<string, AnimParamConfig>? Additional parameter configurations keyed by parameter name
function anim.extend(self, config)
  if not config then
    return
  end

  for param_name, value in pairs(config) do
    if self.params[param_name] ~= nil then
      error(
        ("anim: parameter '%s' already exists on animator"):format(param_name)
      )
    end

    local initial, normalized = prepare_param_config(param_name, value)
    self.params[param_name] = initial
    self.param_configs[param_name] = normalized
  end
end

-- API -------------------------------------------------------------------------

--- Play an animation clip.
---@param self Animator: The animator instance
---@param clip AnimClip: The clip to play
---@param opts {time?:number,speed?:number,weight?:number,loop?:boolean,enabled?:boolean}?: Playback options
---@return AnimTrack
function anim.play(self, clip, opts)
  local tr = {
    clip = clip,
    time = (opts and opts.time) or 0,
    speed = (opts and opts.speed) or 1,
    weight = (opts and opts.weight) or 1,
    loop = (opts and opts.loop) or false,
    enabled = (opts and opts.enabled) or true,
  }
  table.insert(self.tracks, tr)
  return tr
end

--- Stop a specific animation track.
---@param self Animator: The animator instance
---@param track AnimTrack: The track to stop
function anim.stop(self, track)
  for i = #self.tracks, 1, -1 do
    if self.tracks[i] == track then
      table.remove(self.tracks, i)
      return
    end
  end
end

--- Stop all animation tracks and tweens.
---@param self Animator: The animator instance
function anim.stop_all(self)
  self.tracks = {}
  self.lerps = {}
end

--- Tween a parameter from current value to target.
---@param self Animator: The animator instance
---@param param string: Parameter name to tween
---@param target AnimValue: Target value
---@param duration number?: Duration in seconds (default: 0.2)
---@param ease EaseFunc?: Easing function (default: linear)
---@param weight number?: Blend weight (default: 1.0)
function anim.tween(self, param, target, duration, ease, weight)
  local start = clone_value(self.params[param] or 0)
  local L = {
    param = param,
    start = start,
    target = clone_value(target),
    elapsed = 0,
    duration = duration or 0.2,
    ease = ease or Ease.linear,
    weight = weight or 1.0,
  }
  table.insert(self.lerps, L)
end

--- Set the weight of an animation track.
---@param self Animator: The animator instance
---@param track AnimTrack: The track to modify
---@param w number: New weight value
function anim.set_weight(self, track, w) track.weight = w end

--- Set a parameter value immediately.
---@param self Animator: The animator instance
---@param param string: Parameter name
---@param v AnimValue: New value
function anim.set_immediate(self, param, v) self.params[param] = clone_value(v) end

--- Get the current value of a parameter.
---@param self Animator: The animator instance
---@param param string: Parameter name
---@return AnimValue
function anim.get(self, param) return self.params[param] end

--- Advance and evaluate all animations.
---@param self Animator: The animator instance
---@param dt number: Delta time in seconds
function anim.update(self, dt)
  dt = dt / SpeedManager:get_current_speed()

  -- 1) advance tracks (remove finished non-looping)
  for i = #self.tracks, 1, -1 do
    print("updating track", i)
    local tr = self.tracks[i]
    if tr.enabled ~= false and tr.weight ~= 0 then
      tr.time = tr.time + dt * tr.speed
      if tr.time > tr.clip.length then
        if tr.loop then
          tr.time = tr.time % tr.clip.length
        else
          table.remove(self.tracks, i)
        end
      end
    end
  end

  -- 2) advance lerps
  for i = #self.lerps, 1, -1 do
    local L = self.lerps[i]
    L.elapsed = math.min(L.elapsed + dt, L.duration)
    if L.elapsed >= L.duration then
      -- Use lerp_value with t=1.0 to properly merge partial tables
      self.params[L.param] = lerp_value(L.start, L.target, 1.0)
      table.remove(self.lerps, i)
    end
  end

  -- 3) accumulate weighted contributions
  local acc ---@type table<string, AnimValue>
  local wsum ---@type table<string, number>
  acc, wsum = {}, {}

  local function add(param, value, w)
    if value == nil or w == 0 then
      return
    end
    acc[param] = accum_weighted(value, w, acc[param])
    wsum[param] = (wsum[param] or 0) + w
  end

  for _, tr in ipairs(self.tracks) do
    if tr.enabled ~= false and tr.weight ~= 0 then
      local vals = sample_clip(tr.clip, tr.time)
      for p, v in pairs(vals) do
        add(p, v, tr.weight)
      end
    end
  end

  for _, L in ipairs(self.lerps) do
    local t = (L.duration == 0) and 1 or (L.elapsed / L.duration)
    local eased
    if L.ease and type(L.ease) == "function" then
      eased = L.ease(t)
    elseif L.ease and type(L.ease) == "string" then
      print(L.ease, L)
      eased = Ease[L.ease](t)
    else
      eased = t
    end
    add(L.param, lerp_value(L.start, L.target, eased), L.weight or 1.0)
  end

  -- 4) normalize -> final
  for p, sum in pairs(acc) do
    self.params[p] = divide_weight(sum, wsum[p] or 1)
  end
end

-- Convenience -----------------------------------------------------------------

--- Quick single-param clip from (time,value[,ease]) tuples.
---@param name string: Clip name
---@param param string: Parameter name
---@param points {time:number, value:AnimValue, ease:EaseFunc?}[]: Keyframe points
---@return AnimClip
function anim.make_simple_clip(name, param, points)
  local ch = anim.channel(param, points)
  local length = (#points > 0) and points[#points].time or 0
  return anim.clip(name, length, { [param] = ch })
end

--- Tween a property on any object (not just animators).
---@param obj table: The object to animate
---@param property string: Property name to tween
---@param target AnimValue: Target value
---@param duration number?: Duration in seconds (default: 0.2)
---@param ease EaseFunc?: Easing function (default: linear)
function anim.tween_property(obj, property, target, duration, ease)
  -- Create a mini-animator just for this object property
  if not obj._property_tweens then
    obj._property_tweens = {}
  end

  local start = obj[property] or 0
  local tween = {
    object = obj,
    property = property,
    start = clone_value(start),
    target = clone_value(target),
    elapsed = 0,
    duration = duration or 0.2,
    ease = ease or Ease.linear,
  }

  obj._property_tweens[property] = tween
end

--- Update property tweens for an object.
---@param obj table: The object with property tweens
---@param dt number: Delta time
function anim.update_property_tweens(obj, dt)
  if not obj._property_tweens then
    return
  end

  for property, tween in pairs(obj._property_tweens) do
    tween.elapsed = math.min(tween.elapsed + dt, tween.duration)
    local t = (tween.duration == 0) and 1 or (tween.elapsed / tween.duration)
    local eased_t = tween.ease(t)

    obj[property] = lerp_value(tween.start, tween.target, eased_t)

    if tween.elapsed >= tween.duration then
      obj._property_tweens[property] = nil
    end
  end
end

--- Cancel a specific property tween on an object.
---@param obj table: The object with property tweens
---@param property string: Property name to cancel
function anim.cancel_property_tween(obj, property)
  if obj._property_tweens then
    obj._property_tweens[property] = nil
  end
end

--- Cancel all property tweens on an object.
---@param obj table: The object with property tweens
function anim.cancel_all_property_tweens(obj)
  if obj._property_tweens then
    obj._property_tweens = {}
  end
end

--- Trigger an impulse animation: immediately set to peak value, then animate back to rest.
--- Perfect for button presses, impacts, etc.
---@param self Animator: The animator instance
---@param param string: Parameter name to impulse
---@param peak_value AnimValue?: Peak value (default: 1.0)
---@param rest_value AnimValue?: Rest value to return to (default: 0.0)
---@param duration number?: Duration to animate back down (default: 0.3)
---@param ease EaseFunc?: Easing function for the return animation (default: easeInOutCubic)
function anim.impulse(self, param, peak_value, rest_value, duration, ease)
  peak_value = peak_value or 1.0
  rest_value = rest_value or 0.0
  duration = duration or 0.3
  ease = ease or Ease.easeInOutCubic

  -- Immediately set to peak value
  self.params[param] = clone_value(peak_value)

  -- Then tween back to rest value
  anim.tween(self, param, rest_value, duration, ease)
end

--- Drive multiple parameters toward their per-frame target values.
--- This is for immediate-mode inputs like hover, slider positions, etc.
--- Note: Parameters must already be tables to animate with table targets.
---@param self Animator: The animator instance
---@param targets table<string, number|boolean|table<string, number>>: Table of parameter names to target values (true=1, false=0)
---@param dt number: Delta time
---@return table<string, number|table<string, number>>: Table of parameter names to their new values
function anim.drive(self, targets, dt)
  dt = dt / SpeedManager:get_current_speed()

  local results = {}

  for param, target in pairs(targets) do
    -- Get parameter configuration
    local param_config = self.param_configs[param]
    if not param_config then
      error(("anim: parameter '%s' is missing configuration"):format(param))
    end

    local rate = param_config.rate
    local velocity = param_config.velocity
    local stabilize_threshold = param_config.stabilize_threshold or 0

    -- Handle different parameter types
    if type(target) == "boolean" or type(target) == "number" then
      -- Numeric/Boolean parameters
      local target_num = type(target) == "boolean" and (target and 1 or 0)
        or target
      local cur = (type(self.params[param]) == "number") and self.params[param]
        or 0

      local diff = target_num - cur
      if math.abs(diff) < stabilize_threshold then
        -- Close enough, snap to target to prevent oscillation
        cur = target_num
      else
        local step
        if velocity then
          -- Use constant velocity mode - move at fixed speed towards target
          step = math.min(velocity * dt, math.abs(diff))
          if diff < 0 then
            step = -step
          end
          cur = cur + step
        else
          -- -- Use proportional rate mode (original behavior)
          -- if not rate then
          --   error(("anim: parameter '%s' requires a 'rate' when driven without 'velocity'"):format(param))
          -- end

          if math.abs(cur - target_num) < 0.001 then
            cur = target_num
          elseif cur < target_num then
            -- cur = cur + (target_num - cur) * 0.03 * dt * 60 * rate
            cur = cur + (target_num - cur) * dt * rate
          elseif cur > target_num then
            -- cur = cur - (cur - target_num) * 0.03 * dt * 60 * rate
            cur = cur - (cur - target_num) * dt * rate
          else
            cur = target_num
          end
        end
      end

      self.params[param] = cur
      results[param] = cur
    elseif type(target) == "table" then
      -- Table parameters - animate each numeric value in the table
      local cur_table = self.params[param]
      if not cur_table or type(cur_table) ~= "table" then
        error(
          ("anim: parameter '%s' must be a table to drive with table values"):format(
            param
          )
        )
      end

      if not rate then
        error(
          ("anim: parameter '%s' requires a 'rate' to drive table values"):format(
            param
          )
        )
      end

      -- Create a copy to avoid modifying the original during iteration
      local result_table = {}
      for k, v in pairs(cur_table) do
        result_table[k] = v
      end

      -- Animate each key in the target table
      for key, target_val in pairs(target) do
        local cur_val = cur_table[key]

        if type(target_val) == "number" and type(cur_val) == "number" then
          -- Animate numeric values
          local diff = target_val - cur_val

          if math.abs(diff) < stabilize_threshold then
            result_table[key] = target_val
          else
            local step = rate * dt
            if cur_val < target_val then
              result_table[key] = math.min(cur_val + step, target_val)
            elseif cur_val > target_val then
              result_table[key] = math.max(cur_val - step, target_val)
            else
              result_table[key] = cur_val
            end
          end
        else
          -- For non-numeric values or type mismatches, set directly
          result_table[key] = target_val
        end
      end

      self.params[param] = result_table
      results[param] = result_table
    end
  end

  return results
end

return anim
