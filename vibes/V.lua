local V = {}
V.__index = V

function V.new(v) return setmetatable(v, V) end

function V:__mul(other)
  if type(self) == "number" then
    self, other = other, self
  end

  if type(other) == "number" then
    return V.new {
      self[1] * other,
      self[2] * other,
      self[3] * other,
      self[4] * other,
    }
  else
    return V.new {
      self[1] * other[1],
      self[2] * other[2],
      self[3] * other[3],
      self[4] * other[4],
    }
  end
end

function V:__add(other)
  if type(self) == "number" then
    self, other = other, self
  end

  if type(other) == "number" then
    return V.new {
      self[1] + other,
      self[2] + other,
      self[3] + other,
      self[4] + other,
    }
  else
    return V.new {
      self[1] + other[1],
      self[2] + other[2],
      self[3] + other[3],
      self[4] + other[4],
    }
  end
end

return V
