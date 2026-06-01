#!/usr/bin/env nextflow

// A real-world DSL2 pipeline, migrated for Nextflow 26.04.
//
// What changed for 26.04 (strict syntax parser is now the default):
//   1. Statements and declarations can no longer be mixed at the top level.
//      All imperative code (tool checks, parameter validation, channel
//      creation) now lives inside the entry `workflow {}` block.
//   2. `System.exit(1)` is replaced by the `error()` function.
//   3. Duplicate process input names (three `path log`) are now invalid and
//      have been given distinct names.
//   4. Closures use explicit parameters instead of the implicit `it`
//      (implicit `it` is deprecated under the strict parser).
//   5. The legacy DSL1 versions (process inputs with `from` / outputs with
//      `into`) were removed - they no longer parse on 26.04.
//
// To temporarily fall back to the old parser:  export NXF_SYNTAX_PARSER=v1

// ---------------------------------------------------------------------------
// Parameters (legacy parameter declarations are still allowed at top level)
// ---------------------------------------------------------------------------
params.inputDir = null
params.logs     = null

// tools that will be used in the pipeline
params.snpSift      = "${workflow.launchDir}/tools/snpEff/SnpSift.jar"
params.bcftools     = "${workflow.launchDir}/tools/bcftools-1.16/bcftools"
params.installtools = "${workflow.launchDir}/tools/install_tools.sh"


// ---------------------------------------------------------------------------
// Processes
// ---------------------------------------------------------------------------

// process that takes a VCF and splits it by chromosome
process splitVCF {
  memory '1 GB'
  cpus 1

  input:
    tuple val(sampleName), path(vcf)

  output:
    path '*.chr*.vcf', emit: splitvcf
    path "*.log", emit: splitlog

  script:
    """
    echo "${task.process} - Process start: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log

    java -Xmx${task.memory.toGiga()}G -XX:ParallelGCThreads=${task.cpus} -jar ${params.snpSift} split ${vcf}

    echo "${task.process} - Process end: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log
    """
}

// process that annotates each chromosome VCF with VEP from Ensembl in a docker container
process annotateVCF {
  memory '1 GB'
  cpus 1

  input:
    path vcf

  output:
    tuple val(sampleName), path('*_annotated.vcf'), emit: annotatedvcf
    path "*.log", emit: annotatedlog

  script:
  sampleName = vcf.baseName.tokenize(".")[0]
    """
    echo "${task.process} - Process start: ${vcf} on \$(cat /etc/hostname) - `date` in `pwd`" > ${task.process}.log

    vep -i ${vcf} \\
    -o ${vcf.baseName.tokenize(".")[0]}_annotated.vcf \\
    --database \\
    --fork ${task.cpus} \\
    --assembly GRCh38 \\
    --vcf

    echo "${task.process} - Process end: ${vcf} on `hostname` - `date` in `pwd`" > ${task.process}.log
    """
}

// process that merges all annotated VCFs for a sample
process mergeVCF {
  memory '1 GB'
  cpus 1
  publishDir "${params.inputDir}/merged", mode: 'copy'
  publishDir "mergedVCF/", mode: 'copy', pattern: "*.vcf"

  input:
    tuple val(sampleName), val(vcf)

  output:
    path '*.merged.vcf', emit: mergedvcf
    path "*.log", emit: mergedlog

  script:
    """
    echo "${task.process} - Process start: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log

    ${params.bcftools} concat ${vcf.join(" ")} -q 0 -Ov --threads ${task.cpus} -o ${sampleName}.merged.vcf

    echo "${task.process} - Process end: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log
    """
}

// process that collects all logs from previous processes and merges them into a single file
process collectLogs {
  publishDir "logs/", mode: 'copy', pattern: "logs.log"

  // NOTE (26.04): each input must have a unique name. The three logs are
  // staged under fixed names by the collectFile() calls in the workflow,
  // so the variable names here are only used to declare the inputs.
  input:
    path splitlog
    path annotatelog
    path mergelog

  output:
    path 'logs.log'

  script:
    """
    cat splitVCF.log \\
      <(echo --------------) \\
      annotateVCF.log \\
      <(echo --------------) \\
      mergeVCF.log \\
    > logs.log
    """
}


// ---------------------------------------------------------------------------
// Named workflows
// ---------------------------------------------------------------------------

// include { splitVCF } from './modules/splitvcf.module'
// include { annotateVCF } from './modules/annotatevcf.module'
// include { mergeVCF } from './modules/mergevcf.module'
// include { collectLogs } from './modules/collectlogs.module'

// create a named pipeline
workflow awesome_pipeline {
    take:
      vcfFiles
    main:
      splitVCF( vcfFiles )
      annotateVCF( splitVCF.out.splitvcf.flatten() )
      mergeVCF( annotateVCF.out.annotatedvcf.groupTuple().map{ row -> tuple(row[0], row[1]) } )
      collectLogs(
                   splitVCF.out.splitlog.collectFile(name: 'splitVCF.log'),
                   annotateVCF.out.annotatedlog.collectFile(name: 'annotateVCF.log'),
                   mergeVCF.out.mergedlog.collectFile(name: 'mergeVCF.log')
                 )
}

// create another named pipeline
workflow removelogs {
    take:
      vcfFiles
    main:
      splitVCF( vcfFiles )
      annotateVCF( splitVCF.out.splitvcf.flatten() )
      mergeVCF( annotateVCF.out.annotatedvcf.groupTuple().map{ row -> tuple(row[0], row[1]) } )
}


// ---------------------------------------------------------------------------
// Entry workflow - all imperative setup code lives here under strict syntax
// ---------------------------------------------------------------------------
workflow {
  main:
  // check if snpSift is available, install if missing
  if (!file(params.snpSift).exists()) {
      println "SnpSift not found: ${params.snpSift}"
      println "Installing SnpSift..."
      def sout = new StringBuilder()
      def serr = new StringBuilder()
      def proc = "bash ${params.installtools} ${workflow.launchDir}/tools".execute()
      proc.consumeProcessOutput(sout, serr)
      proc.waitFor()
  } else {
      println "SnpSift found: ${params.snpSift}"
  }

  // check if bcftools is available, install if missing
  if (!file(params.bcftools).exists()) {
      println "bcftools not found: ${params.bcftools}"
      println "Installing bcftools..."
      def sout = new StringBuilder()
      def serr = new StringBuilder()
      def proc = "bash ${params.installtools} ${workflow.launchDir}/tools".execute()
      proc.consumeProcessOutput(sout, serr)
      proc.waitFor()
  } else {
      println "bcftools found: ${params.bcftools}"
  }

  // validate input directory (error() replaces System.exit(1))
  if (!params.inputDir)
    error "Please specify --inputDir"

  if (!file(params.inputDir).isDirectory())
    error "Input directory ${params.inputDir} is not a directory"

  // create a channel from the input dir only containing vcf files
  vcfFiles = channel.fromPath("${params.inputDir}/*.vcf")
                    .map { vcf -> tuple(vcf.baseName.tokenize(".")[0], vcf) }

  // // check what's inside the channel
  // vcfFiles.view()

  if (params.logs) {
    awesome_pipeline(vcfFiles)
  } else {
    removelogs(vcfFiles)
  }

  // When workflow is finished, print some metadata.
  // can also send an email here using sendmail
  // see https://www.nextflow.io/docs/latest/metadata.html
  // NOTE (26.04): the strict parser does not allow a standalone
  // `workflow.onComplete { ... }` statement at the top level; the handler is
  // now an `onComplete:` section inside the entry workflow.
  onComplete:
  def status = "NA"
  if(workflow.success) {

    status = "SUCCESS"

    println("""
    Pipeline execution summary
    --------------------------

    Successful completion : ${workflow.success}
    Launch time           : ${workflow.start.format('dd-MMM-yyyy HH:mm:ss')}
    Ending time           : ${workflow.complete.format('dd-MMM-yyyy HH:mm:ss')} (duration: ${workflow.duration})
    Launch directory      : ${workflow.launchDir}
    Work directory        : ${workflow.workDir.toUriString()}
    Nextflow directory    : ${workflow.projectDir}
    Input directory       : ${params.inputDir}

    PIPELINE INFORMATION:
    ---------------------
    Pipeline version      : ${workflow.manifest.version}
    Pipeline path         : ${workflow.scriptFile}
    Pipeline homepage     : ${workflow.manifest.homePage}
    Pipeline description  : ${workflow.manifest.description}
    Author                : ${workflow.manifest.author}
    Configuration path    : ${workflow.configFiles.unique().join(" ")}

    WORKFLOW INFORMATION:
    ---------------------
    Workflow session      : ${workflow.sessionId}
    Nextflow run name     : ${workflow.runName}
    Nextflow version      : ${workflow.nextflow.version}, build ${workflow.nextflow.build} (${workflow.nextflow.timestamp})

    PLATFORM INFORMATION:
    ---------------------
    Workflow profile      : ${workflow.profile ?: '-'}
    Workflow container    : ${workflow.container ?: '-'}
    Container engine      : ${workflow.containerEngine?:'-'}

    The command used to launch the workflow was as follows:
    ${workflow.commandLine}
    """
    )
  }
}

