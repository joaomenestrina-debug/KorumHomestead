# Instructions for coding agents (Codex and others)

Korum Homestead is a World of Warcraft addon: an idle village minigame. It runs inside the game client (Lua 5.1) and is
tested outside it with a small mock of the client in Python.

## Where things are

| Path | What |
|---|---|
| `*.lua`, `KorumHomestead.toc`, `Media/` (root) | the addon. The `.toc` lists the Lua files in load order |
| `tests/` | the tests (`test_homestead.py`) and the client mock (`client_mock.py`) |
| `ferramentas/simulador_ui.py` | opens the addon outside the game and saves pictures of its screens |
| `docs/plano-2.0.md`, `docs/cronograma-2.0.md` | the 2.0 plan and schedule (Portuguese) |
| `docs/tarefas/T-x.y.md` | **your task briefs**: one file per task, read it fully before starting |

## Commands

```
pip install lupa pillow pytest
python -m pytest tests -q                 # must pass before and after your change
python ferramentas/simulador_ui.py        # pictures of every screen in arquivo/telas/homestead/
```

GitHub Actions runs the tests on every pull request. A red run is not done.

## How to work

- Do exactly the task in the brief. Anything else you notice goes in the pull request description, not in the code.
- Branch: `codex/T-x.y-short-name`. Pull request title: `T-x.y: <what it does>`. One task per pull request.
- In the pull request description: what changed, how it was tested, and anything you were unsure of.
- **Commits and pull requests are signed as Korum** (the creator's name). Commit as the repository's configured user
  (`Korum`); never add `Co-Authored-By` lines or mention Codex, Claude or any AI in commit messages, pull request titles
  or descriptions, comments or changelogs.
- **Never create or push git tags.** A tag publishes a file on CurseForge; releases are tagged by Claude only.
- Do not change the version in `KorumHomestead.toc`, `CHANGELOG.md`, `.pkgmeta`, `LICENSE` or anything in `Media/`
  unless the brief says so.

## Rules of the project

- **Independent.** The addon uses no other addon and no library. Never add `## Dependencies`, `## OptionalDeps` or any
  reference to another addon. A test enforces this.
- **Lua 5.1, WoW client API.** No `goto`, no integer division `//`, no `utf8` library. The WoW Forever client has no global
  `GetItemInfo`/`GetItemIcon` guaranteed: use `C_Item.*` with a `pcall` and a fallback, as `Data.lua` does. `string.format`
  with `%d` takes 32-bit numbers only.
- **No new global names.** Everything hangs on the addon table (`local addonName, KH = ...`). The only globals are
  `KorumHomestead`, `KorumHomesteadDB`, the frames named `KorumHomestead*` and the `/kh` command.
- **Every text the player reads is in `Locales.lua`, in English and in Brazilian Portuguese** (same keys in both). Call
  `KH.T("key", ...)`. No text written straight into the UI code.
- **Everything has a control on the screen.** A slash command is only a shortcut, never the only way.
- **Items use the game's item icons** (by item id, through `KH.Data.Icon`). Pixel art is only for places, decorations and
  portraits, and it is made by the project owner, not by code.
- **Saved data must survive.** Never rename or delete a field of `KorumHomesteadDB`; add new ones to the defaults in
  `Core.lua`, and when the shape changes add a migration (from task T0.7 on: `Migrate.lua`).
- **Nothing punishes a player who was away.** No decay, no loss of what was earned.
- **Time:** use `KH.Now()` (never `time()` directly), so the tests can move the clock.
- **Randomness:** use `KH.Rand` (or the helper the brief names), so the tests can fix it.

## Code style

- Comments and identifiers in English, in plain words; say why, not what.
- Follow the shape of the code around you: local functions, small tables, `function X:Method()`.
- UI: build frames once, update them in `Refresh`; use the helpers of `Kit.lua` (buttons, text, colours) for every new
  element, so the look stays the same.

## Tests

- Every change of behaviour comes with a test in `tests/test_homestead.py` (or a new `tests/test_*.py`).
- The tests drive the addon through its own functions and screens (`self.open("garden")`, `self.press(...)`,
  `self.ev("lua expression")`); look at the existing ones first.
- Move the clock with `NOW = NOW + seconds` in the Lua state; fix chance with the seed or `KH.Rand`.
