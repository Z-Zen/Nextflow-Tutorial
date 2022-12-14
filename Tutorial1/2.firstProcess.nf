#!/usr/bin/env nextflow

params.words = ""

// create a channel from given parameter
testChannel = Channel.from(params.words)


// DSL1
// use: nextflow run firstProcess.nf --words hi -dsl1
// if no shebang is defined, the script will be executed using bash(default shell)
process test1 {
  debug true                       // enable debug mode, used to allow the process to output to stdout
  cpus 1                           // set the number of cpus to be used by the process
  memory '1 GB'                    // set the memory to be used by the process
  executor 'local'                 // set the executor to be used by the process

  input:                           // input directive, Nf special syntax to define the input channel
    val words from testChannel     // define a variable called 'words' from input channel 'testChannel'

  output:                          // output directive, Nf special syntax to define the output channel
    stdout words2                  // output the value of 'words' into stdout

  script:                          // script directive, Nf special syntax to define the script to be executed
    """
    echo $words
    """
}


// // DSL2
// // use: nextflow run firstProcess.nf --words hi
// // if no shebang is defined, the script will be executed using bash(default shell)
// process test1 {
//   debug true                       // enable debug mode, used to allow the process to output to stdout
//   cpus 1                           // set the number of cpus to be used by the process
//   memory '1 GB'                    // set the memory to be used by the process
//   executor 'local'                 // set the executor to be used by the process

//   input:                           // input directive, Nf special syntax to define the input channel
//     val words     // define a variable called 'words' from input channel 'testChannel'

//   output:                          // output directive, Nf special syntax to define the output channel
//     val "hi"     // output the value of 'words' into output channel 'testChannel2'

//   script:                          // script directive, Nf special syntax to define the script to be executed
//     """
//     echo $words
//     """
// }

// workflow(){
//   test1(testChannel)
// }