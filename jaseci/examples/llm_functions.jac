"""byLLM basics: typed AI functions. Tests use MockLLM, so no API key is needed."""
import from byllm.lib { MockLLM }

enum Priority { LOW, MEDIUM, HIGH }
sem Priority.HIGH = "Urgent: blocks users or the demo.";

obj Ticket {
    has title: str;
    has priority: Priority;
    has tags: list[str];
}
sem Ticket.title = "A short summary of the issue.";
sem Ticket.tags = "Lowercase keywords describing affected areas.";

def triage(bug: str) -> Ticket by llm(temperature=0.0);
sem triage = "Turn a raw bug report into a structured Ticket.";
sem triage.bug = "The user's free-text bug report.";

def classify(bug: str) -> Priority by llm();
sem classify = "Classify how urgent a bug report is.";

# Module-level override of the ambient `llm`. In a real app, drop this and set
# [plugins.byllm.model] default_model in jac.toml (plus the provider's API key env var).
glob llm = MockLLM(
    model_name="mockllm",
    config={"outputs": [Ticket(title="Login fails", priority=Priority.HIGH, tags=["auth"]), Priority.LOW]}
);

test "triage returns a typed Ticket" {
    t = triage("I can't log in since the last deploy!");
    assert t.priority == Priority.HIGH;
    assert "auth" in t.tags;
    assert classify("typo on the about page") == Priority.LOW;
}
