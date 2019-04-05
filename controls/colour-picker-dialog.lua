require "controls/button"
require "controls/colour-picker-hue-slider"
require "controls/colour-picker-square"
require "controls/control-group"
require "controls/dialog"

ColourPickerDialog = {}
ColourPickerDialog.__index = ColourPickerDialog

--- Opens a colour picker dialog
function ColourPickerDialog:open(initialValue, okHandler)
   local colourPickerSquare = ColourPickerSquare:create({ initialValue = initialValue })
   local colourPickerSlider = ColourPickerHueSlider:create(colourPickerSquare)
   colourPickerSlider.x = colourPickerSquare.x + colourPickerSquare.width + 10

   local dialog
   local okButton = Button:create("OK", "solid", function()
      if okHandler then
         okHandler(colourPickerSquare.value)
      end
      viewStack:popView(dialog)
   end)
   local cancelButton = Button:create("Cancel", nil, function() viewStack:popView(dialog) end)

   dialog = Dialog:create("Pick a colour", nil,
      { ControlGroup:create({ colourPickerSquare, colourPickerSlider }) }, { cancelButton, okButton })
end
