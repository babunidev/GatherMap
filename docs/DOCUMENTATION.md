# Documentation and Human–AI Collaboration Standard

This document is the repository-local standard for project documentation. Read it alongside the root `AGENTS.md` and the relevant source files before writing or revising project records. It must remain usable independently of any ChatGPT Project, agent session, or another GitHub repository.

## Authority, identity, and attribution

- The human **creative** supplies the original ideas, motivation, creative direction, constraints, corrections, and final decisions. AI may propose, research, draft, code, edit, test, and operate tools; credit it only for work supported by evidence.
- In Babuni's own project narratives, **Babuni** identifies the human creative; **babuni.dev** identifies the website/portfolio, not the person. Preserve a repository's explicitly established public byline, historical legal notices, and distinct third-party original-idea or contributor credits. Do not overwrite them with a blanket attribution.
- Use **creative**, not **creator**, as the role label for a person who conceives or makes a work. Do not rewrite verbatim historical quotations, licenses, or third-party notices to enforce this editorial preference.
- Never imply that the human manually wrote AI-generated code, or that AI originated a human-supplied concept. Never treat an AI suggestion, speculative design, or remembered discussion as an approved decision.

## Public narrative and development-journal voice

- Tell public-facing development narratives from the human creative's **first-person perspective**, naturally using “I” and “my” within sentences, but **never begin a narrative sentence with “I” or “My.”** Avoid telling the creative's own story in third person.
- Write concise, thoughtful prose for human readers rather than an AI status report or a chronological dump of tool calls. A small change may need only a few sentences; group related micro-steps.
- Describe what prompted the work, how the idea or problem developed, what the creative directed or decided, what AI contributed, what changed in the repository, and what was actually verified. Include a rejected approach, failed attempt, correction, or disagreement when it explains the outcome.
- Technical specifications, architecture, changelogs, test inventories, and instructions may use neutral language when clearer. Fiction and in-world prose follow their own project-specific writing guides, not the development-journal voice.
- When history is incomplete, label it **retrospective reconstruction** and state the limitation. Paraphrase relevant conversations; do not invent quotes, feelings, motives, dialogue, dates, accepted proposals, commits, or tests.

## Documentation responsibilities

Use the existing files when present; create a missing file only when the repository needs it. Project-specific structures, canonical design archives, story guides, historical logs, and content taxonomies remain authoritative for their own subjects.

| File | Responsibility |
| --- | --- |
| `README.md` | Public entry point, project purpose, usage and current status |
| `CONCEPT.md` | Human creative vision, motivations, approved goals and boundaries |
| `ROADMAP.md` | Planned, in-progress, completed and deferred work with truthful status |
| `CHANGELOG.md` | Actual repository changes; no proposals or unimplemented features |
| `AGENTS.md` | Repository-specific agent, technical, safety and workflow rules |
| `docs/DOCUMENTATION.md` | This shared writing and attribution standard |
| `docs/DEVLOG.md` | Short, publishable first-person account of meaningful development |
| `docs/DECISIONS.md` | Confirmed decisions, important alternatives, reasoning and open questions |
| `docs/DESIGN.md` | Visual, interaction or experience design, when relevant |
| `docs/ARCHITECTURE.md` | Source-backed structure, interfaces and technical constraints, when relevant |
| `docs/CONTENT.md` | Project content organization and editorial rules, when relevant |
| `docs/AI_COLLABORATION.md` | Attribution methodology, evidence and roles |

Do not force every repository to have software tests, a UI design, or the same folder layout. An archive, game, addon, website, tool, and story project may legitimately differ.

## Evidence and change workflow

1. Read `AGENTS.md`, this standard, the relevant project documentation, current code/content, and available history. Do not assume access to earlier private conversations.
2. Separate **creative direction**, **AI proposals**, **iterations/corrections**, **explicit decisions**, **implementation**, and **verification**. Record only stages supported by the available evidence.
3. Make narrowly scoped, reviewable edits. Preserve historical documents and the repository's established facts, identity, licenses, privacy safeguards, and project-specific constraints.
4. For substantial implementation, update the affected documents in the same change when practical: describe the new behavior, decision, changed paths/commit, test command and environment, observed results, and limitations. Update the changelog only for actual changes.
5. For discussion-only work, document approved or pending directions without claiming implementation. For documentation-only work, do not edit runtime behavior or call code untested merely because its documentation was revised.
6. Verify paths, relative links, contradictions, and the final diff. Distinguish source review, automated or mocked checks, actual target-environment testing, release and deployment; one is not proof of another.
7. Exclude credentials, keys, private chats, personal records, unpublished sensitive material, and unrelated details from public documentation. Preserve third-party rights and attribution.

## Precedence

The root `AGENTS.md` governs this repository's unique technical and creative constraints. Established project-specific source-of-truth documents govern their subject matter. This file governs shared documentation voice, provenance, attribution, and status reporting unless the human creative explicitly approves a different standard. If instructions conflict, identify the conflict rather than silently changing project direction.
