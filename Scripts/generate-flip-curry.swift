#!/usr/bin/env xcrun swift

// From https://github.com/thoughtbot/Curry

// Generates a Swift file with implementation of function currying for a ridicolously high number of arguments

import Foundation

let generics = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

extension Array {
  subscript(safe index: Int) -> Element? {
    return indices ~= index ? self[index] : .none
  }
}

func genericType(for position: Int) -> String {
  let max = generics.count
  switch position {
  case _ where position < max: return generics[position % max]
  default: return generics[position / max - 1] + generics[position % max]
  }
}

func commaConcat(_ xs: [String]) -> String {
  return xs.joined(separator: ", ")
}

func singleParameterFunctions(_ xs: [String]) -> String {
  guard let first = xs.first else { fatalError("Attempted to nest functions with no arguments") }
  guard xs.last != first else { return first }
  let remainder = Array(xs.dropFirst())
  return "(\(first)) -> \(singleParameterFunctions(remainder))"
}

func curryDefinitionGenerator(arguments: Int) -> String {
  let genericParameters = (0..<arguments).map(genericType) // ["A", "B", "C", "D"]
  let genericTypeDefinition = "<\(commaConcat(genericParameters))>" // "<A, B, C, D>"

  let inputParameters = Array(genericParameters[0..<arguments - 1]) // ["A", "B", "C"]
  let lowerFunctionArguments = inputParameters.map { "\($0.lowercased())" } // ["a", "b", "c"]
  let returnType = genericParameters.last! // "D"

  let reversedInputParameters = Array(inputParameters.reversed()) // ["C", "B", "A"]
  let reversedGenericParameters = reversedInputParameters + [returnType] // ["C", "B", "A", "D"]
  let reversedLowerFunctionArguments = reversedInputParameters.map { "\($0.lowercased())" } // ["c", "b", "a"]

  let functionArguments = "(\(commaConcat(inputParameters)))" // "(A, B, C)"
  let returnFunction = singleParameterFunctions(reversedGenericParameters) // " (C) -> (B) -> (A) -> D"
  let innerFunctionArguments = commaConcat(lowerFunctionArguments) // "a, b, c"

  let functionDefinition = "function(\(innerFunctionArguments))" // function(a, b, c)

  let implementation = reversedLowerFunctionArguments.enumerated().reversed().reduce(functionDefinition) { accum, tuple in
    let (index, argument) = tuple
    let functionParameters = Array(reversedGenericParameters.suffix(from: index + 1))
    return "{ (\(argument): \(reversedInputParameters[index])) -> \(singleParameterFunctions(functionParameters)) in \(accum) }"
  } // "{ (a: A) -> (B) -> (C) -> D in { (b: B) -> (C) -> D in { (c: C) -> D in function(a, b, c) } } }"

  let curry = [
    "public func flipCurry\(genericTypeDefinition)(_ function: @escaping \(functionArguments) -> \(returnType)) -> \(returnFunction) {",
    "    return \(implementation)",
    "}"
  ]

  return curry.joined(separator: "\n")
}

print("Generating 💬")

let input = CommandLine.arguments[safe: 1] ?? "20"
let limit = Int(input)!

let start = 2
let curries = (start...limit+1).map { curryDefinitionGenerator(arguments: $0) }

let output = curries.joined(separator: "\n\n") + "\n"

let outputPath = "FlipCurry.swift"
let currentPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let currySwiftPath = currentPath.appendingPathComponent(outputPath)
do {
  try output.write(to: currySwiftPath, atomically: true, encoding: String.Encoding.utf8)
  print("Done, curry functions files written at \(outputPath) 👍")
} catch let e as NSError {
  print("An error occurred while saving the generated functions. Error: \(e)")
}
