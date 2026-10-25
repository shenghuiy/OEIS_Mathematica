---
name: docs-page
description: Writing the Markdown in docs/ and the READMEs, which GitHub renders — the TeX that GitHub's math renderer rejects or mangles (\operatorname, and the backslash escapes \{ \} \, \! that Markdown eats inside $...$), the checker script that finds and fixes them, and how to confirm the rendered page. Use when adding or editing a .md page with math, or when GitHub shows "The following macros are not allowed" or a formula renders wrong.
---

# Docs pages on GitHub

Every page in `docs/` and the READMEs is read on github.com, so a page is done when GitHub renders it correctly, not when the Markdown source looks right. Which pages exist and the three indexes a new package goes in are listed in `CLAUDE.md`.

## How GitHub renders math

GitHub typesets `$...$` and `$$...$$` with MathJax, but three things happen first.

1. **Markdown escapes run before MathJax.** A backslash before ASCII punctuation is a Markdown escape, so GitHub drops the backslash and MathJax sees only the punctuation. This happens in inline and display math alike:

   | Source | MathJax sees | Shows as | Write instead |
   |---|---|---|---|
   | `\{1, 2\}` | `{1, 2}` (a group) | 1, 2 | `\lbrace 1, 2\rbrace` |
   | `(p + 1)\, p` | `(p + 1), p` | a literal comma | `(p + 1)\thinspace p` |
   | `p\!\left(n\right)` | `p!\left(n\right)` | p!(n), a factorial | `p\negthinspace\left(n\right)` |

   Macros spelled with letters (`\lbrace`, `\thinspace`, `\sum`, `\dots`) are not Markdown escapes and pass through untouched. Everything in the right-hand column, and `\mathrm`, has been seen typesetting correctly on GitHub.

2. **Some macros are refused.** GitHub replaces the formula with "The following macros are not allowed: operatorname". For an operator name write `\mathrm{lcm}`; the operators MathJax has built in (`\gcd`, `\max`, `\log`, `\sum`) work as they are.

3. **`_` after punctuation, and `*`, can become emphasis.** When one line has two inline formulas like `$\mathrm{diag}_k$ to $\mathrm{diag}_{k+1}$` or `$H_{P^*}$ ... $P^*$`, Markdown pairs the `}_` underscores, or the asterisks, as `<em>...</em>` across the text between them. Both formulas then show as raw TeX with the text between them in italics, and the checker does not catch this. Write those formulas in GitHub's code-span form, $`\mathrm{diag}_k`$, which Markdown leaves alone. An underscore after a letter (`H_{x}`, `a_n`) is inside a word and never pairs.

## Check every page you touch

1. Run the checker from the repository root (no arguments checks `README.md` and `docs/*.md`):

   ```bash
   py -I .claude/skills/docs-page/check_github_math.py --fix
   ```

   `--fix` rewrites each escape in the table above to its named macro, in place; without it the script only reports. It also reports refused macros and other escapes (`\;`, `\:`), which it cannot fix: replace those by hand with a macro spelled in letters, and confirm it renders. Done when a run without `--fix` prints nothing and exits 0. Read the diff of any file it fixed.

2. After pushing, open each changed page on the branch, `https://github.com/shenghuiy/OEIS_Mathematica/blob/<branch>/docs/<page>.md`, in the built-in browser. Each formula is a `math-renderer` element whose text is the TeX MathJax will receive, after Markdown has had its turn:

   ```js
   [...document.querySelectorAll('article.markdown-body math-renderer')].map(e => e.textContent.trim())
   ```

   Done when every entry has the same backslashes as the `$...$` in the source. The built-in browser shows these formulas as raw TeX and never typesets them, so it cannot show a refused macro; when a page uses a macro not yet seen rendering on GitHub, ask the user to look at the page in their own browser.
