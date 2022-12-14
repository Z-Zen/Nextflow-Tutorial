#!/usr/bin/env nextflow

testChannel = Channel.from(params.words)

// DSL1
// use: nextflow run test.nf --words "Hello World" -dsl1
// First process
// if no shebang is defined, the script will be executed using bash(default shell)
process test {
  debug true
  tag "$words - $task.process - $task.index - $task.attempt"          // tag is the name of the process
  publishDir 'outputDir', pattern: '*.txt'                            // publishDir is the directory where the output files will be stored
  memory = { task.exitStatus != 0 ? 1.GB * task.attempt : 1.GB }      // dynamic memory allocation based on task.attempt
  errorStrategy = { task.exitStatus != 0 ? 'retry' : 'terminate' }    // dynamic errorStrategy based on task.exitStatus
  maxRetries = 3                                                      // maxRetries is the number of times a task will be retried
  cpus = 1                                                            // cpus to use for the task
  executor = 'local'                                                  // executor (local, sge, lsf, slurm, etc)
  container = null                                                    // container (docker, singularity, etc)
  cache = 'lenient'                                                   // cache (lenient, strict, none)
  
  input:
    val words from testChannel

  output:
    file 'test.txt' into testOutput

  script:
    """
    echo $words > test.txt
    """
}


// Second process
process test2 {
  debug true
  tag "$inputfile - $task.process - $task.index - $task.attempt"
  errorStrategy { task.exitStatus != 0 ? 'retry' : 'terminate' }
  maxRetries = 3

  input:
    file inputfile from testOutput

  script:
    """
    cat $inputfile
    """
}


// // DSL2
// // use: nextflow run test.nf --words "Hello World" -with-dsl2
// // First process
// process test {
//   tag "$words - $task.process - $task.index - $task.attempt"
//   debug true

//   input:
//     val words

//   output:
//     file 'test.txt'

//   script:
//     """
//     echo $words > test.txt
//     """
// }

// process test2 {
//   debug true
//   tag "$inputfile - $task.process - $task.index - $task.attempt"
//   errorStrategy { task.exitStatus != 0 ? 'retry' : 'terminate' }
//   maxRetries = 3

//   input:
//     file inputfile

//   script:
//     """
//     cat $inputfile
//     """
// }

// // workflow test to test2
// workflow {
//   test(testChannel)
//   test2(test.out)
// }
