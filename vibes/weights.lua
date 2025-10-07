---@class vibes.Weight<T> : { kind: T, weight: number }[]

return {
  ---@generic T
  ---@param roll number
  ---@param weights vibes.Weight<T>
  ---@return T
  pick_based_on_roll = function(roll, weights)
    assert(roll >= 0 and roll <= 1, "roll must be between 0 and 1")

    local total_weight = 0
    for _, weight in ipairs(weights) do
      total_weight = total_weight + weight.weight
    end

    local current_sum = 0
    for _, weight in ipairs(weights) do
      current_sum = current_sum + weight.weight / total_weight
      if roll <= current_sum then
        return weight.kind
      end
    end

    return weights[#weights].kind
  end,
}
