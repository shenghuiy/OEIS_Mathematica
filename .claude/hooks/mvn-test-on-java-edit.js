// PostToolUse hook: run `mvn test` after Claude edits a file under src/java/.
// On test failure, exit 2 so the tail of Maven's output is fed back to Claude.
const { spawnSync } = require("child_process");
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
  if (!/^src\/java\/.*\.java$/.test(rel)) process.exit(0);

  // `mvn3` is the name MacPorts gives Maven on the Mac; apps launched from
  // the Dock may not have /opt/local/bin on PATH, so try the full path too.
  for (const mvn of ["mvn", "mvn3", "/opt/local/bin/mvn3"]) {
    const result = spawnSync(mvn, ["-q", "test"], {
      cwd: projectDir,
      shell: true,
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
    });

    if (result.error) {
      console.error(`mvn test hook: could not run ${mvn} (${result.error.message})`);
      process.exit(1);
    }
    if (result.status === 0) process.exit(0);

    const output = `${result.stdout}\n${result.stderr}`.trim();
    // Command missing: sh exits 127; cmd.exe exits 1 with one of these messages.
    if (
      result.status === 127 ||
      /^'?\S+'? is not recognized as an internal or external command|^The system cannot find the path specified\.$/m.test(output)
    ) {
      continue;
    }
    const tail = output.split(/\r?\n/).slice(-80).join("\n");
    console.error(`${mvn} test failed after editing ${rel}:\n${tail}`);
    process.exit(2);
  }

  console.error("mvn test hook: neither mvn nor mvn3 is on PATH; skipping tests.");
  process.exit(1);
});
