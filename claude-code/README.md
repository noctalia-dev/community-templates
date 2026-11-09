# Claude Code

![Claude Code using the Noctalia theme](screenshot.png)

Tested with Claude Code 2.1.238.

To use a custom config directory, set `CLAUDE_CONFIG_DIR` in Noctalia's
environment as well as Claude Code's. A variable exported only in a terminal
shell will not reach an already-running Noctalia process.

Select `Noctalia` from Claude Code's `/theme` picker after enabling the
template. Claude Code reloads changes to the generated theme automatically. If
its themes directory did not exist when Claude Code started, restart it once
after the first render.
