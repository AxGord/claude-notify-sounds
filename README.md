# claude-notify-sounds

[![npm version](https://img.shields.io/npm/v/claude-notify-sounds.svg)](https://www.npmjs.com/package/claude-notify-sounds)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that plays system sounds to notify you when Claude Code finishes work or needs permission. macOS only.

## Features

- Plays a sound when Claude stops working — no need to keep watching the terminal
- Plays a different sound when Claude needs permission — respond faster to approval prompts
- Lightweight — uses built-in macOS `afplay` and system sounds

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
| `Stop` | Basso | Claude finishes working |
| `Notification` (permission_prompt) | Ping | Claude needs permission to proceed |

## Configuration

To change sounds, edit the scripts in `scripts/` and replace the sound file path. Available macOS system sounds are in `/System/Library/Sounds/`.

## Requirements

- **macOS** — uses `afplay` and built-in system sounds

## License

[MIT](LICENSE)
