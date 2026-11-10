# Writing documentation for people

This guide travels with the repository. Read it with [AGENTS.md](../AGENTS.md) and the relevant project files before making changes. It is a writing and evidence standard, not a replacement for project-specific rules.

## Begin with the reader

A visitor should understand **what this project is, why it exists, what works today, and where to go next** without reading a development transcript.

- Start with a clear introduction in ordinary language. Explain jargon when it first matters.
- Keep the `README.md` an entry point, not a running stream of version notes, internal audits or AI work reports. Put detailed technical evidence and dated history in linked documents.
- Give each document a distinct job. Use informative headings, connected paragraphs, short lists where useful, and links to deeper material. A small navigation table is helpful only when there are genuine choices.
- Move dense or older material to a clearly labeled reference or historical page when necessary; **do not silently delete evidence or collapse an important disagreement**.
- Avoid repeating status disclaimers or the same background across multiple sections. Use a concise status summary and link to the evidence.
- Treat Markdown as a reading surface: sensible heading levels, readable tables, correctly fenced code, descriptive links and relative paths that work on GitHub.
- Write for the project's audience. A player guide, story, technical specification, journal and AI instruction file should not sound identical.

## Authorship and development history

**Babuni is the human creative; babuni.dev is the website**, not the person. Preserve established project-specific bylines, original-idea credits, contributor attributions, licenses and third-party notices. Use **creative**, not *creator*, as the role label for someone making a work, without rewriting protected quotations or legal material.

AI can research, propose, draft, write code, test and edit files. Credit its actual contribution without transferring the human creative's ideas or decisions to AI. Do not say the creative wrote code that AI produced. An AI suggestion is not approved merely because it was recorded.

Tell public development history **from the human creative's first-person perspective**, using *I* and *my* naturally within sentences but **never beginning a sentence with “I” or “My.”** Write in a reflective, concrete, readable voice rather than as an AI activity report. Explain what prompted a meaningful change, how the creative directed or corrected it, what AI did, and what resulted.

A small change may need only two or three sentences. Group related micro-steps. Preserve the disagreements, failed attempts and alternatives needed to understand the result. If earlier history cannot be verified, label it a **retrospective reconstruction** instead of inventing a seamless narrative.

Technical specifications, changelogs and reference instructions may use neutral language. Fiction and world lore follow their own writing standards.

## Keep documents in their proper place

| Document | Reader's question |
| --- | --- |
| `README.md` | What is this, how do I use or explore it, and where should I read next? |
| `CONCEPT.md` | What is the creative idea, and what boundaries matter? |
| `ROADMAP.md` | What is planned, underway, completed or deferred? |
| `CHANGELOG.md` | What actually changed in the repository or release? |
| `docs/DEVLOG.md` | How did the work and decisions develop, in the creative's voice? |
| `docs/DECISIONS.md` | What was accepted, rejected or left unresolved, and why? |
| `docs/ARCHITECTURE.md` | How does the implemented or proposed system fit together? |
| `docs/DESIGN.md` | What are the visual and interaction choices? |
| `docs/CONTENT.md` | How is the material organized and published? |
| `docs/AI_COLLABORATION.md` | How are evidence, roles and attribution handled? |
| `AGENTS.md` | What must contributors and AI agents obey in this repository? |

Use only files the project needs. Story archives, games, websites, addons and tools need different structures. Canonical world material and historical source archives retain their own authority.

## Make claims that the evidence supports

Keep these categories separate:

- **Creative direction:** a goal or constraint supplied by the human.
- **Proposal:** an unapproved possibility.
- **Decision:** a choice explicitly accepted by the human.
- **Implementation:** work actually present in files or running systems.
- **Verification:** a particular source review, test, device check, live integration or deployment observation.

A source build is not a device test. A mock API is not a server integration. A Git tag is not a published release, and a deployed page is not proof that all interactions work. Date status claims and link to the relevant result.

Do not guess test outcomes, acceptance, dates, commits, quotes or history. Preserve uncertainty. Do not describe unfinished code or an unratified design as live behavior.

## Editing workflow

1. Read `AGENTS.md`, this guide, related documentation and the actual source/history. Resolve contradictions rather than assuming one document is current.
2. Identify the reader and the document's job. Improve the opening, order and navigation before polishing individual sentences.
3. Preserve facts, creative decisions, canon, technical restrictions, public privacy boundaries, licensing and third-party credit. Keep significant historical material in a discoverable place.
4. Make reviewable edits. For substantial implementation, update the relevant roadmap, decision record, changelog and brief development entry alongside code when practical.
5. For discussion-only or documentation-only work, say so; never invent an implementation or test. Check relative links, titles, status language and the diff.
6. Keep credentials, private conversations, real member/player records, tokens, personal information, unpublished secrets and unrelated details out of public repositories.

## Precedence

`AGENTS.md` and established project-specific source-of-truth documents govern their own subjects. This guide governs shared readability, documentation voice, attribution and evidence unless the creative explicitly approves another standard. Flag conflicts rather than silently rewriting the project's direction.
