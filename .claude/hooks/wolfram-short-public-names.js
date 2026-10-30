// PostToolUse hook: after Claude edits a Wolfram test file or a doc page, flag
// public symbols written with the OEIS` prefix (OEIS`A399539[...]). The tests
// load the package first and the docs start with Get, so OEIS` is already on
// $ContextPath and the short name is enough. OEIS`Private`helper keeps its
// prefix, and names inside strings (Names["OEIS`*"], NameQ["OEIS`n"]) and
// Wolfram comments are context names, not calls, so they are skipped.
const fs = require("fs");
const path = require("path");

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  let filePath;
  try {
    filePath = JSON.parse(input).tool_input?.file_path;
  } catch {
    process.exit(0);
  }
  if (!filePath) process.exit(0);

  const rel = path
    .relative(projectDir, path.resolve(projectDir, filePath))
    .split(path.sep)
    .join("/");
  if (!/^test\/wolfram\/[^/]+\.wlt$|^docs\/[^/]+\.md$|^(test\/[^/]+\/)?README\.md$/.test(rel)) process.exit(0);

  let text;
  try {
    text = fs.readFileSync(path.resolve(projectDir, filePath), "utf8");
  } catch {
    process.exit(0);
  }

  const found = [];
  text.split(/\r?\n/).forEach((line, i) => {
    const code = line.replace(/"(?:[^"\\]|\\.)*"/g, '""').replace(/\(\*.*?\*\)/g, "");
    for (const m of code.matchAll(/OEIS`(?!Private`)[A-Za-z$][A-Za-z0-9$]*/g)) {
      found.push(`  line ${i + 1}: ${m[0]}`);
    }
  });
  if (found.length === 0) process.exit(0);

  console.error(
    `${rel} names public symbols with the OEIS\` prefix:\n${found.join("\n")}\n` +
      "Write the short name (A399539[...], not OEIS`A399539[...]): the package is loaded first, so OEIS` is on " +
      "$ContextPath. Keep OEIS`Private`helper for private helpers, and context names inside strings as they are."
  );
  process.exit(2);
});
