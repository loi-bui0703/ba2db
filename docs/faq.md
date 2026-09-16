# FAQ

### Does this replace a data architect?

No, and designs that treat it that way will disappoint you. It replaces the
*blank page* and enforces the discipline a good architect applies by habit —
citing sources, normalizing deliberately, justifying every index, admitting what
the documents do not say. A human still has to answer the open questions and
own the result.

### Which model should I use?

Any model strong enough to read a long document carefully. The workflow is
model-agnostic on purpose. In practice the extraction stage rewards larger,
more careful models; the later stages are more mechanical.

If you compare models, please
[file what you find](https://github.com/loi-bui0703/ba2db/issues) — real
comparisons are more useful than our guesses.

### My BA documents are in Vietnamese. Does that work?

Yes — that is the primary case this was built for. The skill reads Vietnamese
documents, writes bilingual EN/VI artifacts, and keeps every identifier and all
SQL in English `snake_case`.

### How large a document set can it handle?

Split by subsystem. A single subsystem's documents comfortably fit any modern
context window, and Stage 0's inventory is designed to help you split. For a
very large system, run the workflow per subsystem and reconcile the conceptual
models at Stage 2.

### Can it read .docx / .pdf / Confluence?

Whatever your agent can read, the skill can use — it never parses files itself.
That is deliberate: a parser would be one more dependency and one more thing to
break. If your agent cannot open a format, convert it first.

### What if the BA documents are incomplete or contradictory?

That is the normal case, and the workflow is built for it rather than around it:
contradictions go to `CONFLICTS` with **both** versions kept, gaps become
`OPEN QUESTIONS` with a stated default assumption, and low-certainty extractions
are marked `Confidence: low`. The final report surfaces all three.

A design that ships with fifteen documented open questions is more useful than
one that silently guessed fifteen times.

### Does it support NoSQL?

Not well. Stages 0–2 are useful for any data model, but Stages 3–5 assume a
relational target — normalization, FKs, DDL. Document-store design trades on
different rules (access-pattern-first, deliberate duplication). Forcing that
into this workflow would produce relational thinking in a JSON costume.

### Will it run migrations on my database?

No. It generates DDL and, if you ask, validates syntax by applying it to a
**temporary scratch database** that it drops afterwards. It never touches an
existing database.

### Does it send my documents anywhere?

The package makes no network calls and has no telemetry. Your agent, however,
sends whatever you give it to whichever model provider you use — that is between
you and them. For confidential BA documents, use a model deployment you trust.

### Why zero dependencies?

This package writes files into your home directory and your repository, and
installs instructions an AI agent will follow. Both deserve a supply chain of
exactly zero. It is also why `skill/` is plain Markdown you can read end to end.

### Can I customise the templates?

Yes — that is expected. Edit them in your installed copy, or fork. If your change
would help others (a DBMS dialect, a missing pattern, a stricter checklist item),
a PR is very welcome.

### It produced a bad design. What now?

[File a skill-quality issue](https://github.com/loi-bui0703/ba2db/issues/new?template=skill-quality.yml)
with the input, the output, and what it should have been. That is the product
failing — it is the most actionable report this project can receive.
