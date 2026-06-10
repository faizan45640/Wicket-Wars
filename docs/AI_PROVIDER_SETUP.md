# AI Provider Setup

Wicket Wars now tries AI generation in this order:

1. Hugging Face Inference Providers
2. Google AI
3. Deterministic fallback players/commentary

The Flutter app never stores AI keys. All AI calls happen in Firebase Functions.

## Hugging Face Token

Create a Hugging Face access token from:

https://huggingface.co/settings/tokens

Then save it as a Firebase Functions secret:

```bash
npx firebase-tools functions:secrets:set HUGGING_FACE_TOKEN
```

Paste the Hugging Face token when Firebase asks for the value.

## Google AI Backup Token

If you also want Google AI as backup:

```bash
npx firebase-tools functions:secrets:set GOOGLE_AI_API_KEY
```

## Deploy Functions

```bash
npx firebase-tools deploy --only functions
```

## Hugging Face Token Permission

Inference Providers calls require a token with the **"Make calls to Inference
Providers"** permission. If you use a fine-grained token without this scope, every
call returns 401/403 and the app silently uses fallback players. A classic
read/write token also works.

## Free Tier Note

Hugging Face free accounts get a small monthly inference credit (about $0.10),
PRO accounts get more. This is plenty for a viva demo (dozens of small
generations), but if credits run out the app automatically falls back to Google
AI, then to deterministic data. For heavier use, configure `GOOGLE_AI_API_KEY`
(Gemini has a more generous free tier for students).

## Optional Model Selection

The default Hugging Face models are configured in `functions/index.js`:

```text
meta-llama/Llama-3.1-8B-Instruct,Qwen/Qwen2.5-7B-Instruct
```

These are tried in order; the first one that responds is used. Both were
verified live on the Inference Providers router for this project. To minimize credit usage you
can append `:cheapest` to a model id (for example
`meta-llama/Llama-3.1-8B-Instruct:cheapest`) to route to the lowest-cost
provider. If a model becomes unavailable, replace it in `HUGGING_FACE_MODELS`
inside `functions/index.js` (or set the `HUGGING_FACE_MODELS` env var) and redeploy.

## How To Verify

Open a starter pack in the app. The starter pack screen should show one of:

- `huggingface:<model>`: Hugging Face generated the basic players.
- `google:<model>`: Google AI generated the basic players.
- `fallback`: API failed or rate-limited, fallback players were used.

Check backend logs:

```bash
npx firebase-tools functions:log --only openStarterPack --lines 80
```

