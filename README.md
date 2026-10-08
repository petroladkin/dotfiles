### Install and Setup

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/petroladkin/dotfiles/master/tools/install.sh)"
```

### Setup without online install

1. Clone `dotfiles` repository
```shell
git clone https://github.com/petroladkin/dotfiles.git
```

2. Run `setup.sh` script
```shell
cd <cloned folder>
```
```shell
./setup.sh
```

### What you get

Supported: macOS, Ubuntu / Debian / Pop!_OS, Fedora, WSL (Ubuntu).

- **Shell**: zsh + Oh My Zsh + Powerlevel10k, MesloLGS NF fonts
- **Editor**: Neovim + [LazyVim](https://www.lazyvim.org/) (config in `nvim/`), `vim` is aliased to `nvim`
- **Terminal**: tmux, [Fresh](https://getfresh.dev/) terminal IDE, Midnight Commander
- **Viewers**: [Frogmouth](https://github.com/Textualize/frogmouth) (Markdown), [tdf](https://github.com/itsjunetime/tdf) (PDF, macOS only)
- **Python tooling**: [uv](https://docs.astral.sh/uv/)
- **Git**: tig, lazygit, [revdiff](https://github.com/umputun/revdiff) (TUI diff review with annotations)
- **Agents**: [Claude Code](https://code.claude.com/), [Herdr](https://herdr.dev/)
- **Runtime**: Node LTS via [fnm](https://github.com/Schniz/fnm) (for LazyVim language servers)
- **CLI**: ripgrep, fd, fzf

Machine-specific shell config goes to `~/.custom.zshrc` (sourced last, not in the repo).
Previous configs are moved to `~/.previous_configs/`.

On WSL, fonts must be installed on the Windows side: open `fonts/` from Explorer,
install the `.ttf` files and select `MesloLGS NF` in the Windows Terminal profile.
