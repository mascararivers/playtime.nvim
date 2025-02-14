# playtime.nvim

> Measure how much you've used Neovim over time.

> [!WARNING]
> This plugin is not fully finished. Changes can and will be breaking.

## Table of Contents

- [Installation](#installation)
- [Commands](#commands)

## Installation

lazy.nvim:
```lua
return {
    {
        "walker84837/playtime.nvim",
        config = function()
            require("playtime").setup()
        end
    }
}
```

## Commands

- `:Playtime` - Open the playtime window.

## License

This plugin is licensed under the [MIT License](LICENSE).
