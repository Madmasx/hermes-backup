---
name: hermes-local-llm
description: "Use when wiring a local LLM (LM Studio/Ollama) into Hermes."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, lmstudio, ollama, local-llm, llm-serving, troubleshooting, context-window]
---

# Hermes ↔ Local LLM Integration

Diagnosing why a locally-hosted model (LM Studio, Ollama, llama.cpp, vLLM) won't
work as Hermes' default model, and setting it up correctly.

## When to Use

Use this skill when the user says "I set the model to X_LOCAL but it doesn't work", "local model won't
connect", or has a `model:` block pointing at a LAN/localhost OpenAI-compatible
endpoint (e.g. `http://192.168.0.x:1234`).

## The three failure layers — check in this order

Local-model failures are almost always ONE of these three, each with a distinct,
easy-to-misread error. Diagnose top to bottom.

### 1. Auth / token
```bash
curl -s -m 8 http://HOST:PORT/v1/models
curl -s -m 8 http://HOST:PORT/api/v1/models
```
- `"LM Studio API token is required"` / `"Malformed LM Studio API token: abc123…"`
  → the server requires a Bearer token. Fix: disable auth in the server UI (LAN
  of trust) OR set the correct key. For LM Studio the key env var is
  `LM_API_KEY` (in `~/.hermes/.env`). A "Malformed … token" response means the
  stored value is wrong/expired — copy the real token from the server UI.

### 2. Wrong model id
Hermes sends `model.default` verbatim as the OpenAI `model` field. It must be the
EXACT id the server reports, never an invented alias like `GEMMA_LOCAL`.
```bash
curl -s http://HOST:PORT/api/v1/models   # LM Studio native — includes max_context_length
curl -s http://HOST:PORT/v1/models       # OpenAI-compatible — id list only, NO context
```
Use the `key`/`id` value (e.g. `google/gemma-4-e4b`), not the `display_name`.

### 3. Context window (the most common blocker)
Hermes requires ≥64,000 tokens of context. Local endpoints usually report NO
context over the OpenAI-compatible `/v1/models`, so Hermes falls back to 8,192
and refuses startup:
```
Model X has a context window of 8,192 tokens, which is below the minimum 64,000
```

Two-part fix — BOTH required:
1. **Hermes config override** (tells Hermes the model's real window):
   ```bash
   hermes config set model.context_length 131072
   hermes config set auxiliary.compression.context_length 131072
   ```
   The second key matters because Hermes reuses the same model for context
   compression and runs the SAME 64K check on the auxiliary model.
2. **Raise the real engine context** — the config override only silences Hermes;
   the actual engine still runs at its loaded `n_ctx`. If the server was loaded
   with a small window you'll see the engine reject requests:
   ```
   "request (17398 tokens) exceeds the available context size (8192 tokens)" … "n_ctx":8192
   ```
   Fix in the server UI: eject/unload the model, raise the "Context Length" /
   "n_ctx" slider (≥65536, ideally the model max), reload, restart the server.
   The `max_context_length` field in `/api/v1/models` is the model's *theoretical
   maximum*, NOT what it is currently loaded at — the load-time slider is what
   actually matters.

## End-to-end verification
```bash
hermes chat -q "Responde únicamente con la palabra: CONECTADO"
```
Passes only when auth + model id + real context are all correct. Use it as the
final gate after each fix; it also surfaces the auxiliary-compression error that
a plain curl test will not.

## Pitfalls
- `hermes config set auxiliary.compression.context_length 131072` prints
  "not a recognized config key" — the agent DOES read it
  (`agent/agent_init.py` reads `auxiliary.compression.context_length`). Save it
  anyway; the warning is just the CLI schema being narrower than the runtime.
- `lmstudio` is a valid built-in Hermes provider (`auth_type: api_key`, env vars
  `LM_API_KEY` / `LM_BASE_URL`, default base_url `http://127.0.0.1:1234/v1`).
  No need to define a custom provider for LM Studio.
- LM Studio serves BOTH `/v1/*` (OpenAI-compatible) and `/api/v1/*` (native).
  Only the native one reports `max_context_length` — always read models from
  `/api/v1/models` for diagnostics.
- Never hand-edit `config.yaml`; use `hermes config set` (stray indentation can
  corrupt it and break the live gateway).
- Correct store: secrets (`LM_API_KEY`) go in `~/.hermes/.env`; settings
  (`model.base_url`, `model.context_length`) go in `config.yaml`.

See `references/lmstudio-hermes.md` for LM Studio specifics, provider-overlay
details, and the exact error transcripts.
