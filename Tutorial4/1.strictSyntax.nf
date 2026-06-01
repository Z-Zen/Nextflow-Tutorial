#!/usr/bin/env nextflow

// ===========================================================================
// Tutorial4 - Exercise 1: Migrating to the strict syntax parser (26.04)
// ===========================================================================
//
// Since 26.04 the strict syntax parser is the default. The four most common
// things that used to work and now FAIL to parse:
//
//   1. Top-level statements mixed with declarations (process / workflow).
//      -> All imperative code must live inside a workflow block.
//   2. `System.exit(1)` to abort.            -> use the `error()` function.
//   3. `Channel.from(...)`                    -> use `channel.of(...)`
//      (also note: lowercase `channel` is now preferred over `Channel`).
//   4. Implicit `it` in closures (deprecated) -> name the closure parameter.
//
// Below is the OLD, pre-26.04 style. It is commented out because it no longer
// parses. Your job: complete the strict-syntax version, replacing every `?`.
//
// Run:  nextflow run Tutorial4/1.strictSyntax.nf --words "Hello 26.04"


// ---------------------------------------------------------------------------
// OLD pre-26.04 style (does NOT parse on 26.04 - kept for reference only)
// ---------------------------------------------------------------------------
// params.words = "Hello World"
//
// // top-level statement mixed with a process declaration -> ILLEGAL now
// myChannel = Channel.from(params.words)
//
// if (!params.words) {
//   System.exit(1)                         // ILLEGAL now
// }
//
// process echoWords {
//   debug true
//   input:
//     val w from myChannel                 // DSL1 `from` -> removed
//   output:
//     stdout into result                   // DSL1 `into` -> removed
//   script:
//     """
//     echo $w
//     """
// }


// ---------------------------------------------------------------------------
// EXERCISE: complete the strict-syntax version (replace every ?)
// ---------------------------------------------------------------------------
params.words = "Hello World"

process echoWords {
  debug true

  input:
    val w

  output:
    stdout

  script:
    """
    echo $w
    """
}

workflow {
  // 1. abort with a helpful message if no words were given (use error(), not System.exit)
  if (!params.words)
    ?

  // 2. build a channel from the parameter using the NON-deprecated factory
  myChannel = channel.?(params.words)

  // 3. call the process
  echoWords(?)
}


// ---------------------------------------------------------------------------
// // corrigé (solution)
// ---------------------------------------------------------------------------
// params.words = "Hello World"
//
// process echoWords {
//   debug true
//
//   input:
//     val w
//
//   output:
//     stdout
//
//   script:
//     """
//     echo $w
//     """
// }
//
// workflow {
//   if (!params.words)
//     error "Please specify --words"
//
//   myChannel = channel.of(params.words)
//
//   echoWords(myChannel)
// }
