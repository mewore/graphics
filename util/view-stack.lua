ViewStack = {}
ViewStack.__index = ViewStack

--- A view stack that handles the order in which to order the views and uptates only the top view
-- @param firstView {View | nil} - The initial view
function ViewStack:create(firstView)
   local this = {
      stack = {},
      lastOpaqueViewIndex = 0,
   }
   setmetatable(this, self)
   if firstView ~= nil then
      this:pushView(firstView)
   end

   firstView.onClose = function() love.event.quit() end

   return this
end

--- Checks whether a view is opaque
-- @param view {View}
local function viewIsOpaque(view)
   return view.isOpaque == nil or view.isOpaque == true
end

--- Pushes a view to the top of the stack.
-- @param viewToPush {View}
function ViewStack:pushView(viewToPush)
   self.stack[#self.stack + 1] = viewToPush
   -- Views are assumed to be opaque but some elements, for example dialogs, may allow rendering of the ones under them
   if viewIsOpaque(viewToPush) then
      self.lastOpaqueViewIndex = #self.stack
   end
   print("Pushed view. Stack size: ", #self.stack)
end

--- Pops a view from the stack. It doesn't need to be the top one.
-- @param viewToPop {View | nil}
function ViewStack:popView(viewToPop)
   if #self.stack == 0 then
      error("Cannot pop any views - there aren't any")
   end

   local viewIndex = #self.stack
   if viewToPop ~= nil then
      while viewIndex >= 1 and self.stack[viewIndex] ~= viewToPop do
         viewToPop = viewToPop - 1
      end
      if viewToPop == nil then
         error("Could not find the specified view in the view stack")
      end
   end

   for i = viewIndex + 1, #self.stack do
      self.stack[i - 1] = self.stack[i]
   end
   self.stack[#self.stack] = nil

   if self.lastOpaqueViewIndex >= viewIndex then
      self.lastOpaqueViewIndex = self.lastOpaqueViewIndex - 1
      while self.lastOpaqueViewIndex >= 2 and not viewIsOpaque(self.stack[self.lastOpaqueViewIndex]) do
         self.lastOpaqueViewIndex = self.lastOpaqueViewIndex - 1
      end
   end
   print("Popped view. Stack size: ", #self.stack)
   print("lastOpaqueViewIndex: ", self.lastOpaqueViewIndex)
   print("stack[lastOpaqueViewIndex]: ", self.stack[self.lastOpaqueViewIndex] ~= nil)
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function ViewStack:update(dt)
   self.stack[#self.stack]:update(dt)
end

--- LOVE draw handler
function ViewStack:draw()
   for i = self.lastOpaqueViewIndex, #self.stack do
      self.stack[i]:draw()
   end
end
