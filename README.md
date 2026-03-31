# claude-notify-sounds

[![npm version](https://img.shields.io/npm/v/claude-notify-sounds.svg)](https://www.npmjs.com/package/claude-notify-sounds)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that plays system sounds to notify you when Claude Code finishes work or needs permission. Supports macOS, Linux, and Windows.

## Features

- Plays a sound when Claude stops working — no need to keep watching the terminal
- Plays a different sound when Claude needs permission — respond faster to approval prompts
- Cross-platform: macOS, Linux (PulseAudio/PipeWire), Windows (Git Bash)
- Falls back to terminal bell when no sound system is available

## Quick Start

Install from the Claude Code plugin marketplace:

```
claude plugin add claude-notify-sounds
```

Or install manually:

```bash
git clone https://github.com/AxGord/claude-notify-sounds.git
claude plugin add ./claude-notify-sounds
```

## How It Works

The plugin uses Claude Code [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to play sounds on specific events:

| Hook | Sound | When |
|------|-------|------|
| `Stop` | Warning tone | Claude finishes working |
| `Notification` (permission_prompt) | Ping / message tone | Claude needs permission to proceed |

### Platform Details

| OS | Method | Sounds |
|----|--------|--------|
| **macOS** | `afplay` | Built-in system sounds (`Basso.aiff`, `Ping.aiff`) |
| **Linux** | `paplay` / `pw-play` | Freedesktop sound theme (`.oga`) |
| **Windows** | PowerShell `SoundPlayer` | Windows Media sounds (`.wav`) |
| **Fallback** | Terminal bell (`\a`) | Default terminal bell |

## Configuration

To change sounds, edit the scripts in `scripts/` and replace the sound file path:

- **macOS** — available sounds in `/System/Library/Sounds/`
- **Linux** — freedesktop sounds in `/usr/share/sounds/freedesktop/stereo/`
- **Windows** — system sounds in `C:\Windows\Media\`

## Requirements

- **macOS** — no extra dependencies (`afplay` is built-in)
- **Linux** — `paplay` (PulseAudio/PipeWire) or `pw-play` (PipeWire native); `sound-theme-freedesktop` package for sounds
- **Windows** — Git Bash or similar bash environment with access to `powershell.exe`

## License

[MIT](LICENSE)
