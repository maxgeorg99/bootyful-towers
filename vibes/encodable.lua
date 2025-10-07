---@class Encodable
---@field encode fun(self: Encodable): table<string, string>
---@field decode fun(self: Encodable, data: table<string, string>)

---@param instance table The instance of the class
---@param type string Type of the instance
---@param parent_path string The parent's require path
---@param self_encoding_func (fun(data: table<string, string>): table<string, string>) | nil The optional function to encode the instance
---@param self_decoding_func (fun(self_card: type, data: table<string, string>)) | nil The optional function to decode the instance
return function(
  instance,
  type,
  parent_path,
  self_encoding_func,
  self_decoding_func
)
  local parent = require(parent_path)
  instance.encode = function(self_card)
    local data = {}
    if self_encoding_func then
      ---@diagnostic disable-next-line: cast-local-type
      data = self_encoding_func(self_card)
    end
    local parent_data = parent.encode(self_card)
    data["_type"] = type
    for k, v in pairs(parent_data) do
      data[k] = v
    end
    return data
  end

  instance.decode = function(self_card, data)
    if self_decoding_func then
      self_decoding_func(self_card, data)
    end
    parent.decode(self_card, data)
  end
end
