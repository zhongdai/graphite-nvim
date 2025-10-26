# graphite-nvim

Neovim plugin to run Graphite CLI commands from inside the editor. Create and submit stacks with a floating output window.

- Commands:
  - `:GraphiteCreateStack` — prompts for a message and runs `gt create -am "<msg>"`
  - `:GraphiteSubmitStack` — runs `gt submit --stack`
  - `:GraphiteLog` — runs `gt log`

## Requirements

- Graphite CLI installed: `brew install withgraphite/tap/graphite`
- Neovim 0.8+

Graphite CLI reference: [graphite.dev/features/cli](https://graphite.dev/features/cli)

## Installation

Using `lazy.nvim`:

```lua
{
  "zdai/graphite-nvim",
  config = function()
    require("graphite").setup({
      -- optional overrides
      -- gt_cmd = "gt",
      -- float = { width = 0.9, height = 0.8, border = "rounded" },
    })
  end,
}
```

Using `packer.nvim`:

```lua
use({
  "zdai/graphite-nvim",
  config = function()
    require("graphite").setup({})
  end,
})
```

## Usage

- `:GraphiteCreateStack` — enter your commit message when prompted.
- `:GraphiteSubmitStack` — submit PRs for the stack.
- `:GraphiteLog` — view the current stack tree.

Output is shown in a floating window. Press `q` or `<Esc>` to close.

## License

MIT
