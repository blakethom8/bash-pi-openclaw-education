# Module 6: Gemini CLI Comparison

**What another production agent looks like — and what to steal from it**

---

## Module Goals

By the end of this module, you'll understand:
- What Gemini CLI actually is under the hood
- How it compares to Pi and OpenClaw architecturally
- What features are genuinely new vs. repackaged Pi
- Why GCP extensions are Gemini's "secret sauce" — and how your setup already has the same thing
- Concrete patterns to apply to your own agent design

**Time:** 1.5–2 hours

---

## What Gemini CLI Is (and Isn't)

Gemini CLI is Google's open-source AI agent CLI, built around the same core loop as Pi: model sees context, calls tools, results go back into context, repeat until no more tool calls.

**It is not:**
- A fundamentally different kind of agent
- Magic — it's the same while-loop you already understand
- Only useful if you're on GCP

**It is:**
- A heavily featured production version of the Pi concept
- Opinionated about safety (confirm by default, policy engine)
- Deeply integrated with Google's own cloud (GCP is home turf)
- A reference implementation for agent patterns worth knowing

---

## The High-Level Comparison

| | Pi | OpenClaw | Gemini CLI |
|---|---|---|---|
| Core loop | While + 4 tools | While + 4 tools + messaging | While + 17 tools + approval gates |
| Context files | AGENTS.md | AGENTS.md / SOUL.md / USER.md | GEMINI.md (3-level hierarchy) |
| Skills | Always loaded | Always loaded | On-demand via `activate_skill` |
| Extensions | TypeScript via Jiti | TypeScript | MCP servers (any language) |
| Safety | Trust by default | Trust by default | Confirm by default + policy engine |
| Rollback | None | None | Git shadow repo checkpointing |

The loop is identical. The differences are in **features layered on top**.

---

## What's Genuinely New vs. Repackaged Pi

**Repackaged Pi (same concept, different name):**
- GEMINI.md = AGENTS.md
- `run_shell_command` = `bash()`
- `save_memory` = `write()` to a memory file
- Skills via `activate_skill` = skills system (just loaded differently)

**Genuinely new additions:**
- **Plan Mode** — read-only enforcement before execution, editable plan file
- **Subagents** — isolated context loops that delegate and report back
- **Checkpointing** — automatic git snapshots before every file mutation
- **Policy engine** — five-tier allow/deny/ask rules per tool per argument
- **MCP protocol** — standardized tool servers in any language
- **Hooks** — 10+ lifecycle intercept points
- **Model steering** — inject hints mid-execution without stopping
- **Model routing** — Pro model for planning, Flash for execution

---

## The "Domain-Native Context" Insight

This is the conceptual core of the module.

Gemini CLI's GCP extensions (Cloud Run, Cloud SQL, gcloud) don't just add tools — they give the agent **pre-wired knowledge** of GCP's APIs, auth patterns, resource naming, and best practices. The agent already speaks GCP fluently before you write a single line of GEMINI.md.

**Your OpenClaw setup with Hetzner + Supabase is the same pattern.**

When you put your server hostnames, Supabase connection strings, table schemas, and naming conventions into AGENTS.md, you're building "Hetzner-native context" and "Supabase-native context." The architecture is identical. The difference is:

- Gemini's GCP knowledge = deep (trained on it + polished extension)
- Your infrastructure knowledge = explicit (written into AGENTS.md)

Both give the agent what it needs to act without guessing.

---

## Lessons to Take Back

1. **Domain-native context is your competitive advantage.** Invest heavily in AGENTS.md.
2. **On-demand skill loading saves tokens.** Brief descriptions in system prompt, full docs on demand.
3. **Plan before you act.** You don't need Plan Mode built in — a `--dry-run` flag achieves the same thing.
4. **Checkpointing = `git commit` before dangerous operations.** Manual version, same safety net.
5. **MCP is worth watching.** Build tool servers that work across frameworks.

---

## Lessons in This Module

### 6.1 The Same Loop, More Features
**File:** `6.1-core-architecture.md`

Structural comparison of the loops, tool counts, context file systems, skill loading strategies, and a full feature comparison table.

---

### 6.2 The Secret Sauce: Domain-Native Context
**File:** `6.2-domain-native-context.md`

Why GCP extensions are Gemini's real advantage, how your AGENTS.md replicates the same pattern, and how to maximize your own domain-native context.

---

### 6.3 What Gemini CLI Adds for Production Use
**File:** `6.3-production-features.md`

Deep dive into Plan Mode, subagents, checkpointing, policy engine, MCP, hooks, and model steering — what each does and why it matters.

---

### 6.4 What to Take Back to Your Own Agent Design
**File:** `6.4-what-to-steal.md`

Actionable patterns: DIY equivalents for every Gemini CLI production feature using Pi, OpenClaw, and bash.

---

**Next:** [6.1 The Same Loop, More Features →](6.1-core-architecture.md)
