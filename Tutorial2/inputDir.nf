#!/usr/bin/env nextflow

// Introducing some nextflow functions, nextflow.config and modules


params.inputDir = null

if (!params.inputDir) {
  println "Please specify --inputDir"
  System.exit(1)
}

// First, we need to get files from the given directory into a channel
// Directory contains
// - file1 = file1_1.txt
// - file2 = file2.txt
// - file3 = file3_1.txt, file3_2.txt
// We need to create a channel for each file1, file2 and file3.
// Each channel should contain: (filename, file1, file2 if exists)
// Hint1: use fromFilePairs to get paired files, see https://www.nextflow.io/docs/latest/channel.html#fromfilepairs
// Hint2: use map to create a tuple(list) of (filename, file1, file2 if exists), see https://www.nextflow.io/docs/latest/operator.html#map
// Hint3: to get filename, use tokenize function of groovy
Channel
  .fromFilePairs(["${params.inputDir}/*_{1,2}.txt", ?], size: ?)                                   // will generally return a list [filename, [file1, file2]]
  .map{
    tuple(                                                                                         // create a list of the following:
      it[0].tokenize(".")[0].tokenize("_")[0],                                                       // filename parsed from full path of file1 e.g. /path/to/file1_1.txt -> file1
      ?,                                                                                             // file1
      it[1][1]                                                                                       // file2 if exists
    )                                                                                              // end of list
  }
  .set{ ch_input }                                                                                 // return a list of [filename, file1, file2] into ch_input channel

// ch_input.view()

// DSL1
process process1 {
  debug true
  input:
    tuple val(filename), file(file1), file(file2) from ch_input

  output:
    tuple ?, ?("*.txt") into ch_output

  script:
    """
    echo "filename: $filename"
    echo "file1: $file1"
    if [[ -s "$file2" ]]; then echo "file2: $file2"; fi

    cat $file1 $file2 > ${filename}_new.txt
    """
}


process process2 {
  debug true
  tag "$filename - $task.process - $task.index - $task.attempt"
  publishDir "inputDirResults/", mode: 'copy', pattern: "*.txt"

  input:
    tuple val(filename), file(inputfile) from ch_output

  output:
    ?

  script:
    """
    echo filename: ${filename}
    echo inputfile: ${inputfile}
    cat ${inputfile} > ${filename}.txt
    """
}




// DSL2
// process process1 {
//   debug true

//   input:
//    ?

//   output:
//    ?

//   script:
//     """
//     echo "filename: $filename"
//     echo "file1: $file1"
//     if [[ -s "$file2" ]]; then echo "file2: $file2"; fi

//     cat $file1 $file2 > ${filename}_new.txt
//     """
// }

// process process2 {
//   debug true
//   tag "$filename - $task.process - $task.index - $task.attempt"
//   publishDir "inputDirResults/", mode: 'copy', pattern: "*.txt"

//   input:
//     ?

//   output:
//     ?

//   script:
//     """
//     echo filename: ${filename}
//     echo inputfile: ${inputfile}
//     cat ${inputfile} > ${filename}.txt
//     """
// }


// workflow {
//   process1(ch_input)
//   process2(process1.out)
// }





// corrigé

// params.inputDir = null

// if (!params.inputDir) {
//   println "Please specify --inputDir"
//   System.exit(1)
// }

// get files from directory into a channel
// Channel
//   .fromFilePairs(["${params.inputDir}/*_{1,2}.txt", "${params.inputDir}/file2.txt"], size: -1)   // size: -1 means all files
//   .map{ tuple(it[0].tokenize(".")[0].tokenize("_")[0], it[1][0], it[1][1]) }.set{ ch_input }     // return a list of (filename, file1, file2) into ch_input channel

// // ch_input.view()

// // DSL1
// process process1 {
//   debug true

//   input:
//     tuple val(filename), file(file1), file(file2) from ch_input

//   output:
//     tuple val(filename), file("*.txt") into ch_output

//   script:
//     """
//     echo "filename: $filename"
//     echo "file1: $file1"
//     if [[ -s "$file2" ]]; then echo "file2: $file2"; fi

//     cat $file1 $file2 > ${filename}_new.txt
//     """
// }


// process process2 {
//   debug true
//   tag "$filename - $task.process - $task.index - $task.attempt"
//   publishDir "inputDirResults/", mode: 'copy', pattern: "*.txt"

//   input:
//     tuple val(filename), file(inputfile) from ch_output

//   output:
//     file "*.txt"

//   script:
//     """
//     echo filename: ${filename}
//     echo inputfile: ${inputfile}
//     cat ${inputfile} > ${filename}.txt
//     """
// }

// DSL2

// process process1 {
//   debug true
//   input:
//    tuple val(filename), file(file1), file(file2)

//   output:
//    tuple val(filename), file("*.txt")

//   script:
//   """
//   echo "filename: $filename"
//   echo "file1: $file1"
//   if [[ -s "$file2" ]]; then echo "file2: $file2"; fi

//   cat $file1 $file2 > ${filename}_new.txt
//   """
// }

// process process2 {
//   debug true
//   tag "$filename - $task.process - $task.index - $task.attempt"
//   publishDir "inputDirResults/", mode: 'copy', pattern: "*.txt"

//   input:
//     tuple val(filename), file(inputfile)

//   output:
//     file "*.txt"

//   script:
//   """
//   echo filename: ${filename}
//   echo inputfile: ${inputfile}
//   cat ${inputfile} > ${filename}.txt
//   """
// }


// include { process1 } from './modules/process1.module'
// include { process2 } from './modules/process2.module'

// workflow {
//   process1(ch_input)
//   process2(process1.out)
// }