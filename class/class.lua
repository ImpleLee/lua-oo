local insert, move = table.insert, table.move

local class = {
  __newindex = function(t, k, v)
    if type(v) ~= 'function' then
      rawset(t, k, v)
      return
    end
    rawset(t, k, function(self, ...)
      if self.parents then return v(self, ...) end
      local cls = {parents = {}}
      for k, v in pairs(self) do
        if type(v) == 'function' then cls[k] = v end
      end
      setmetatable(cls, cls)
      return cls[k](cls, ...)
    end)
  end
}
setmetatable(class, class)

function class:is(...)
  local parents = {...}
  move(parents, 1, #parents, #self.parents + 1, self.parents)
  return self
end
function class:__call(prototype)
  local parents = self.parents
  local parent_protos = {}
  for _, parent in pairs(parents) do insert(parent_protos, parent.prototype) end
  local mro = {prototype}
  local function merge(lists)
    local nonempty = {}
    for _, list in ipairs(lists) do
      if #list > 0 then insert(nonempty, list) end
    end
    local lasts, pos = {}, {}
    for _, list in pairs(nonempty) do
      for i, element in ipairs(list) do
        if not lasts[element] then lasts[element] = {} end
        lasts[element][list] = i
      end
      pos[list] = 1
    end
    local counter, length = #nonempty, #nonempty
    while counter > 0 do
      local element
      for i = 1, length do
        local list = nonempty[i]
        element = list[pos[list]]
        if element then
          local last = lasts[element]
          for _, other in pairs(nonempty) do
            if last[other] and last[other] > pos[other] then
              element = nil
              break
            end
          end
          if element then break end
        end
      end
      assert(element, 'Cannot resolve MRO')
      insert(mro, element)
      for _, list in pairs(nonempty) do
        if list[pos[list]] == element then
          pos[list] = pos[list] + 1
          if pos[list] > #list then counter = counter - 1 end
        end
      end
    end
  end
  merge((function()
    local lists = {parent_protos}
    for _, parent in pairs(parents) do insert(lists, parent.mro) end
    return lists
  end)())
  local specials = {
    __prototype = prototype,
    __parents = parent_protos,
    __mro = mro,
    __resolve = function(key)
      return function(state, control)
        if not state then return end
        for i = control + 1, #state do
          local value = state[i][key]
          if value then return i, value end
        end
      end, mro, 0
    end,
    __is = function(cls)
      for _, parent in pairs(mro) do if parent == cls then return true end end
      return false
    end
  }
  return setmetatable({
    prototype = prototype,
    parents = parent_protos,
    mro = mro
  }, {
    __call = function(_, ...)
      local obj = setmetatable({}, {
        __index = function(_, key)
          if specials[key] then return specials[key] end
          for _, value in specials.__resolve(key) do return value end
        end
      })
      if obj.__init then obj:__init(...) end
      return obj
    end
  })
end

return class
