#!/usr/bin/env nextflow

// ===========================================================================
// Tutorial4 - Exercise 3: Typed processes & typed workflows (26.04, preview)
// ===========================================================================
//
// With `nextflow.enable.types = true` you can annotate process inputs/outputs
// and workflow take/emit with types. Benefits: errors are caught before the
// run instead of deep inside a task, and records make data self-documenting.
//
nextflow.enable.types = true
//
// Run:  nextflow run Tutorial4/3.typedProcess.nf --inputCsv samples.csv


record Sample {
    id: String
    fastq_1: Path
    fastq_2: Path
}

// A record describing the result of FASTQC for a sample.
record FastqcResult {
    id: String
    logs: Path
}

// Typed `params` block (required when nextflow.enable.types is on).
params {
    inputCsv: Path?
}


// ---------------------------------------------------------------------------
// A TYPED process.
//   - input is a `record(...)` (destructured: id, fastq_1, fastq_2 become
//     available as variables inside the process).
//   - output is a typed value built with record(...).
//
// EXERCISE: fill in the input field types and the output (replace every ?)
// ---------------------------------------------------------------------------
process FASTQC {
  tag id

  input:
    record(
        id: ?,           // hint: String
        fastq_1: Path,
        fastq_2: ?       // hint: Path
    )

  output:
    record(
        id: id,
        logs: file("fastqc_${id}_logs")
    )

  script:
    """
    mkdir -p fastqc_${id}_logs
    echo "would run: fastqc ${fastq_1} ${fastq_2}" > fastqc_${id}_logs/cmd.txt
    """
}


// ---------------------------------------------------------------------------
// A TYPED workflow: take/emit carry types too. A channel of records is
// written `Channel<Sample>`.
//
// EXERCISE: annotate the take/emit types (replace every ?)
// ---------------------------------------------------------------------------
workflow QC {
  take:
    read_pairs: Channel<?>          // hint: Sample

  main:
    results = FASTQC(read_pairs)

  emit:
    fastqc: Channel<FastqcResult> = results
}


workflow {
  if (!params.inputCsv)
    error "Please specify --inputCsv"

  samples = channel.fromPath(params.inputCsv)
    .splitCsv()
    .map { row -> record(id: row[0], fastq_1: file(row[1]), fastq_2: file(row[2])) }

  QC(samples)
  QC.out.fastqc.view { r -> "FASTQC done for ${r.id} -> ${r.logs}" }
}


// ---------------------------------------------------------------------------
// // corrigé (solution)
// ---------------------------------------------------------------------------
// process FASTQC {
//   tag id
//
//   input:
//     record(
//         id: String,
//         fastq_1: Path,
//         fastq_2: Path
//     )
//
//   output:
//     record(
//         id: id,
//         logs: file("fastqc_${id}_logs")
//     )
//
//   script:
//     """
//     mkdir -p fastqc_${id}_logs
//     echo "would run: fastqc ${fastq_1} ${fastq_2}" > fastqc_${id}_logs/cmd.txt
//     """
// }
//
// workflow QC {
//   take:
//     read_pairs: Channel<Sample>
//
//   main:
//     results = FASTQC(read_pairs)
//
//   emit:
//     fastqc: Channel<FastqcResult> = results
// }
