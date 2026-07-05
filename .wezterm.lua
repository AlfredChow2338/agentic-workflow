-- Place in $HOME/.wezterm.lua or $HOME/.config/wezterm/wezterm.lua
-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 10.0
config.color_scheme = 'rose-pine-moon'

-- customised settings
config.max_fps = 120
config.enable_tab_bar = true
config.window_decorations = "RESIZE"
config.font = wezterm.font("Hack Nerd Font", { weight = "Regular" })

config.inactive_pane_hsb = {
  saturation = 0.0,
  brightness = 0.5,
}

config.window_background_opacity = 0.9

-- Finally, return the configuration to wezterm:
return config