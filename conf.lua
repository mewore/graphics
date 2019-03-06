function love.conf(t)
   t.identity = 'graphics'
   t.appendidentity = true
   t.author = 'Mewore'
   t.title = 'Graphics'
   -- Attach a console (boolean, Windows only)
   t.console = true
   -- Enable release mode (boolean)
   t.release = false
   -- The window width (number)
   t.window.width = 800
   -- The window height (number)
   t.window.height = 500
   -- Remove all border visuals from the window (boolean)
   t.window.borderless = false
   -- Let the window be user-resizable (boolean)
   t.window.resizable = true
   -- Enable fullscreen (boolean)
   t.window.fullscreen = false
   -- Enable vertical sync (boolean)
   t.window.vsync = true
   -- The number of FSAA-buffers (number)
   t.window.fsaa = 0

   --Modules to enable
   t.modules.keyboard = true
   t.modules.event = true
   t.modules.image = true
   t.modules.graphics = true
   t.modules.timer = true
   t.modules.mouse = true
end