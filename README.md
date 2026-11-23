[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/chainforge?utm_medium=integration&utm_source=button&utm_campaign=chainforge)

# Deploy and Host ChainForge on Railway

ChainForge is an open-source visual environment for testing prompts across large language models. You build flows on a canvas: send many prompt variants to several models at once, compare their answers side by side, score them with code or LLM evaluators, and plot the results, without writing a test harness.

## About Hosting ChainForge

ChainForge is a Python (Flask) server that serves its React canvas and saves flows to disk. It has no login of its own and can run Python code you write in evaluator nodes, so this template never exposes it directly. ChainForge listens only inside the container, behind a small Caddy front that asks for a generated password and refuses requests from other sites. Flows, settings, uploaded files and custom providers are stored on a Railway volume, so they survive redeploys and restarts. The only value you supply is your LLM API key. Updates arrive as Railway update notices when we bump the pinned version.

## Common Use Cases

* Compare how several models (GPT, Claude, Gemini, local or OpenRouter models) answer the same prompts
* Test many prompt templates and input variables at once, then score the answers with Python or LLM evaluators
* Share a hosted prompt-evaluation workspace with a small team, with saved flows that persist

## Dependencies for ChainForge Hosting

* An API key for at least one LLM provider (OpenAI by default; Anthropic, Google, OpenRouter and others can be added in Settings)
* One Railway volume for flows and settings (created by the template)

### Deployment Dependencies

* ChainForge on GitHub: https://github.com/ianarawjo/ChainForge
* ChainForge on PyPI (version 0.3.7.8 is installed): https://pypi.org/project/chainforge/
* ChainForge documentation: https://chainforge.ai/docs/
* Template repository: https://github.com/aalfath/chainforge-railway-template

### Implementation Details

**What you get:** one `ChainForge` service built from our public GitHub repository. Inside it, ChainForge 0.3.7.8 runs on 127.0.0.1, and Caddy serves your Railway URL on `PORT` 8080, with a password on everything except `/healthz` (Railway's health check). A volume at `/data` holds your flows and settings.

**After deploy:**

1. Open the service's **Variables** tab and copy `CHAINFORGE_PASSWORD`.
2. Open the public URL and sign in as `admin` with that password.
3. Start from an example (**Example Flows**) or a blank flow, and press **Run** on a Prompt Node.

**Variables:**

| Variable | What it does |
|---|---|
| `OPENAI_API_KEY` | **Required.** Your OpenAI API key (https://platform.openai.com/api-keys), or a key for any OpenAI-compatible API. |
| `OPENAI_BASE_URL` | Optional. Leave empty for OpenAI. Set it to use another OpenAI-compatible API, for example `https://openrouter.ai/api/v1`. |
| `CHAINFORGE_USERNAME` | Sign-in name, `admin` by default. |
| `CHAINFORGE_PASSWORD` | Generated sign-in password. |

Keys for other providers (Anthropic, Google, Azure, Bedrock, Together, DeepSeek, OpenRouter, Ollama) can be added later in ChainForge's **Settings** page or as variables (`ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY` and so on). ChainForge calls OpenAI-compatible APIs directly from your browser, so a custom `OPENAI_BASE_URL` must allow browser requests (CORS), as OpenAI and OpenRouter do.

**Not included:** the optional RAG nodes (`chainforge[rag]`, which needs PyTorch and much more memory) are left out, so the core app runs in 0.5 GB of RAM. It used about 100 to 150 MB in our tests. Anyone who reaches the app with the password can run Python code on the server through evaluator nodes, so share the password only with people you trust.

**Updates:** the template builds from https://github.com/aalfath/chainforge-railway-template. When we move it to a new ChainForge release, Railway shows an update notice on your project, and you choose when to apply it. Your volume keeps your flows. Read `CHANGELOG.md` in the repository first.

## Why Deploy ChainForge on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying ChainForge on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
