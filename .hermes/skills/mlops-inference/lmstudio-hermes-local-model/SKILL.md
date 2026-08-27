---
name: lmstudio-hermes-local-model
description: "Use when configuring LM Studio local models in Hermes."
version: 1.0.0
author: Hermes Agent + @madmasx
license: MIT
metadata:
  hermes:
    tags: [hermes, lmstudio, local-llm, provider, gemma, configuration]
---

# LM Studio local model in Hermes

Wire a local LM Studio server into Hermes as the model provider and fix the
failure modes that make it silently not connect.

## When to use

- Setting up LM Studio (local LLM server, default port 1234) as Hermes' model provider.
- Hermes won't connect to LM Studio: token/auth errors, "model not found",
  "below the minimum 64,000" context rejection, or engine "exceeds context size" errors.

## Quick facts

- LM Studio serves OpenAI-compatible API under `/v1` and a native API under `/api/v1`.
- Hermes provider id is `lmstudio` (transport `openai_chat`, auth `api_key`).
  - API key env var: `LM_API_KEY`
  - base url env var: `LM_BASE_URL`
- Hermes requires the main model to report/accept >= 64K context, otherwise it
  refuses to initialize.

## Steps

1. **Confirm the server answers**
   ```bash
   curl -s -m 8 http://<host>:1234/v1/models
   ```
   If it returns `"LM Studio API token is required"`, auth is ON. Either disable
   it (LM Studio UI → Developer → Server → Authentication / "Require API key" OFF),
   or provide the real token (see Pitfalls).

2. **Get the REAL model id (never an alias)**
   ```bash
   curl -s http://<host>:1234/v1/models            # data[].id (OpenAI-compatible)
   curl -s http://<host>:1234/api/v1/models        # models[].key (native, has context + loaded_instances)
   ```
   Ids look like `google/gemma-4-e4b`. A hand-written name like `GEMMA_LOCAL`
   does not exist and will fail.

3. **Set the config via `hermes config set`** (never hand-edit config.yaml):
   ```bash
   hermes config set model.default google/gemma-4-e4b
   hermes config set model.provider lmstudio
   hermes config set model.base_url http://<host>:1234/v1
   ```

4. **Override context length (critical)** — the OpenAI-compatible `/v1/models`
   reports no context, so Hermes falls back to 8192 and rejects the model with
   "below the minimum 64,000":
   ```bash
   hermes config set model.context_length 131072
   hermes config set auxiliary.compression.context_length 131072
   ```
   `hermes config set` prints "not a recognized config key" for the auxiliary
   one, but it IS saved and read by the agent (confirmed in `agent/agent_init.py`
   via `cfg_get(_agent_cfg, "auxiliary", "compression")`).

5. **Raise the real `n_ctx` in LM Studio (separate from step 4)** — the engine
   rejects prompts with `"exceeds the available context size (8192 tokens)"` when
   the model was loaded with the default n_ctx. In the LM Studio UI: eject the
   model, reload it, set the **Context Length (n_ctx)** slider to >= 65536
   (ideally 131072). The API's `max_context_length` field is the theoretical max,
   NOT the loaded n_ctx — confirm with `loaded_instances[].config.context_length`.

6. **Verify end-to-end**
   ```bash
   hermes chat -q "Responde únicamente con la palabra: CONECTADO"
   ```

## Pitfalls

- **Token**: LM Studio's real token format is `lmstudio-...`; a random hex string
  returns `"Malformed LM Studio API token"`. For a trusted LAN, disabling auth is
  simpler than maintaining the token.
- **Two context knobs, both must be >= 64K**: Hermes' belief
  (`model.context_length` + `auxiliary.compression.context_length`) and the
  engine's enforced `n_ctx` (set in the LM Studio load UI). Fixing only one still
  fails — Hermes passes the startup check but the engine rejects the request.
- **Auxiliary compression model** inherits the same misdetected 8K context; it
  must be overridden too or startup fails after the main-model check passes.
- **RAM**: 7.5B Q4 with 128K context needs several GB for the KV cache. If the
  load fails on memory, drop to 65536 (still >= Hermes' 64K minimum).

## Verification

- `curl http://<host>:1234/api/v1/models` → `loaded_instances[].config.context_length` == 131072.
- `hermes chat -q "..."` returns a normal reply.
