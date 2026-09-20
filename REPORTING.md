# REPORTING

How to report a bug or ask for a feature so we can act on it. The forms are in
`.github/ISSUE_TEMPLATE`; this is the work you do before you fill one. It is the
same whether you are a person or an agent: an agent that reaches this file from
`AGENTS.md` follows every step below.

## Before you file

1. **Decide it is Bend, not your program.** A `.bend` the checker rejects, or a
   program that fails its own logic, is yours to fix. File only when Bend itself
   is wrong: the checker admits a bad term, a backend prints a wrong value, the
   compiler crashes, or two lanes disagree on the same program. Re-decide this
   for every report — a real bug last time does not make the next one real.

2. **Read `WONTFIX.txt`.** Every entry there is a closed question: a design
   choice, a capacity limit, or an open problem with no solution we trust yet.
   If your report is one of them we will close it as such. The `#NNN` on each
   entry is the issue that already covers it.

3. **Search the tracker** (`gh issue list --repo bendlang/bend --search "..."`,
   open and closed). If the bug is already there, add to that issue — see
   Follow up — do not open a second one.

## Make it small

4. **Reduce it to the smallest `.bend` that still shows the bug.** Cut every def
   and argument the bug does not need. A ten-line file we can run beats a project
   we cannot.

## What the form wants

5. **Collect the fields, exactly** (`bug.yml`):
   - the command you ran — e.g. `bend main.bend -o main`
   - the output — the whole error, or the wrong result next to the right one
   - the file — the small `.bend` from step 4
   - `bend --version`
   - `uname -sm`
   - `clang --version` — the first line

   For a feature (`feature.yml`): the code you would write, and what it lets you
   do that Bend does not today. Check the SOON and OPEN sections of `WONTFIX.txt`
   first — some of it is already coming.

6. **Sanitize.** Strip absolute paths, host names, tokens, and anything private
   from the output and the file; keep the part that shows the bug. `/Users/you/…`
   becomes `…/`.

## File it

7. Open the form (blank issues are off — pick Bug or Feature) and paste the
   fields. From the CLI one non-interactive call carries the same fields:

   ```
   gh issue create --repo bendlang/bend --label bug \
     --title "<one line: what breaks>" \
     --body "$(cat body.md)"
   ```

   where `body.md` holds the six fields above, each under its own heading. The
   title is one line naming what breaks — not "bug", not "help".

## Follow up

8. New information — a smaller repro, another platform, a workaround — is a
   comment on the same issue (`gh issue comment <n> --repo bendlang/bend`), not
   a new issue. Do not close someone else's issue; say what you found and let us.
