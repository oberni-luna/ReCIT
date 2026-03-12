# Agent guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift and SwiftUI. Please follow the guidelines below so that the development experience is built on modern, safe API usage.


## Project overview

- **App name:** RECITs
- **Bundle ID:** <!-- e.g. com.yourname.myapp -->
- **Purpose:** This App allows users to keep track of their books; give, lend or sell them to friends. 
- **Key features:**
  - Item inventory (physical books) 
  - Searching for books : editions, works or authors
  - Keeping track of book lists 
- **Current status:** In development 

### Architecture

- @Observable models shared across views to handle main features 
- SwiftData for persistence, no CloudKit sync
- Navigation driven by NavigationStack + navigationDestination(for:)

## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.


## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.


## Swift instructions

- Always mark `@Observable` classes with `@MainActor`.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app's documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.


## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap's location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don't apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- Place view logic into view models or similar, so it can be tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.


## SwiftData instructions

- Use SwiftData for local persistence (no CloudKit sync).
- Keep models lightweight; prefer relationships over deeply nested data.
- Always use `@Model` for persistence types and keep them in their own files.


## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.


## Code style and linting

- Never let trailing whitespace empty lines in the code.
- If there is a swiftlint file in the repository, always follow its rules.
- When creating function of constructors with many parameters, format them like this:

```swift
func myFunction(
    firstParameter: String,
    secondParameter: Int,
    thirdParameter: Bool
) {
    // function body
}

let myObject = MyClass(
    firstParameter: "Hello",
    secondParameter: 42,
    thirdParameter: true
)
```

- Always explicitly specify the type of a variable or constant when it is being declared, even if it can be inferred, but not for guard/if-let statements. For example:

```swift
let myString: String = "Hello, world!"
var myNumber: Int = 42

guard let myOptionalString else { return }
if let myOptionalNumber {
    // use myOptionalNumber
}
```

- On if let/guard let statements, if the name of the let property have the same name as the optional being unwrapped, use this syntax:

```swift
var myProperty: String?

guard let myProperty else { return }
if let myProperty {
    // use myProperty
}
```

- Prefer the `.init()` syntax when creating instances of types (except for sugar like arrays, dictionaries, and sets). For example:

```swift
let person: Person = .init(name: "Alice", age: 30)
let numbers: [Int] = []
let settings: [String: Any] = [:]
let uniqueValues: Set<String> = []
```

- When using SwiftUI environments, you don't need to explicitly specify the type. For example, prefer this:

```swift
@Environment(\.dismiss) var dismiss // no type needed
@Environment(\.colorScheme) var colorScheme // no type needed
```

- When a function or a computed property only have one line, you can omit the `return` keyword. For example, prefer this:

```swift
var fullName: String {
    firstName + " " + lastName // no return needed
}

func greet() -> String {
    "Hello, \(name)!" // no return needed
}
```
