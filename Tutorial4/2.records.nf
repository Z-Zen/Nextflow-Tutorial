#!/usr/bin/env nextflow

// ===========================================================================
// Tutorial4 - Exercise 2: Records (26.04, preview feature)
// ===========================================================================
//
// Records replace positional tuples with NAMED fields. Instead of carrying a
// `tuple(id, fastq_1, fastq_2)` around and remembering that index 0 is the id,
// you declare a record type once and access fields by name (sample.id).
//
// Records require the static-typing feature flag, enabled per-script:
nextflow.enable.types = true
//
// NOTE: typed processes/workflows cannot be mixed with legacy ones in the same
// script once this flag is on.
//
// Run:  nextflow run Tutorial4/2.records.nf --inputCsv samples.csv
//
// samples.csv looks like:
//   sampleA,/data/A_1.fastq,/data/A_2.fastq
//   sampleB,/data/B_1.fastq,/data/B_2.fastq


// ---------------------------------------------------------------------------
// A record type: a name + typed fields. Available types include String,
// Integer, Boolean, Path, List<T>, Map<K,V>, ...
// ---------------------------------------------------------------------------
record Sample {
    id: String
    fastq_1: Path
    fastq_2: Path
}

// With `nextflow.enable.types = true` you must use a typed `params` block;
// the legacy `params.inputCsv = null` form is no longer allowed. `Path?` means
// a nullable Path (no default).
params {
    inputCsv: Path?
}


// ---------------------------------------------------------------------------
// EXERCISE: build a channel of Sample records from the CSV (replace every ?)
// ---------------------------------------------------------------------------
workflow {
  if (!params.inputCsv)
    error "Please specify --inputCsv"

  samples = channel.fromPath(params.inputCsv)
    .splitCsv()
    .map { row ->
        // construct a record with the record(...) function, naming each field
        record(
            id: row[0],
            fastq_1: file(?),     // hint: row[1]
            fastq_2: file(?)      // hint: row[2]
        )
    }

  // access fields BY NAME (no more it[0] / it[1])
  samples.view { sample -> "id=${sample.?}  r1=${sample.fastq_1}  r2=${sample.fastq_2}" }
}


// ---------------------------------------------------------------------------
// // corrigé (solution)
// ---------------------------------------------------------------------------
// workflow {
//   if (!params.inputCsv)
//     error "Please specify --inputCsv"
//
//   samples = channel.fromPath(params.inputCsv)
//     .splitCsv()
//     .map { row ->
//         record(
//             id: row[0],
//             fastq_1: file(row[1]),
//             fastq_2: file(row[2])
//         )
//     }
//
//   samples.view { sample -> "id=${sample.id}  r1=${sample.fastq_1}  r2=${sample.fastq_2}" }
// }
