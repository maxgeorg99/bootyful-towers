---@class mixin.ReactiveList : Element
---@field get_reactive_list fun(self: self): table
---@field create_element_for_item fun(self: self, item: any, state: mixin.ReactiveList.ItemState): Element
---@field reactive_container Element
---@field _append_element_for_item fun(self: self, element: Element, item: any)
---@field _update_reactive_list fun(self: self)
---@field _reactive mixin.ReactiveList.State

---@class mixin.ReactiveList.ItemState
---@field index number
---@field total_count number

---@class mixin.ReactiveList.State
---@field item_to_element table<string, Element>

return {
  --- @param self mixin.ReactiveList
  create = function(self)
    function self:_update_reactive_list()
      local items = self:get_reactive_list()
      if #items == 0 then
        self.reactive_container:remove_all_children()
        return
      end

      local dirty = false
      local current_elements = {}
      for i, item in ipairs(items) do
        if not self._reactive.item_to_element[item.id] then
          dirty = true
          self._reactive.item_to_element[item.id] = assert(
            self:create_element_for_item(item, {
              index = i,
              total_count = #items,
            }),
            "Must return a valid element"
          )
          self._reactive.item_to_element[item.id].z = i
        end

        current_elements[item.id] = self._reactive.item_to_element[item.id]

        if self.reactive_container.children[i] ~= current_elements[item.id] then
          dirty = true
        end
      end

      -- if #current_elements ~= #items then
      --   if self:is_debug_mode() then
      --     print("Current elements", #current_elements, "Items", #items)
      --   end
      --   dirty = true
      -- end

      -- -- Clear elements that are no longer in the list, they are now dead.
      -- for id, _ in pairs(self._reactive.item_to_element) do
      --   if not current_elements[id] then
      --     dirty = true
      --     -- self._reactive.item_to_element[id] = nil
      --   end
      -- end

      if dirty then
        self.reactive_container:remove_all_children()
        for i = 1, #items do
          self.reactive_container:append_child(
            self._reactive.item_to_element[items[i].id]
          )
        end
        -- for _, child in ipairs(items) do
        --   self.reactive_container:append_child(
        --     self._reactive.item_to_element[child.id]
        --   )
        -- end
      end
    end
  end,

  --- @param self mixin.ReactiveList
  init = function(self)
    if not self.reactive_container then
      self.reactive_container = self
    end

    validate(self, {
      get_reactive_list = "function",
      create_element_for_item = "function",
    })

    self._reactive = { item_to_element = {} }
    table.insert(self._post_update_hooks, self._update_reactive_list)
  end,
}
