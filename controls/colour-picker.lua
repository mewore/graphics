require "controls/colour-picker-dialog"

ColourPicker = {}
ColourPicker.__index = ColourPicker

--- A colour picker for the paint display
function ColourPicker:create()
   local this = {}
   setmetatable(this, self)
   return this
end

function ColourPicker:open(value, onPickHandler)
   ColourPickerDialog:open(value, function(newValue)
      onPickHandler({ r = newValue.r, g = newValue.g, b = newValue.b, a = value.a })
   end)
end
