#!/usr/bin/env nextflow

// Introducing nextflow.config and modules

// params.inputFile = null

// if (!params.inputFile) {
//   println "Please specify --inputFile"
//   System.exit(1)
// }

// DSL1
// process process1 {
//   input:
//     ? inputFile from params.inputFile

//   output:
//     ? 'output*' into outputFile

//   script:
//     """
//     split -l 1 $inputFile output_
//     """
// }

// outputFile.?().set { outputFile2 }

// process process2 {
//   tag "filename: $inputFile - task process: $task.process - task index: $task.index - task attempt: $task.attempt"
//   publishDir "inputFileResults/", mode: 'copy'

//   input:
//     file inputFile from ?

//   output:
//     file ? into outputFile3

//   script:
//     """
//     cat ${inputFile} > \$(cat ${inputFile} | cut -f1 -d".").txt
//     """
// }


// // DSL2
// process process1 {
//   input:
//   file inputFile

//   output:
//   file 'output*'

//   script:
//     """
//     split -l 1 $inputFile output_
//     """
// }

// process process2 {
//   debug true
//   tag "filename: $inputFile - task process: $task.process - task index: $task.index - task attempt: $task.attempt"

//   input:
//   file inputFile

//   script:
//     """
//     cat $inputFile
//     """
// }

// workflow {
//   ?
//   ?
//   ?
// }








// // Corrigé
// params.inputFile = null

// if (!params.inputFile) {
//   println "Please specify --inputFile"
//   System.exit(1)
// } else {
//   input_ch = Channel.fromPath(params.inputFile)
// }

// // DSL1
// process process1 {
//   input:
//     file inputFile from input_ch

//   output:
//     file 'output*' into outputFile

//   script:
//     """
//     split -l 1 $inputFile output_
//     """
// }

// outputFile.flatten().set { outputFile2 }

// process process2 {
//   tag "filename: $inputFile - task process: $task.process - task index: $task.index - task attempt: $task.attempt"
//   publishDir "inputFileResults/", mode: 'copy'

//   input:
//     file inputFile from outputFile2

//   output:
//     file '*.txt' into outputFile3

//   script:
//     """
//     cat ${inputFile} > \$(cat ${inputFile} | cut -f1 -d".").txt
//     """
// }

// // DSL2
// process process1 {
//   input:
//     file inputFile

//   output:
//     file 'output*'

//   script:
//     """
//     split -l 1 $inputFile output_
//     """
// }

// process process2 {
//   tag "filename: $inputFile - task process: $task.process - task index: $task.index - task attempt: $task.attempt"
//   publishDir "inputFileResults/", mode: 'copy'

//   input:
//     file inputFile

//   output:
//     file '*.txt'

//   script:
//     """
//     cat ${inputFile} > \$(cat ${inputFile} | cut -f1 -d".").txt
//     """
// }

// include { process1 } from './modules/split.module'
// include { process2 } from './modules/cat.module'

// workflow {
//   process1(input_ch)
//   process1.out.flatten().set { process2_input_ch }
//   process2(process2_input_ch)
// }