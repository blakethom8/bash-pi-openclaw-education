# Module 7: Where Agents Live

**The infrastructure layer — where your agent process runs, what it can touch, and how to make intentional decisions about compute environments**

---

## The Core Question

You ask your agent to analyze last quarter's sales data. It calls `bash("python analyze.py")`. Something runs. A file appears. Numbers come back.

**Where did that actually happen?**

Not at Anthropic. Not in the cloud by default. Not in some abstracted "agent runtime." It happened on whatever machine the agent process was running on — its CPU, its RAM, its filesystem. If you ran the agent on your laptop, it ran on your laptop. If you ran it on your Hetzner server, it ran there.

This seems obvious once you say it. But most developers never fully internalize it, and it causes real problems:

- Agents that work on your laptop and fail on your server (different user, different environment)
- Agents that can read files they shouldn't be able to (running as your user with your permissions)
- Agents that crash at 2am with no one to restart them (no daemon, no auto-restart)
- Agents that fill up a disk or consume all RAM (no resource limits)
- Agents that nobody knows how to debug remotely (no logging strategy)

---

## The Key Insight

> **The agent is just a process. Its capabilities and limitations are determined entirely by where that process runs and what that process has access to.**

Nothing more. Nothing less. There is no special agent runtime. There is no magic sandbox. When you call `bash("rm -rf ./old-reports/")`, that runs as you, on your machine, right now.

This is both the power and the danger of the bash-first agent design. Understanding it at the process level gives you full control.

---

## Module Goals

By the end of this module, you'll understand:

- What a process is and why it's the right mental model for an agent
- What a daemon is and why your reporting agents should probably be one
- The difference between bare metal, VMs, containers, and serverless — and when each makes sense
- How the filesystem determines what your agent can and can't do
- How to give an agent a sandbox so mistakes are recoverable
- Where to actually run your enterprise agents (Hetzner, Supabase, Azure)

**Who this is for:** You've built agents. You understand the Pi loop. You want to understand the infrastructure layer so you can deploy agents you trust in production.

**Time:** 2–3 hours

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│  Your Interface (Laptop / Telegram / Cron)                    │
└──────────────────────────────┬───────────────────────────────┘
                               │ (you trigger the agent)
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  Agent Process (wherever it runs)                             │
│                                                               │
│  • RAM: agent loop code + conversation context               │
│  • Filesystem: reads/writes files it has permission for      │
│  • Network: calls Anthropic API, Supabase, external services │
│  • User identity: runs as whoever started it                 │
└──────────────────────────────┬───────────────────────────────┘
                               │ (API calls over network)
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  Anthropic API                                                │
│  • The LLM model runs HERE, not on your machine              │
│  • Your context (messages array) gets sent here each turn    │
│  • The response comes back over the network                  │
└──────────────────────────────────────────────────────────────┘
```

The model lives at Anthropic. Everything else — the loop, the tools, the files, the bash commands — lives wherever your process lives.

---

## Lessons

### 7.1 The Agent is a Process
**File:** `7.1-the-agent-as-a-process.md`

What a process actually is. Why the agent's user identity, working directory, and environment variables determine everything it can do. Where RAM actually gets used. The three things that determine what any agent is capable of.

---

### 7.2 Daemons: Agents That Never Sleep
**File:** `7.2-daemons-and-services.md`

What a daemon is (background process, not attached to a terminal). How OpenClaw runs as a daemon. How to manage agent daemons with systemd. The three agent lifecycle patterns: one-shot, interactive session, and persistent daemon.

---

### 7.3 VMs, Containers, and Serverless
**File:** `7.3-vms-containers-serverless.md`

First-principles mental models for each compute environment. Bare metal vs. VM vs. container vs. serverless. When each makes sense for agent workloads. The three deployment patterns for your Hetzner/Supabase stack.

---

### 7.4 What Can Your Agent Touch? Filesystem Access
**File:** `7.4-filesystem-access.md`

Unix permissions in 60 seconds. The workspace pattern. Four things that go wrong with filesystem access (escape, disk exhaustion, credential exposure, concurrent writes). How remote filesystems (Supabase, S3) differ from local ones. The rule of least privilege.

---

### 7.5 Giving Agents a Sandbox
**File:** `7.5-sandboxing.md`

Why sandboxing is engineering discipline, not distrust. The five levers: filesystem isolation, user permissions, network isolation, resource limits, time limits. Practical sandbox setups for development, production, and untrusted agents. The recovery question.

---

### 7.6 Where to Actually Run Your Enterprise Agents
**File:** `7.6-enterprise-deployment.md`

A deployment decision matrix for reporting agents, data pipelines, and corporate automation. Your current stack (Hetzner + Supabase + Azure) mapped to real deployment decisions. The production-readiness checklist. The .env pattern. The intern mental model.

---

### 7.7 Reference Architecture for Enterprise Agents
**File:** `7.7-putting-it-together.md`

Everything synthesized into a recommended architecture diagram, a what-lives-where table, a decision guide for new agent deployments, and the three commands you'll use most.

---

## Key Questions This Module Answers

- Where does bash actually run when an agent calls the bash tool?
- Where is the RAM being used?
- Where do the files live?
- Does the agent live on my laptop? A server? The cloud?
- What is a daemon and is it relevant to agents?
- What's the difference between a VM, a container, and serverless?
- How do I give an agent a sandbox to play in?
- How do I give an agent access to my database and servers?
- What can go wrong with file access?
- Where should I run my enterprise agents?

---

**Start here:** [7.1 The Agent is a Process →](7.1-the-agent-as-a-process.md)
