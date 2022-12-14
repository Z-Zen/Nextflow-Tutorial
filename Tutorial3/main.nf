#!/usr/bin/env nextflow

// get current launch directory
currentDir = workflow.launchDir

// input directory containing VCFs files
params.inputDir = null

params.logs = null

// tools that will be used in the pipeline
params.snpSift = currentDir + '/tools/snpEff/SnpSift.jar'
params.bcftools = currentDir + '/tools/bcftools-1.16/bcftools'

// tools installation script
params.installtools = currentDir + '/tools/install_tools.sh'

// check if snpSift is available
if (!file(params.snpSift).exists()) {
    println "SnpSift not found: ${params.snpSift}"
    println "Installing SnpSift..."
    def sout = new StringBuilder(), serr = new StringBuilder()
    def proc = "bash ${params.installtools} ${currentDir}/tools".execute()
    proc.consumeProcessOutput(sout, serr)
    proc.waitFor()
} else {
    println "SnpSift found: ${params.snpSift}"
}

// check if bcftools is available
if (!file(params.bcftools).exists()) {
    println "bcftools not found: ${params.bcftools}"
    println "Installing bcftools..."
    def sout = new StringBuilder(), serr = new StringBuilder()
    def proc = "bash ${params.installtools} ${currentDir}/tools".execute()
    proc.consumeProcessOutput(sout, serr)
    proc.waitFor()
} else {
    println "bcftools found: ${params.bcftools}"
}

// check if input directory is provided
if (!params.inputDir) {
  println "Please specify --inputDir"
  System.exit(1)
}

// check if inputDir is a directory
if (!file(params.inputDir).isDirectory()) {
  println "Input directory ${params.inputDir} is not a directory"
  System.exit(1)
}

// create a channel from the input dir only containing vcf files
Channel.fromPath("${params.inputDir}/*.vcf").map { tuple(it.baseName.tokenize(".")[0], it) }.set {vcfFiles}

// // check what's inside the channel
// vcfFiles.view()

// DSL1
// process that takes a VCF and splits it by chromosome
process splitVCF {
  memory '1 GB'
  cpus 1

  input:
    tuple val(sampleName), path(vcf) from vcfFiles

  output:
    file '*.chr*.vcf' into split_ch
    file "*.log" into split_log_ch

  script:
    """
    echo "${task.process} - Process start: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log

    java -Xmx${task.memory.toGiga()}G -XX:ParallelGCThreads=${task.cpus} -jar ${params.snpSift} split ${vcf}

    echo "${task.process} - Process end: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log
    """
}

// each channel from previous process contains [x.chr1.vcf, x.chr2.vcf, x.chr3.vcf, ...]
// and we have to treat each chromosome separately using the function flatten below
split_ch.flatten().set {splitVCFFiles}

// process that annotates each chromosome VCF with VEP from Ensembl in a docker container
process annotateVCF {
  memory '1 GB'
  cpus 1

  input:
    file vcf from splitVCFFiles

  output:
    tuple val(sampleName), path('*_annotated.vcf') into annotated_ch
    file "*.log" into annotate_log_ch

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
  publishDir "mergedVCF/", mode: 'copy', pattern: "*.vcf"

  input:
    tuple val(sampleName), val(vcf) from annotated_ch.groupTuple().map{tuple(it[0], it[1])}

  output:
    file '*.merged.vcf' into merged_ch
    file "*.log" into merge_log_ch

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

  input:
    file log from split_log_ch.collectFile(name: 'splitVCF.log')
    file log from annotate_log_ch.collectFile(name: 'annotateVCF.log')
    file log from merge_log_ch.collectFile(name: 'mergeVCF.log')

  output:
    file 'logs.log'

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


// // DSL2
// // process that takes a VCF and splits it by chromosome
// process splitVCF {
//   memory '1 GB'
//   cpus 1

//   input:
//     tuple val(sampleName), path(vcf)

//   output:
//     path '*.chr*.vcf', emit: splitvcf
//     path "*.log", emit: splitlog

//   script:
//     """
//     echo "${task.process} - Process start: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log

//     java -Xmx${task.memory.toGiga()}G -XX:ParallelGCThreads=${task.cpus} -jar ${params.snpSift} split ${vcf}

//     echo "${task.process} - Process end: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log
//     """
// }

// // process that annotates each chromosome VCF with VEP from Ensembl in a docker container
// process annotateVCF {
//   memory '1 GB'
//   cpus 1

//   input:
//     path vcf

//   output:
//     tuple val(sampleName), path('*_annotated.vcf'), emit: annotatedvcf
//     path "*.log", emit: annotatedlog

//   script:
//   sampleName = vcf.baseName.tokenize(".")[0]
//     """
//     echo "${task.process} - Process start: ${vcf} on \$(cat /etc/hostname) - `date` in `pwd`" > ${task.process}.log

//     vep -i ${vcf} \\
//     -o ${vcf.baseName.tokenize(".")[0]}_annotated.vcf \\
//     --database \\
//     --fork ${task.cpus} \\
//     --assembly GRCh38 \\
//     --vcf

//     echo "${task.process} - Process end: ${vcf} on `hostname` - `date` in `pwd`" > ${task.process}.log
//     """
// }

// // process that merges all annotated VCFs for a sample
// process mergeVCF {
//   memory '1 GB'
//   cpus 1
//   publishDir "${params.inputDir}/merged", mode: 'copy'
//   publishDir "mergedVCF/", mode: 'copy', pattern: "*.vcf"

//   input:
//     tuple val(sampleName), val(vcf)

//   output:
//     path '*.merged.vcf', emit: mergedvcf
//     path "*.log", emit: mergedlog

//   script:
//     """
//     echo "${task.process} - Process start: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log

//     ${params.bcftools} concat ${vcf.join(" ")} -q 0 -Ov --threads ${task.cpus} -o ${sampleName}.merged.vcf

//     echo "${task.process} - Process end: ${sampleName} on `hostname` - `date` in `pwd`" > ${task.process}.log
//     """
// }

// // process that collects all logs from previous processes and merges them into a single file
// process collectLogs {
//   publishDir "logs/", mode: 'copy', pattern: "logs.log"

//   input:
//     path log
//     path log
//     path log

//   output:
//     path 'logs.log'

//   script:
//     """
//     cat splitVCF.log \\
//       <(echo --------------) \\
//       annotateVCF.log \\
//       <(echo --------------) \\
//       mergeVCF.log \\
//     > logs.log
//     """
// }


// include { splitVCF } from './modules/splitvcf.module'
// include { annotateVCF } from './modules/annotatevcf.module'
// include { mergeVCF } from './modules/mergevcf.module'
// include { collectLogs } from './modules/collectlogs.module'

// // create a named pipeline
// workflow awesome_pipeline {
//     take:
//       vcfFiles
//     main: 
//       splitVCF( vcfFiles )
//       annotateVCF( splitVCF.out.splitvcf.flatten() )
//       mergeVCF( annotateVCF.out.annotatedvcf.groupTuple().map{ tuple(it[0], it[1]) } )
//       collectLogs( 
//                    splitVCF.out.splitlog.collectFile(name: 'splitVCF.log'), 
//                    annotateVCF.out.annotatedlog.collectFile(name: 'annotateVCF.log'),
//                    mergeVCF.out.mergedlog.collectFile(name: 'mergeVCF.log')
//                  )
// }

// // create another named pipeline
// workflow removelogs {
//     take:
//       vcfFiles
//     main: 
//       splitVCF( vcfFiles )
//       annotateVCF( splitVCF.out.splitvcf.flatten() )
//       mergeVCF( annotateVCF.out.annotatedvcf.groupTuple().map{ tuple(it[0], it[1]) } )
// }

// // run the pipeline
// workflow {
//   if(params.logs){
//     awesome_pipeline(vcfFiles)
//   } else {
//     removelogs(vcfFiles)
//   }
// }


// When workflow is finished, print some metadata
// can also send an email here using sendmail
// see https://www.nextflow.io/docs/latest/metadata.html
workflow.onComplete {
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