#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const childProcess = require("child_process");

const root = process.cwd();
const pluginPath = path.join(root, ".claude-plugin", "plugin.json");
const marketplacePath = path.join(root, ".claude-plugin", "marketplace.json");

const failures = [];
const warnings = [];

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    failures.push(`${path.relative(root, filePath)} is not valid JSON: ${error.message}`);
    return null;
  }
}

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walk(fullPath));
    } else {
      files.push(fullPath);
    }
  }
  return files;
}

function grepFiles(pattern, files) {
  const hits = [];
  for (const file of files) {
    if (!fs.existsSync(file)) continue;
    const text = fs.readFileSync(file, "utf8");
    const lines = text.split(/\r?\n/);
    lines.forEach((line, index) => {
      if (pattern.test(line)) {
        hits.push(`${path.relative(root, file)}:${index + 1}: ${line.trim()}`);
      }
    });
  }
  return hits;
}

function commandOutput(command) {
  return childProcess.execSync(command, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}

const plugin = readJson(pluginPath);
const marketplace = readJson(marketplacePath);

if (plugin && marketplace) {
  const versions = [
    plugin.version,
    marketplace.metadata && marketplace.metadata.version,
    marketplace.plugins && marketplace.plugins[0] && marketplace.plugins[0].version,
  ];

  if (new Set(versions).size !== 1) {
    failures.push(`Version mismatch: ${versions.join(" / ")}`);
  }

  if (!plugin.name || plugin.name !== "scriptorium-cowork") {
    failures.push(`plugin.json name must be "scriptorium-cowork"; got "${plugin.name}"`);
  }

  if (!plugin.description || plugin.description.length > 256) {
    failures.push(`plugin.json description is ${plugin.description ? plugin.description.length : 0} chars; Cowork cap is 256`);
  }

  if (!marketplace.plugins || marketplace.plugins.length !== 1) {
    failures.push("marketplace.json must contain exactly one plugin entry");
  }
}

const skillFiles = walk(path.join(root, "skills")).filter((file) => file.endsWith("SKILL.md"));
if (skillFiles.length !== 14) {
  failures.push(`Expected 14 skill files; found ${skillFiles.length}`);
}

for (const file of skillFiles) {
  const text = fs.readFileSync(file, "utf8");
  const frontmatter = text.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatter) {
    failures.push(`${path.relative(root, file)} is missing YAML frontmatter`);
    continue;
  }
  if (!/^name:\s*\S+/m.test(frontmatter[1])) {
    failures.push(`${path.relative(root, file)} frontmatter missing name`);
  }
  if (!/^description:\s*.+/m.test(frontmatter[1])) {
    failures.push(`${path.relative(root, file)} frontmatter missing description`);
  }
}

const markdownFiles = [
  "README.md",
  "CLAUDE.md",
  "CONNECTORS.md",
  ...skillFiles.map((file) => path.relative(root, file)),
].map((file) => path.join(root, file));

// Match stale skill identifiers from the rename history. Excludes `research-` because
// it collides with legitimate prose ("research-direction coach", "research-paper-shaped
// artifact") in the grill skills and README, none of which are stale.
const staleHits = grepFiles(/\b(lit-|running-a-|setting-up-)\w+/, markdownFiles)
  .filter((hit) => !hit.includes("CHANGELOG"));
if (staleHits.length > 0) {
  failures.push(`Stale renamed-skill references found:\n${staleHits.join("\n")}`);
}

const claude = fs.readFileSync(path.join(root, "CLAUDE.md"), "utf8");
if (/eleven SKILL\.md files/.test(claude)) {
  failures.push("CLAUDE.md still says eleven SKILL.md files");
}
if (/zip -r \/tmp\/scriptorium-cowork\.plugin \. -x "\*\.git\*" "\*\.DS_Store"/.test(claude)) {
  failures.push("CLAUDE.md still documents the old manual zip command");
}

const synthesize = fs.readFileSync(path.join(root, "skills", "synthesize", "SKILL.md"), "utf8");
if (/Run the contradiction check/.test(synthesize)) {
  failures.push("synthesize still instructs handoff to contradictions before final cite-check; remove and let review own that phase");
}

// v0.4.0 (R7): vocab dedupe — reference files in skills/*/references/ must not
// be byte-identical EXCEPT when explicitly allowlisted (e.g., grill-me's pointer
// to the canonical grill-question copy). Catches drift if someone edits one
// vocab file without the other.
const ALLOWED_DUPLICATE_REFS = new Set([
  // Pairs are encoded as sorted-and-joined paths; an allowlisted byte-identical
  // pair means the smaller file is intentionally a pointer.
]);
function vocabDedupeCheck() {
  const refsRoot = path.join(root, "skills");
  if (!fs.existsSync(refsRoot)) return;
  const refFiles = walk(refsRoot)
    .filter((file) => file.includes(`${path.sep}references${path.sep}`) && file.endsWith(".md"));
  const byHash = new Map();
  for (const file of refFiles) {
    const text = fs.readFileSync(file, "utf8");
    if (text.length < 100) continue; // pointer files are small by design — skip
    const hash = require("crypto").createHash("sha256").update(text).digest("hex");
    if (!byHash.has(hash)) byHash.set(hash, []);
    byHash.get(hash).push(path.relative(root, file));
  }
  for (const [, paths] of byHash) {
    if (paths.length > 1) {
      const key = [...paths].sort().join("::");
      if (!ALLOWED_DUPLICATE_REFS.has(key)) {
        failures.push(`Byte-identical reference files (drift risk): ${paths.join(", ")}`);
      }
    }
  }
}
vocabDedupeCheck();

try {
  const pluginFile = "/private/tmp/scriptorium-cowork-validator.plugin";
  if (fs.existsSync(pluginFile)) {
    fs.unlinkSync(pluginFile);
  }
  commandOutput(`zip -r ${pluginFile} . -x '*.git*' '*.DS_Store' '*.plugin' 'scripts/release.sh' 'scripts/*' '.github/*' '.claude-plugin/marketplace.json' >/dev/null`);
  const listing = commandOutput(`unzip -l ${pluginFile}`);
  const forbidden = [
    ".claude-plugin/marketplace.json",
    "scripts/release.sh",
    "scripts/validate-plugin.js",
  ].filter((name) => listing.includes(name));
  if (forbidden.length > 0) {
    failures.push(`Packaged plugin includes developer-only files: ${forbidden.join(", ")}`);
  }
  const packagedSkills = listing.split(/\r?\n/).filter((line) => /SKILL\.md$/.test(line)).length;
  if (packagedSkills !== 14) {
    failures.push(`Packaged plugin should include 14 SKILL.md files; found ${packagedSkills}`);
  }
  // v0.4.0: runtime/cite-check.py and runtime/build-viewer.py must ship.
  // Skill prose references them; if scripts/ exclusion accidentally drops them,
  // the cite-check discipline gate is hollow (was the v0.3.0 packaging bug).
  if (!listing.includes("runtime/cite-check.py")) {
    failures.push("Packaged plugin missing runtime/cite-check.py — synthesize prose references it; check zip exclusions");
  }
  if (!listing.includes("runtime/build-viewer.py")) {
    failures.push("Packaged plugin missing runtime/build-viewer.py — render prose references it; check zip exclusions");
  }
} catch (error) {
  warnings.push(`Package-shape validation skipped or failed: ${error.message}`);
}

if (warnings.length > 0) {
  console.log("Warnings:");
  for (const warning of warnings) {
    console.log(`- ${warning}`);
  }
}

if (failures.length > 0) {
  console.error("Validation failed:");
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log("Validation passed:");
console.log(`- plugin version: ${plugin.version}`);
console.log(`- plugin description length: ${plugin.description.length}`);
console.log(`- skills: ${skillFiles.length}`);
console.log("- package shape: ok");
