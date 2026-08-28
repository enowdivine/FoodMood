/// Groq API configuration.
///
/// Paste your key below. Free keys: https://console.groq.com/keys
///
/// The key is compiled into the client bundle, which is acceptable for a demo
/// but not for production — a real deployment proxies this call through a
/// backend so the secret never reaches the browser.
const String kGroqApiKey = 'PASTE_YOUR_GROQ_API_KEY_HERE';

const String kGroqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

/// Groq retired the Llama 3.3 endpoints; this is the strongest chat model
/// currently served on the free tier. Check https://console.groq.com/docs/models
/// if this ever 404s — swapping the id here is the only change needed.
const String kGroqModel = 'openai/gpt-oss-120b';

/// Placeholder shipped in the repo when no key is configured.
const String _keyPlaceholder = 'PASTE_YOUR_GROQ_API_KEY_HERE';

/// True once a real key has been filled in.
bool get hasGroqKey =>
    kGroqApiKey.isNotEmpty && kGroqApiKey != _keyPlaceholder;
