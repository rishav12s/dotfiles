#!/bin/bash

# Set a custom font size for Kitty
CUSTOM_FONT_SIZE=13
DEFAULT_FONT_SIZE=11.5 # Replace with your terminal's default font size

# Check if the terminal is Kitty using the KITTY_PID environment variable
if [[ -n "$KITTY_PID" ]]; then
  # Set padding, margin and font size
  kitty @ set-spacing padding=0 margin=0
  kitty @ set-font-size "$CUSTOM_FONT_SIZE"

  # Open nvim with provided arguments
  nvim "$@"

  # Restore default padding, margin and font size
  kitty @ set-spacing padding=default margin=default
  kitty @ set-font-size "$DEFAULT_FONT_SIZE"
else
  # Do nothing if not Kitty
  nvim "$@"
fi
