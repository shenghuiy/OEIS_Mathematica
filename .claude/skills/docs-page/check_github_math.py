"""Find (and fix) math in Markdown files that GitHub renders wrong.

Usage: python check_github_math.py [--fix] [FILE.md ...]   (default: README.md and docs/*.md)

Flags, inside $...$ and $$...$$ outside code spans and fenced blocks:
  - a macro GitHub's math renderer rejects (\\operatorname);
  - a backslash before ASCII punctuation, such as \\{ \\} \\, \\!
    Markdown treats it as an escape and drops the backslash before the math is typeset,
    so \\{1, 2\\} shows as 1, 2 and p\\!\\left( shows as p!(.
--fix rewrites the escapes that have a named equivalent (see NAMED) in place.
Exits 1 if anything is left unfixed.
"""

import pathlib
import re
import sys

REJECTED = {"operatorname": r"\mathrm{...}"}
NAMED = {
    r"\{": r"\lbrace ",
    r"\}": r"\rbrace ",
    r"\,": r"\thinspace ",
    r"\!": r"\negthinspace ",
}
FENCE = re.compile(r"^\s*(```|~~~)")
CODE_SPAN = re.compile(r"(`+).*?\1")
MATH = re.compile(r"\$\$(.+?)\$\$|\$(.+?)\$")
ESCAPE = re.compile(r"\\[!-/:-@\[-`{-~]")


def fix_math(tex):
    out = ESCAPE.sub(lambda e: NAMED.get(e.group(0), e.group(0)), tex)
    return re.sub(r" +([}$])", r"\1", re.sub(r"(\\[a-z]+) +", r"\1 ", out))


def scan(text, fix):
    """Yield (lineno, math, problem) and, with fix, return the fixed text via StopIteration."""
    in_fence = False
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        masked = CODE_SPAN.sub(lambda m: "\0" * len(m.group(0)), line)
        pieces, last = [], 0
        for m in MATH.finditer(masked):
            math = line[m.start():m.end()]
            new = fix_math(math) if fix else math
            pieces += [line[last:m.start()], new]
            last = m.end()
            for name, use in REJECTED.items():
                if "\\" + name in new:
                    yield i + 1, math, f"\\{name} is not allowed, use {use}"
            for e in ESCAPE.finditer(new):
                yield i + 1, math, e.group(0) + " loses its backslash"
        lines[i] = "".join(pieces) + line[last:]
    return "\n".join(lines)


def main(args):
    fix = "--fix" in args
    args = [a for a in args if a != "--fix"]
    root = pathlib.Path.cwd()
    files = [pathlib.Path(a) for a in args] or [root / "README.md", *sorted((root / "docs").glob("*.md"))]
    found = 0
    for f in files:
        text = f.read_bytes().decode("utf-8")
        gen = scan(text, fix)
        while True:
            try:
                lineno, math, why = next(gen)
            except StopIteration as done:
                if fix and done.value != text:
                    f.write_bytes(done.value.encode("utf-8"))
                    print(f"{f}: fixed")
                break
            print(f"{f}:{lineno}: {why}: {math}")
            found += 1
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
