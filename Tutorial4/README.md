# Tutorial4 - Nextflow 26.04 features

New exercises covering what changed in **Nextflow 26.04**. They follow the same
style as Tutorial1–3: runnable/illustrative code up top, `?` placeholders for
you to fill in, and a commented-out *corrigé* (solution) at the bottom of each
file.

## What changed in 26.04

| Change | Old | New |
| --- | --- | --- |
| Strict syntax parser is the **default** | mixed top-level statements, DSL1 `from`/`into` | imperative code inside `workflow {}` |
| Abort the run | `System.exit(1)` | `error "message"` |
| Channel factory | `Channel.from(...)` | `channel.of(...)` (lowercase `channel`) |
| Closures | implicit `it` (deprecated) | named parameter `{ x -> ... }` |
| Records (preview) | positional `tuple(id, r1, r2)` | `record Sample { id: String; ... }` |
| Static typing (preview) | untyped processes/workflows | `nextflow.enable.types = true` |
| Modules | `include { X } from '../path/main'` | `include { X } from 'nf-core/x'` + `nextflow module ...` |
| Deprecated config | `manifest.defaultBranch` | auto-detected |
| Deprecated method | `path.listFiles()` | `path.listDirectory()` |

Temporary escape hatch if you must run old-style code:

```bash
export NXF_SYNTAX_PARSER=v1
```

## Exercises

| File | Topic |
| --- | --- |
| `1.strictSyntax.nf` | Migrate Groovy/DSL1 to the strict parser (`error()`, `Channel.of`, `workflow {}`) |
| `2.records.nf` | Declare and build `record` types, access fields by name |
| `3.typedProcess.nf` | Typed processes & typed workflows (`take:`/`emit:` with `Channel<Type>`) |
| `4.moduleSystem.nf` | The module registry and `nextflow module` CLI |

## Running

```bash
# Exercise 1
nextflow run Tutorial4/1.strictSyntax.nf --words "Hello 26.04"

# Exercises 2 & 3 expect a CSV: id,fastq_1,fastq_2 per line
nextflow run Tutorial4/2.records.nf     --inputCsv samples.csv
nextflow run Tutorial4/3.typedProcess.nf --inputCsv samples.csv
```

> **Note:** Records and static typing are **preview** features in 26.04 - syntax
> may change in later releases. The exercises are written to teach the syntax and
> to *lint* cleanly (`nextflow lint Tutorial4/<file>.nf`); fully executing 2–4
> needs real inputs/tools.
