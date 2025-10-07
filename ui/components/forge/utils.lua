local function rarity_to_integer(rarity)
  if rarity == Rarity.COMMON then
    return 0
  elseif rarity == Rarity.UNCOMMON then
    return 1
  elseif rarity == Rarity.RARE then
    return 2
  elseif rarity == Rarity.EPIC then
    return 3
  elseif rarity == Rarity.LEGENDARY then
    return 4
  end
end

local function integer_to_rarity(integer)
  if integer == 0 then
    return Rarity.COMMON
  elseif integer == 1 then
    return Rarity.UNCOMMON
  elseif integer == 2 then
    return Rarity.RARE
  elseif integer == 3 then
    return Rarity.EPIC
  elseif integer == 4 then
    return Rarity.LEGENDARY
  end
end

local function upgrade_rarity(rarity)
  assert(rarity ~= Rarity.LEGENDARY, "cannot upgrade legendary")

  return integer_to_rarity(rarity_to_integer(rarity) + 1)
end

return {
  rarity_to_integer = rarity_to_integer,
  integer_to_rarity = integer_to_rarity,
  upgrade_rarity = upgrade_rarity,
}
