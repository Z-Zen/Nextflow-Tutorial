#!/usr/bin/env nextflow

// ===========================================================================
// Tutorial4 - Exercise 4: The module system / module registry (26.04)
// ===========================================================================
//
// 26.04 introduces a native module system. Instead of vendoring modules and
// including them by fragile relative paths, you reference them by their
// canonical registry name and let Nextflow resolve/install them.
//
//   OLD (relative path):
//     include { BWA_MEM } from '../../../modules/nf-core/bwa/mem/main'
//
//   NEW (registry name):
//     include { BWA_MEM } from 'nf-core/bwa/mem'
//
// There are also new CLI commands:
//     nextflow module list                 # discover available modules
//     nextflow module install nf-core/fastqc
//     nextflow module run nf-core/fastqc   # run a module directly
//
// ---------------------------------------------------------------------------
// This file is mostly illustrative: the include below is commented out so the
// script still parses without the module being installed. Uncomment it once
// you have run `nextflow module install nf-core/fastqc`.
// ---------------------------------------------------------------------------

// include { FASTQC } from 'nf-core/fastqc'

params.reads = null


// ---------------------------------------------------------------------------
// EXERCISE: rewrite this OLD-style include as a NEW registry-name include.
//
//   Given:  include { SEQTK_TRIM } from '../modules/nf-core/seqtk/trim/main'
//   Write the 26.04 equivalent on the line below (replace ?).
// ---------------------------------------------------------------------------

// include { SEQTK_TRIM } from ?


workflow {
  if (!params.reads)
    error "Please specify --reads (this exercise is illustrative)"

  reads = channel.fromPath(params.reads)

  // Once the module is installed and the include above is uncommented:
  // FASTQC(reads)
  reads.view { f -> "would feed ${f} to a registry module" }
}


// ---------------------------------------------------------------------------
// // corrigé (solution)
// ---------------------------------------------------------------------------
// include { SEQTK_TRIM } from 'nf-core/seqtk/trim'
