ControlGroup = {}
ControlGroup.__index = ControlGroup

--- A group of controls that are treated as one control.
function ControlGroup:create(controls)
   local this = {
      x = controls[1] and controls[1].x or 0,
      y = controls[1] and controls[1].y or 0,
      width = 0,
      height = 0,
      controls = controls,
   }
   setmetatable(this, self)

   for _, control in ipairs(controls) do
      this.x, this.y = math.min(this.x, control.x), math.min(this.y, control.y)
      this.width = math.max(this.width, control.x + control.width)
      this.height = math.max(this.height, control.y + control.height)
   end

   this.width, this.height = this.width - this.x, this.height - this.y

   return this
end

--- Change the position of this element
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function ControlGroup:setPosition(x, y)
   local dx, dy = x - self.x, y - self.y
   for _, control in ipairs(self.controls) do
      control.x, control.y = control.x + dx, control.y + dy
   end
   self.x, self.y = x, y
end

--- Get both the X and the Y position of this element
-- @returns {int}, {int}
function ControlGroup:getPosition() return self.x, self.y end

--- Change the size of this element
function ControlGroup:setSize(_, _) error("Cannot set the size of a control group") end

--- Get the size of this element
-- @returns {int}, {int}
function ControlGroup:getSize() return self.width, self.height end

--- LOVE update handler
function ControlGroup:update()
   for _, control in ipairs(self.controls) do
      control:update()
   end
end

--- LOVE draw handler
function ControlGroup:draw()
   for i = #self.controls, 1, -1 do
      self.controls[i]:draw()
   end
end
