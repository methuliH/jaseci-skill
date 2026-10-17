"""Minimal REST API: walker:pub and def:pub become POST endpoints.

Run:   jac start main.jac --no_client
Try:   curl -X POST localhost:8000/walker/add_note -H 'Content-Type: application/json' -d '{"text": "hi"}'
       curl -X POST localhost:8000/function/list_notes -H 'Content-Type: application/json' -d '{}'
Docs:  http://localhost:8000/docs
"""

node Note {
    has text: str;
    has pinned: bool = False;
}

walker:pub add_note {
    has text: str;

    can create with Root entry {
        note = (root ++> Note(text=self.text))[0];
        report note;
    }
}

def:pub list_notes() -> list[Note] {
    return [root -->[?:Note]];
}

def:pub pin_note(note_id: str) -> Note | None {
    for n in [root -->[?:Note]] {
        if jid(n) == note_id {
            n.pinned = True;
            return n;
        }
    }
    return None;
}
