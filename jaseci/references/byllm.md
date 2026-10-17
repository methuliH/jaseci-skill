# byLLM: AI functions (offline fallback)

Prefer `jac guide jac-by-llm`. Requires `pip install byllm`. Verified on jaclang 0.16.x.

`by llm()` replaces a function body. The compiler builds the prompt from the
name, types and `sem` strings, and makes the model's output match the return type.

```jac
import from byllm.lib { MockLLM }

enum Sentiment { POSITIVE, NEGATIVE, NEUTRAL }

obj Review {
    has summary: str;
    has sentiment: Sentiment;
    has score: int;
}
sem Review.score = "1-5 star rating implied by the text.";

def analyze(text: str) -> Review by llm(temperature=0.0);
sem analyze = "Analyze a product review.";
sem analyze.text = "Raw customer review text.";

def word_count(text: str) -> int { return len(text.split()); }
sem word_count = "Count words in text.";
sem word_count.text = "Text to count.";

def answer(question: str) -> str by llm(tools=[word_count], max_react_iterations=4);
sem answer = "Answer the question, calling tools when useful.";

# For real use, delete this glob and configure jac.toml instead (see below).
glob llm = MockLLM(model_name="mockllm", config={"outputs": [
    Review(summary="Great", sentiment=Sentiment.POSITIVE, score=5)
]});

test "analyze is typed" {
    r = analyze("Love it, works perfectly.");
    assert r.sentiment == Sentiment.POSITIVE;
}
```

## Configuring a real model

jac.toml:
```toml
[plugins.byllm.model]
default_model = "gpt-4o-mini"     # or "claude-sonnet-4-6", "gemini/gemini-2.0-flash", "ollama/llama3"
```
Set `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY` (Ollama needs none).
Per file override: `import from byllm.lib { Model }` then
`glob llm: Model = Model(model_name="gpt-4o");`. Any glob name works:
`def f(x: str) -> str by fast();`.

## Rules

- `llm` is ambient. No glob is needed if jac.toml sets the model.
- Describe everything the model should know with `sem`, not docstrings.
- Return `obj`/`enum`/`list[obj]`/`T | None`, not `node`. Copy into nodes to persist.
- No inline `"..." by llm` expressions. Always declare a function.
- `tools=[fn, self.method]` take function references, not strings, and each
  tool needs its own `sem`. Tools turn on the ReAct loop automatically.
- Options: `temperature, max_tokens, tools, max_react_iterations, conversation=list,
  system_prompt, stream=True (str only, returns a generator), incl_info={...},
  max_output_retries`. Typos in options only fail at runtime.
- Methods: `def advise(q: str) -> str by llm();` inside an `obj` automatically sees its `has` fields.
- Multimodal: `import from byllm.lib { Image, Video }`; `def f(img: Image) -> T by llm();`.
- Errors: `ByLLMError` subclasses from `byllm.lib` (`RateLimitError`, `OutputConversionError`, ...).
- Endpoints that call LLMs or `await` should be `async def:pub`.
