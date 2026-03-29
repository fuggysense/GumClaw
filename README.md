# GumClaw

Multi-bot Telegram launcher for Claude Code. Register multiple bots, pick one per session, auto-pair trusted users.

Built on [ClaudeClaw](https://github.com/robonuggets/claudeclaw) by Jay from RoboLabs. Powered by [gum](https://github.com/charmbracelet/gum).

## What you get

**GumClaw Launcher** — one command to manage all your Telegram bots
- Interactive bot picker with styled terminal UI
- Multi-bot registry with lock tracking (no two sessions fight over the same bot)
- Auto-pair eliminates manual pairing codes
- Each bot pins to a project directory — auto-cd on launch

**Workspace Blueprint** — multi-agent setup with session persistence
- Primary agent + up to 3 sub-agents (alpha/beta/gamma)
- SOUL.md (personality), USER.md (context), CLAUDE.md (instructions)
- Cron registry, shared memory

## Setup

### Option A: Guided (recommended)

```bash
git clone <this-repo>
cd claudeclaw-seamless
claude
```

Then type `/setup` and follow the prompts.

### Option B: Script

```bash
git clone <this-repo>
cd claudeclaw-seamless
bash install.sh
```

## Usage

```bash
gumclaw                    # Pick a bot → launch Claude Code
gumclaw <bot-id>           # Direct launch with specific bot
gumclaw --add              # Register a new bot from @BotFather
gumclaw --list             # See all bots + which are in use
gumclaw --release <id>     # Force-release a stuck lock
```

### Multi-bot workflow

```bash
# Terminal 1 — Marketing
$ gumclaw
  > marketing_bot    @marketing_bot    Marketing agent    ~/Marketing
    video_bot        @video_bot        Video production   ~/Videos

# Terminal 2 — Video
$ gumclaw
    marketing_bot    @marketing_bot    Marketing agent    [IN USE: PID 44047]
  > video_bot        @video_bot        Video production   ~/Videos
```

Each session gets its own bot. No conflicts.

## How it works

1. **Bot registry** (`bot-registry.json`) stores all your bots with tokens, purposes, and project dirs
2. **GumClaw launcher** lets you pick a bot, validates the token, writes a lock file, then `exec`s into Claude Code with that bot's token
3. **Lock files** track which bot is used by which session (PID-based, auto-cleaned when session dies)
4. **Auto-pair** syncs trusted users into all plugin state dirs on every session start

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Pro or Max subscription)
- [Bun](https://bun.sh) runtime (installer handles this)
- [jq](https://jqlang.github.io/jq/) (`brew install jq`)
- [gum](https://github.com/charmbracelet/gum) (`brew install gum`) — optional, falls back to plain prompts
- Telegram bot token(s) from @BotFather
- Your Telegram user ID from @userinfobot

## Files

```
claudeclaw-seamless/
├── CLAUDE.md                        # Repo instructions
├── install.sh                       # Bash installer
├── .claude/skills/
│   └── setup.md                     # Guided /setup skill
├── CLAUDE.md                        # Workspace instructions (progressive setup)
├── SOUL.md                          # Agent personality + tone
├── USER.md                          # User context (fills in over time)
├── cron-registry.json               # Scheduled tasks
├── agents/{alpha,beta,gamma}/       # Sub-agent workspaces
├── shared/memory/                   # Cross-agent memory
├── memory/                          # Primary agent memory
└── telegram/                        # GumClaw system
    ├── gumclaw                      # Launcher script
    ├── auto-pair.sh                 # Access syncing + stale lock cleanup
    ├── discover-groups.sh           # Find group chat IDs
    ├── trusted-users.template.json  # User/group config template
    └── SETUP-GUIDE.md              # Troubleshooting
```

**Installed to:**
```
~/.claude/channels/telegram/
├── gumclaw                  # Launcher (symlinked to PATH)
├── bot-registry.json        # All bots + tokens (chmod 600)
├── locks/                   # Per-bot PID locks
├── trusted-users.json       # Auto-approve user IDs
├── auto-pair.sh             # SessionStart hook
└── .env                     # Default bot token (legacy fallback)
```

## Known limitations

- **One bot per session** — Telegram API allows only one consumer per bot token
- **Can't switch bots mid-session** — the plugin reads the token once at startup. Use `gumclaw` to relaunch.
- **First message delay** — first Telegram message after idle may not arrive. Send a second.
- **No offline queue** — messages sent while Claude Code is closed are lost.

## Credits

- [ClaudeClaw](https://github.com/robonuggets/claudeclaw) by Jay from RoboLabs — workspace blueprint
- [gum](https://github.com/charmbracelet/gum) by Charmbracelet — terminal UI
- GumClaw by Jerel — multi-bot registry + auto-pair

## License

MIT
