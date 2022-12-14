#!/usr/bin/env nextflow

// hard coded variable
staticWords = 'Hello World'

// parameter variable that can be changed at runtime
params.words = 'Hello World'

println("---------------------------------\n")

println("Testing local vs global variables inside an if statement \n")

// examples of local vs global variables
// when you define a variable with def, it is local else it is global
if(true){
  def testVar = "test"
  testVar2 = "test2"
  println("Inside IF statement:")
  println("Printing testVar inside my if condition: " + testVar)
  println("Printing testVar2 inside my if condition: " + testVar2 + "\n")
}
// if "testVar" is defined, it will print it
// since it is local, it will not be defined outside of the if statement
println("Outside IF statement:")
if(binding.hasVariable("testVar") == true){
  println("Printing testVar outside my if condition: " + testVar)
} else {
  println("Printing testVar outside my if condition: " + "not defined")
}

// if "testVar2" is defined in the environment, it will print it
// since it is global, it will be defined outside of the if statement
if(binding.hasVariable("testVar2") == true){
  println("Printing testVar2 outside my if condition: " + testVar2 + "\n")
} else {
  println("Printing testVar2 outside my if condition: " + "not defined\n")
}

// ternary operator that is equivalent to the above if statement
// println("Printing my testVar2 outside my if condition: " + (binding.hasVariable("testVar2") == true) ? testVar2 : "not defined")


println("---------------------------------\n")

println("Testing static vs parameter variables")

// Groovy language, prints static variable
println("My static words: " + staticWords)

// Groovy language, prints the given parameter
println("My param words: " + params.words)


println("---------------------------------\n")

println("Testing list")

myList = [1,2,3,4,5,6,7,8,9,10]

println("My list: " + myList + "\n")

println("Testing for loop")

for (i in myList){
  println("i: " + i)
}

println("---------------------------------\n")

println("Multiply each element by 2: " + myList.collect{it * 2})
println("My original list did not change: " + myList)
myList << 11                  // add 11
myList.add(3,0)               // add 0 just before index 3
myList.addAll([12,13])        // add 12 and 13
myList.addAll(12,["Hi"])      // add "Hi" just before index 12
myList.removeElement("Hi")    // remove "Hi"
println(myList)               // print myList
println(myList.size())        // print size of myList

// more on collections
// https://groovy-lang.org/groovy-dev-kit.html#_working_with_collections
// https://www.baeldung.com/groovy-collections-find-elements
// https://blog.nareshak.com/groovy-collections-1/


println("---------------------------------\n")

println("Testing map")

myMap = [1: "one", 2: "two", 3: "three"]

println("My map: " + myMap)
println("My map size: " + myMap.size())
println("My map keys: " + myMap.keySet())
println("My map values: " + myMap.values())
println("My map contains key 1: " + myMap.containsKey(1))
println("My map contains key 4: " + myMap.containsKey(4))
println("My map contains value one: " + myMap.containsValue("one"))
println("My map contains value four: " + myMap.containsValue("four"))
println("My map get key 1: " + myMap.get(1))
println("My map get key 4: " + myMap.get(4))
println("My map get key 4 or default: " + myMap.get(4, "default"))

// more on maps
// https://groovy-lang.org/groovy-dev-kit.html#Collections-Maps
// https://www.tutorialspoint.com/groovy/groovy_maps.htm
// https://www.baeldung.com/groovy-collections-find-elements#3-map
