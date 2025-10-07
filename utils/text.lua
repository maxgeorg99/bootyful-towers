local function format_number(num)
  local wholeNum = math.floor(math.abs(num))
  local digitCount = string.len(tostring(wholeNum))

  if digitCount >= 4 then
    return string.format("%.0f", num) -- no decimals for 4+ digit numbers
  elseif num == math.floor(num) then
    return string.format("%.0f", num) -- no decimals for whole numbers
  else
    return string.format("%.2f", num) -- 1 decimals otherwise
  end
end

return {
  format_number = format_number,
}
