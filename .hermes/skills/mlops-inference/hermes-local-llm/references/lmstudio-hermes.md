# LM Studio ↔ Hermes specifics

## Hermes provider overlay (source: hermes_cli/providers.py)

```python
"lmstudio": HermesOverlay(
    transport="openai_chat",
    auth_type="api_key",
    extra_env_vars=("LM_API_KEY",),
    base_url_override="http://127.0.0.1:1234/v1",
    base_url_env_var="LM_BASE_URL",
),
```

Implications:
- `lmstudio` is a first-class canonical provider — do NOT define a custom provider
  for it. `hermes model` / `hermes setup` should list it.
- Secrets go in `~/.hermes/.env` (`LM_API_KEY`, optionally `LM_BASE_URL`).
- `model.base_url` in `config.yaml` is the explicit override; `LM_BASE_URL` in
  `.env` is the provider-default fallback. Keep them consistent (both should point
  at the same host; the `/v1` suffix is optional — LM Studio routes `/`, `/v1`,
  and `/api/v1` the same).

## Endpoint differences

| Path | Type | What it returns |
|------|------|-----------------|
| `GET /v1/models` | OpenAI-compatible | `{"data":[{"id": "google/gemma-4-e4b", ...}]}` — id only, **no context** |
| `GET /api/v1/models` | LM Studio native | full model metadata incl. `max_context_length`, `loaded_instances`, `quantization`, `capabilities` |
| `POST /v1/chat/completions` | OpenAI-compatible | normal completions |

Always read the model list from `/api/v1/models` for diagnostics — it is the only
endpoint that reports `max_context_length` and shows whether the model is
currently loaded (`loaded_instances`).

## Error transcripts (verbatim, for pattern-matching)

Auth required (server has token auth enabled):
```json
{"error":{"message":"An LM Studio API token is required to make requests to this server, but none was provided using the Authorization header using the 'Bearer' scheme ...","code":"invalid_api_key"}}
```

Stored token wrong/expired:
```json
{"error":{"type":"invalid_request","code":"invalid_api_key","message":"Malformed LM Studio API token provided: 22aac52a71... Ensure you are using a valid token."}}
```

Context window below Hermes minimum (config override missing):
```
Failed to initialize agent: Model google/gemma-4-e4b has a context window of 8,192 tokens, which is below the minimum 64,000 required by Hermes Agent.
```

Same check on the auxiliary compression model:
```
Auxiliary compression model google/gemma-4-e4b has a context window of 8,192 tokens ... set auxiliary.compression.context_length to override the detected value if it is wrong.
```

Real engine context too small (config override present but model loaded with low n_ctx):
```json
{"error":{"code":400,"message":"request (17398 tokens) exceeds the available context size (8192 tokens), try increasing it","type":"exceed_context_size_error","n_prompt_tokens":17398,"n_ctx":8192}}
```
This is the key signal that the *load-time* context in the server is too small —
no amount of Hermes config can fix it; the model must be reloaded with a bigger
"Context Length"/"n_ctx" slider.

## LM Studio UI steps (current versions)

- Disable auth: Developer tab → Server section → turn OFF "Require API key" /
  "Authentication". For a trusted LAN this is the simplest fix.
- Raise context: eject/unload the model, then in the load panel drag "Context
  Length" (n_ctx) to the target (≥65536 for Hermes; 131072 for full 128K).
  Reload, then ensure the Server toggle is ON.
- Expose on LAN: ensure "Serve on local network" is enabled, otherwise the server
  only listens on 127.0.0.1 and a remote `http://192.168.0.x:1234` call won't
  reach it (a successful auth/context error response already proves LAN reach).

## Verification shortcut

```bash
hermes chat -q "Responde únicamente con la palabra: CONECTADO"
```
Fastest full-stack check: exercises auth → model id → main-model context →
auxiliary-compression context → real engine n_ctx, in one shot.
