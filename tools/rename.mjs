#!/usr/bin/env node
// Renames the objects of this repository before they are imported into an SAP system, for example when
// the project code BE collides with existing objects there.
//
//   node tools/rename.mjs --code XY [--letter Y] [--from BE] [--from-letter Z] [--dry-run]
//   node tools/rename.mjs --map renames.json [--dry-run]
//
// --code replaces the project code in all names: ZCL_BE_ → ZCL_XY_, ZCX_BE_ → ZCX_XY_, ZIF_BE_ → ZIF_XY_,
// $ZBE_ → $ZXY_ and ZBE_ → ZXY_. --letter changes the customer namespace letter (Z or Y) at the same time.
// --from and --from-letter name the current code and letter, for a repository that was renamed before.
// --map renames single objects; the file maps old names to new names, e.g. {"ZCL_BE_JSON": "ZCL_BE_JSON_UTIL"}.
//
// The script rewrites file names and contents in src/ (abapGit files), the ARC-1 extension and the
// documentation, computes the file name of the ICF node again and checks the SAP name length limits.

import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync, renameSync, statSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, relative } from 'node:path';

const root = join(dirname(new URL(import.meta.url).pathname), '..');
const sourceFolders = ['src', 'arc1-extension/src', 'arc1-extension/tests', 'docs'];
const sourceFiles = ['README.md'];
const textExtensions = /\.(abap|xml|ts|mjs|js|json|md)$/;

// Name length limits of SAP objects; transparent tables are checked separately (16 characters)
const lengthLimits = { clas: 30, intf: 30, msag: 20, tabl: 30, ttyp: 30, dtel: 30, doma: 30, devc: 30 };
const icfNameLimit = 15;
const databaseTableLimit = 16;

function parseArguments(argv) {
  const options = { dryRun: false, letter: 'Z', from: 'BE', 'from-letter': 'Z' };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--dry-run') {
      options.dryRun = true;
    } else if (['--code', '--letter', '--from', '--from-letter', '--map'].includes(argument)) {
      options[argument.slice(2)] = argv[index + 1];
      index += 1;
    } else {
      throw new Error(`Unknown argument ${argument}`);
    }
  }
  if (!options.code && !options.map) {
    throw new Error('Pass --code <new project code> or --map <file with old and new names>');
  }
  for (const code of [options.code, options.from].filter(Boolean)) {
    if (!/^[A-Z][A-Z0-9]{0,12}$/i.test(code)) {
      throw new Error('A project code consists of letters and digits and starts with a letter');
    }
  }
  for (const letter of [options.letter, options['from-letter']]) {
    if (!/^[ZY]$/i.test(letter)) {
      throw new Error('The namespace letter is Z or Y');
    }
  }
  return options;
}

// Characters that belong to an ABAP name; a slash does not, so URL paths like /sap/bc/zbe_… match too
const nameCharacter = '[A-Za-z0-9_$]';

function keepCase(original, replacement) {
  return original === original.toLowerCase() ? replacement.toLowerCase() : replacement.toUpperCase();
}

function buildRules(options) {
  const rules = [];
  if (options.map) {
    const renames = JSON.parse(readFileSync(options.map, 'utf8'));
    for (const [oldName, newName] of Object.entries(renames)) {
      rules.push({
        pattern: new RegExp(`(?<!${nameCharacter})${escape(oldName)}(?!${nameCharacter})`, 'gi'),
        replacement: newName,
      });
    }
  }
  if (options.code) {
    const letter = options.letter.toUpperCase();
    const code = options.code.toUpperCase();
    const fromLetter = options['from-letter'].toUpperCase();
    const from = options.from.toUpperCase();
    const prefixes = [
      [`$${fromLetter}${from}_`, `$${letter}${code}_`],
      [`${fromLetter}CL_${from}_`, `${letter}CL_${code}_`],
      [`${fromLetter}CX_${from}_`, `${letter}CX_${code}_`],
      [`${fromLetter}IF_${from}_`, `${letter}IF_${code}_`],
      [`${fromLetter}${from}_`, `${letter}${code}_`],
    ];
    for (const [oldPrefix, newPrefix] of prefixes) {
      // The dollar sign of local packages is part of the name, so $ZBE_ is not renamed twice
      const lookbehind = oldPrefix.startsWith('$') ? `(?<!${nameCharacter})` : `(?<!${nameCharacter})(?<!\\$)`;
      rules.push({ pattern: new RegExp(`${lookbehind}${escape(oldPrefix)}`, 'gi'), replacement: newPrefix });
    }
  }
  return rules;
}

function escape(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function rename(text, rules) {
  let result = text;
  for (const rule of rules) {
    result = result.replace(rule.pattern, (match) => keepCase(match, rule.replacement));
  }
  return result;
}

function listFiles(folder) {
  if (!existsSync(folder)) {
    return [];
  }
  return readdirSync(folder).flatMap((entry) => {
    const path = join(folder, entry);
    return statSync(path).isDirectory() ? listFiles(path) : [path];
  });
}

// abapGit names the file of an ICF node after the node and a hash of its URL
function icfFileName(xml) {
  const url = /<URL>([^<]*)<\/URL>/.exec(xml)?.[1];
  const name = /<ICF_NAME>([^<]*)<\/ICF_NAME>/.exec(xml)?.[1];
  if (!url || !name) {
    throw new Error('ICF node without URL or ICF_NAME');
  }
  const hash = createHash('sha1').update(url).digest('hex').slice(0, 25);
  return `${name.toLowerCase().padEnd(icfNameLimit, ' ')}${hash}.sicf.xml`;
}

function checkLengths(files) {
  const problems = [];
  for (const file of files) {
    const match = /^(.+?)\.(clas|intf|msag|tabl|ttyp|dtel|doma|devc)\.xml$/.exec(basename(file.target));
    if (match) {
      const name = match[1].replace(/#/g, '/');
      const isDatabaseTable = match[2] === 'tabl' && /<TABCLASS>TRANSP<\/TABCLASS>/.test(file.content);
      const limit = isDatabaseTable ? databaseTableLimit : lengthLimits[match[2]];
      if (name.length > limit) {
        problems.push(`${match[2].toUpperCase()} ${name.toUpperCase()} has ${name.length} characters, at most ${limit} are allowed`);
      }
    }
    if (file.target.endsWith('.sicf.xml')) {
      const name = /<ICF_NAME>([^<]*)<\/ICF_NAME>/.exec(file.content)?.[1] ?? '';
      if (name.length > icfNameLimit) {
        problems.push(`ICF node ${name} has ${name.length} characters, at most ${icfNameLimit} are allowed`);
      }
    }
  }
  return problems;
}

function main() {
  const options = parseArguments(process.argv.slice(2));
  const rules = buildRules(options);
  const candidates = [
    ...sourceFolders.flatMap((folder) => listFiles(join(root, folder))),
    ...sourceFiles.map((file) => join(root, file)).filter((file) => existsSync(file)),
  ].filter((file) => textExtensions.test(file));

  const files = candidates.map((source) => {
    const original = readFileSync(source, 'utf8');
    const content = rename(original, rules);
    const isAbapGitFile = relative(root, source).startsWith('src');
    let target = source;
    if (isAbapGitFile) {
      target = join(dirname(source), source.endsWith('.sicf.xml') ? icfFileName(content) : rename(basename(source), rules));
    }
    return { source, target, original, content };
  });

  const targets = new Set(files.map((file) => file.target));
  if (targets.size !== files.length) {
    throw new Error('Two files would get the same name');
  }
  for (const file of files) {
    if (file.target !== file.source && existsSync(file.target) && !files.some((other) => other.source === file.target)) {
      throw new Error(`${relative(root, file.target)} already exists`);
    }
  }
  const problems = checkLengths(files);
  if (problems.length > 0) {
    throw new Error(`Names too long after renaming:\n  ${problems.join('\n  ')}`);
  }

  const changed = files.filter((file) => file.content !== file.original || file.target !== file.source);
  for (const file of changed) {
    const from = relative(root, file.source);
    const to = relative(root, file.target);
    console.log(from === to ? `changed  ${from}` : `renamed  ${from} -> ${to}`);
  }
  console.log(`${changed.length} file(s) ${options.dryRun ? 'would change (dry run)' : 'changed'}`);
  if (options.dryRun) {
    return;
  }
  // Two phases, so that a chain like A -> B and B -> C does not overwrite B
  const moved = changed.filter((file) => file.target !== file.source);
  for (const file of changed) {
    writeFileSync(file.source, file.content);
  }
  for (const file of moved) {
    renameSync(file.source, `${file.source}.renaming`);
  }
  for (const file of moved) {
    renameSync(`${file.source}.renaming`, file.target);
  }
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
