"""Graph + walker basics: model tasks as nodes, query and traverse them."""

node Project {
    has name: str;
}

node Task {
    has title: str;
    has done: bool = False;
    has points: int = 1;
}

edge HasTask: Project --> Task {
    has order: int = 0;
}

walker ProgressReport {
    has done_points: int = 0;
    has total_points: int = 0;
    has reports: list[dict] = [];

    can start with Root entry {
        visit [-->[?:Project]];
    }

    can tally with Task entry {
        self.total_points += here.points;
        if here.done {
            self.done_points += here.points;
        }
    }

    can on_project with Project entry {
        visit [here ->:HasTask:->];
    }

    can finish with Root exit {
        report {"done": self.done_points, "total": self.total_points};
    }
}

with entry:__main__ {
    proj = (root ++> Project(name="hackathon"))[0];
    proj +>:HasTask(order=1):+> Task(title="Set up repo", done=True, points=1);
    proj +>:HasTask(order=2):+> Task(title="Build backend", points=3);
    proj +>:HasTask(order=3):+> Task(title="Demo video", points=2);

    open_tasks = [t for t in [proj ->:HasTask:->] if not t.done];
    print([t.title for t in open_tasks]);

    result = root spawn ProgressReport();
    print(result.reports[0] if result.reports else {});
}
