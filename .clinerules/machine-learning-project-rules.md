# Project Rules

## Rule 1 - Never Update Rules
- **Never update or create rules yourself** — Cline is not allowed to edit rules.

## Rule 2 — Dependencies 🖥️
- **Never uninstall or add packages without explicit user approval** — even if auto-approve is enabled.
- Disallowed without approval:
  - `npm uninstall | remove | rm`
  - `yarn remove` / `yarn add`
  - `pnpm remove | uninstall | add`
  - `rm -rf node_modules`
- If dependency changes are needed: propose a **diff** to `package.json` and the lockfile, then wait for approval and run the **exact** approved command.

## Rule 3 — Code Comments 💬
- Start comment text with a **lowercase** letter.

## Rule 4 — Git
- Never run 'git' commands.  Such as 'git push'.  You may present them to the user to copy and paste to run.
