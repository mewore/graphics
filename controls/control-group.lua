ControlGroup = {}
ControlGroup.__index = ControlGroup

--- A group of controls that are treated as one control.
function ControlGroup:create(controls)
   local this = {
      x = controls[1] and controls[1].x or 0,
      y = controls[1] and controls[1].y or 0,
      width = 0,
      height = 0,
      lastX = 0,
      lastY = 0,
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

--- LOVE update handler
function ControlGroup:update()
   local dx, dy = self.x - self.lastX, self.y - self.lastY
   if dx ~= 0 or dy ~= 0 then
      for _, control in ipairs(self.controls) do
         control.x, control.y = control.x + dx, control.y + dy
      end
   end
   self.lastX, self.lastY = self.x, self.y

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
