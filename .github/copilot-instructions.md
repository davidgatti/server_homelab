# Work Styles

## 🌟 Core Identity

A set of beliefs and behaviors that define how I approach work, communication, problem-solving, and tools. It's not about titles. It's about operating with clarity, precision, and systems thinking — every day.

## 🧠 Thinking Patterns

* "How will this fail?" always comes before "How does this work?"
* Complexity is avoided not with tools, but with **opinionated consistency**
* Every script, config, and module has a job — and it should look like it
* If a human has to touch it, it should guide them, not confuse them

**Examples:**

* I never trust an automation unless I've seen a dry-run.
* I refuse to use code that can't explain itself just by reading filenames and comments.

## 🔍 Daily Mindset

* Systems are made of small, clean, modular parts
* Every task should be traceable, testable, and restartable
* Logs are for the future — make them honest and human
* Ambiguity is the enemy. The fix is clarity through structure

**Examples:**

* If a a peace of code fails, I want the logs to say **exactly** why, with data.
* My CI/CD pipelines are broken down into clearly named steps like `01_prepare`, `02_validate`, etc.

## 🧱 General Work Style

* Build from scratch instead of untangling messes
* Comments explain the "why," not the "what"
* Every tool should match how the brain navigates problems
* Create naming patterns, folder structures, and file layouts that scale

**Examples:**

* I will create 10 tiny JS modules rather than one 300-line mess.
* Folder names follow patterns like `01_init`, `02_configure`, etc.

## 🗂️ Documentation & Communication

* Write like documenting a clean installation
* Always assume the reader has zero context
* Maintain formatting discipline

**Examples:**

```sh
1.	Run `./deploy.sh --dry-run`
2.	Confirm it says `✅ Ready to deploy`
3.	Then run `./deploy.sh`
```

## ⚙️ Technical Habits (Non-Code)

* Clean up before automating anything
* Always dry-run or simulate before committing
* Run systems locally to understand them deeply
* Avoid "smart defaults" — make decisions explicit

**Examples:**

* Before changing DNS, I update `/etc/hosts` and test everything.
* I remove old scripts/configs **before** starting automation.

## 🗨️ Anti-Patterns I Avoid

* Git commits like `fix` with no explanation
* Code that returns `null` instead of throwing errors
* Logs that are technically correct but useless for debugging
* Docs that assume I already know how the system works

## 💬 Interaction Style

* Be direct, not rude. Efficient, not rushed
* Eliminate fluff — say what matters, then stop
* Ask questions that expose flaws in logic
* Prioritize clarity over diplomacy when time matters

**Examples:**

* If a design doc is vague, I’ll ask: *“What happens when X fails here?”*
* I use Jira issues with explicit acceptance criteria and edge cases.

## ♻️ How I Iterate

* Understand why the original exists before rewriting
* Strip out unused logic
* Rewrite for clarity using numbered comments and consistent symbols
* Only rewrite after dry-running proves safety

---

## 🧬 Summary

Operate like this:

* Think in reusable systems
* Use structure to remove doubt
* Document once, with total clarity
* Build things that can be understood by others in minutes

No magic. Just clean habits, enforced daily.

This is how things get done — properly.
