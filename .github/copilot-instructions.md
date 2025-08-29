# Development Guidelines

## Philosophy

### Core Beliefs

* **Incremental progress over big bangs** — Small changes that compile and pass tests
* **Learning from existing code** — Study and plan before implementing
* **Pragmatic over dogmatic** — Adapt to project reality
* **Clear intent over clever code** — Be boring and obvious
* **No magic, just clean habits** — Think in reusable systems

### Simplicity Means

* Single responsibility per function/class
* Avoid premature abstractions
* No clever tricks — choose the boring solution
* If you need to explain it, it's too complex

## Mindset

### Thinking Patterns

* "How will this fail?" always comes before "How does this work?"
* Complexity is avoided with **opinionated consistency**, not more tools
* Each script/config/module should do one thing and look like it
* Ambiguity is the enemy — structure is the cure

### Daily Habits

* Systems are built from clean, modular parts
* All tasks should be traceable, testable, restartable
* Logs are written for future humans — make them human
* Prefer clarity, precision, and structure

---

## Process

### 0. Knowledge Base First

**ALWAYS check `.knowledge/` folder before starting major work:**

* `.knowledge/instructions/` — Implementation guidance
* `.knowledge/documentation/` — API/tool references
* `.knowledge/logbook/` — Project history

### 1. Planning & Staging

For major changes:

1. **Create logbook entry**

   ```bash
   cd .knowledge/logbook
   ./init.sh 'brief-description-of-change'
   ```

2. **Create `IMPLEMENTATION_PLAN.md`** with staged goals:

   ```markdown
   ## Stage N: [Name]
   **Goal**: [Specific deliverable]  
   **Success Criteria**: [Testable outcomes]  
   **Tests**: [Specific test cases]  
   **Status**: [Not Started|In Progress|Complete]
   ```

3. **Update statuses**, remove plan after all stages complete, and document in logbook.

### 2. Implementation Flow

1. Understand existing code
2. Write failing test (red)
3. Write minimum code to pass (green)
4. Refactor with tests passing
5. Commit with clear messages linked to plan

### 3. When Stuck (After 3 Attempts)

1. Document what failed (errors, assumptions)
2. Research 2–3 alternatives
3. Question fundamentals (abstraction, approach, complexity)
4. Try a different angle (library, architecture, simplify)

---

## Technical Standards

### Architecture

* Composition over inheritance
* Interfaces over singletons
* Explicit over implicit
* Test-driven where possible

### Code Quality

* Each commit must:

  * Compile
  * Pass all tests
  * Include new tests
  * Follow formatting/linting

* Before committing:

  * Run linter/formatter
  * Self-review
  * Clear commit message explaining “why”

### Error Handling

* Fail fast, with context
* Never swallow exceptions silently
* Handle at correct layer for visibility

---

## Decision Framework

When choices exist, prefer:

1. **Testability**
2. **Readability**
3. **Consistency**
4. **Simplicity**
5. **Reversibility**

---

## Integration Practices

### Learning the Codebase

* Find 3 similar implementations
* Match libraries, structure, test approach

### Tooling

* Use project build/test/lint tools
* Don't add new tools without strong justification

---

## Quality Gates

### Definition of Done

* [ ] Tests written and passing
* [ ] Linter/formatter clean
* [ ] Project conventions followed
* [ ] Clear commit messages
* [ ] Matches the plan
* [ ] No TODOs without issue links

### Test Guidelines

* Test behavior, not implementation
* Prefer one assertion per test
* Use meaningful test names
* Tests must be deterministic

---

## Documentation & Communication

* Document like it’s a clean install
* Number steps, use ASCII (`-->`, `^^^`)
* Assume the reader knows nothing
* Enforce structure and formatting discipline

---

## Non-Code Technical Habits

* Clean up before automating
* Simulate or dry-run before real runs
* Run things locally to understand them
* Avoid hidden defaults — be explicit

---

## Personal Conduct

### Work Style

* Build fresh, don’t fix spaghetti
* Comments explain “why,” not “what”
* Tools should match problem-solving flow
* Structure folders and names to scale

### Communication

* Be direct, not rude
* Say what matters, then stop
* Ask clear, critical questions
* Prioritize clarity over niceness when needed

---

## Aesthetic Choices

* Pixel-perfect terminals
* Monospace, dark red themes
* Minimal, modern, logic-driven interfaces

---

## Final Reminder

**NEVER**:

* Use `--no-verify`
* Disable tests
* Commit broken code
* Skip `.knowledge/` or logbook

**ALWAYS**:

* Reference `.knowledge/` before starting
* Create plans for infra/arch work
* Write clean, traceable code
* Document failures and rethink after 3 tries

---

## Summary

* Build reusable systems
* Enforce structure daily
* Document once — clearly
* Eliminate magic, enforce habits

This is how we do things — properly.
