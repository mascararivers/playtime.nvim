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

## Contributions

Contributions are welcome! Feel free to open a [pull request](https://github.com/walker84837/playtime.nvim/pulls) or [issue](https://github.com/walker84837/playtime.nvim/issues).

### Roadmap

- [ ] Generate report from usage data and show it in a browser or otherwise documents with graphs, etc.
- [ ] Allow for configuration options

## Commands

- `:Playtime` - Open the playtime window.
- `:Playtime report` - Open the playtime report window.

## License

This plugin is licensed under the [MIT License](LICENSE).
