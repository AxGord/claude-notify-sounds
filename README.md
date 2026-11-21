# claude-notify-sounds

[![npm version](https://img.shields.io/npm/v/claude-notify-sounds.svg)](https://www.npmjs.com/package/claude-notify-sounds)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A [Claude Code](https://code.claude.com/docs/en/overview) plugin that plays a sound when Claude finishes, needs your permission or hits a usage limit — and stays **silent while background agents or workflows are still running**, so you only hear it when the work is really done. Supports macOS, Linux, and Windows.

## Features

- Silent while background agents or workflows still run — the sound means the work is truly finished
- Plays a sound when Claude stops working — no need to keep watching the terminal
- Plays a different sound when Claude needs permission — respond faster to approval prompts
- Plays an alert when a turn stops on a usage limit — know right away that work is paused
- Cross-platform: macOS, Linux (PulseAudio/PipeWire), Windows (Git Bash)
- Falls back to terminal bell when no sound system is available

## Quick Start

Install from this repo (always up to date):

```bash
claude plugin marketplace add AxGord/claude-notify-sounds
claude plugin install notify-sounds@claude-notify-sounds
```

It is also listed in the [community marketplace](https://github.com/anthropics/claude-plugins-community), which pins a fixed commit and may serve an older version:

```bash
claude plugin marketplace add anthropics/claude-plugins-community
claude plugin install notify-sounds@claude-community
```

## How It Works

The plugin uses Claude Code [hooks](https://code.claude.com/docs/en/hooks) to play sounds on specific events:

| Hook | Sound | When |
|------|-------|------|
| `Stop` | Warning tone | Claude finishes working |
| `Notification` (permission_prompt) | Ping / message tone | Claude needs permission to proceed |
| `StopFailure` (rate_limit) | Alert tone | Turn stopped on a usage limit (Claude Code v2.1.78+) |

The usage-limit alert plays once per limit stop:

- sub-agents rejected on the limit stay silent — only the main agent's stop counts
- a turn Claude was told to wrap up on the limit ([wrap-up allowance](https://support.claude.com/en/articles/17040437-claude-code-wrap-up-allowance)) ends with a normal stop, so it plays the alert instead of the stop sound
- a repeat alert in the same session within 60 seconds stays silent (a wrap-up stop followed by the limit rejecting the next wake-up is one stop)

The stop sound is skipped when work is not actually finished:

- sub-agent completions (`SubagentStop`)
- background agent tasks (subagent/workflow) still running when the turn ends — they re-invoke Claude on completion, so the real finish comes later, even when Claude replies in between (`background_tasks` in the Stop hook input, Claude Code v2.1.145+; on older versions the sound always plays)
- a background shell command launched moments before the turn ends ("started it and now waiting for it") — detected by the task output file being younger than a grace window, 30 seconds by default (`CLAUDE_NOTIFY_SOUNDS_GRACE` env var overrides; `0` disables)

Long-lived background shell processes (dev servers, watchers) do not silence the sound — a turn that ends long after starting one counts as finished. Any detection failure means the sound plays.

### Platform Details

| OS | Method | Sounds |
|----|--------|--------|
| **macOS** | `afplay` | Built-in system sounds (`Basso.aiff`, `Ping.aiff`, `Sosumi.aiff`) |
| **Linux** | `paplay` / `pw-play` | Freedesktop sound theme (`.oga`) |
| **Windows** | PowerShell `SoundPlayer` | Windows Media sounds (`.wav`) |
| **Fallback** | Terminal bell (`\a`) | Default terminal bell |

## Configuration

To change sounds, edit the `play_sound` calls in `scripts/notify-stop.sh`, `scripts/notify-permission.sh` and `play_limit_sound` in `scripts/play-sound.sh` (arguments: macOS, Linux, Windows sound file names):

- **macOS** — available sounds in `/System/Library/Sounds/`
- **Linux** — freedesktop sounds in `/usr/share/sounds/freedesktop/stereo/`
- **Windows** — system sounds in `C:\Windows\Media\`

## Requirements

- **macOS** — no extra dependencies (`afplay` is built-in)
- **Linux** — `paplay` (PulseAudio/PipeWire) or `pw-play` (PipeWire native); `sound-theme-freedesktop` package for sounds
- **Windows** — Git Bash or similar bash environment with access to `powershell.exe`

## See also

- [claude-keep-awake](https://github.com/AxGord/claude-keep-awake) — keeps your computer awake (even lid closed on Apple Silicon) while Claude Code works
- [Claude Workflow](https://axgord.github.io/claude-workflow/) — workflows for Claude Code agents: state machines, gates, a task queue, a shared thread pool and a live map

## License

[MIT](LICENSE)
