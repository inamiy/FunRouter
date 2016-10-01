# FunRouter

Functional & type-safe URL routing example for [Functional Swift Conference 2016](http://2016.funswiftconf.com/).

There are following route types available.

- `Route1` (struct, function-based)
- `Route2` (enum, optimizable) 


## Example

Assume `typealias Route<Value> = RouteN<Value>` (`N = 1, 2`).

```swift
/// Parses "/Hello/{city}/{year}".
let route: Route<(String, Int)> =
    curry { ($1, $2) } <^> match("Hello") <*> string() <*> int()
    
// or, more fancy flipped way:
// let route =
//    /"Hello" </> string() </> int() <&!> flipCurry { ($1, $2) }

let value1 = route.run(["Hello", "Budapest", "2016"])
expect(value1?.0) == "Budapest"
expect(value1?.1) == 2016

let value2 = route.run(["Ya", "tu", "sabes"])
expect(value2).to(beNil())
```

### More complex routing

```swift
enum Sitemap {
    case foo(Int)       // "/R/foo/{Int}"
    case bar(Double)    // "/R/bar/{Double}"
    case baz(String)    // "/R/baz/{String}"
    case fooBar         // "/R/foo/bar"
    case notFound
}

let route: Route<Sitemap> =
    match("R")
        *> choice([
            match("foo") *> int() <&> Sitemap.foo,
            match("bar") *> double() <&> Sitemap.bar,
            match("baz") *> string() <&> Sitemap.baz,
            match("foo") *> match("bar") *> pure(Sitemap.fooBar),
        ])
    <|> pure(Sitemap.notFound)
    
expect(route.run(["R", "foo", "123"])) == .foo(123)
expect(route.run(["R", "bar", "4.5"])) == .bar(4.5)
expect(route.run(["R", "baz", "xyz"])) == .baz("xyz")
expect(route.run(["R", "foo", "bar"])) == .fooBar
expect(route.run(["R", "foo", "xxx"])) == .notFound
```

### Optimization

For `Route2<Value>`, you can call `optimize()` so that:

```swift
// Before optimization (duplicated `match("foo")`)
let naiveRoute: Route<Sitemap> =
    match("R")
        *> choice([
            match("foo") *> int() <&> Sitemap.foo,
            match("bar") *> double() <&> Sitemap.bar,
            match("baz") *> string() <&> Sitemap.baz,
            match("foo") *> match("bar") *> pure(Sitemap.fooBar)
        ])

// After optimization
let optimizedRoute = optimize(naiveRoute)
```

will have an optimized structure as:

```swift
naiveRoute = .match("R", .choice([
    .match("foo", .capture(int)),
    .match("bar", .capture(double)),
    .match("baz", .capture(string)),
    .match("foo", .match("bar", .term(fooBar)))
]))

optimizedRoute = .match("R", .choice([
    .match("bar", .capture(double)),
    .match("baz", .capture(string)),
    .match("foo", .choice([
        .capture(int),
        .match("bar", .term(fooBar))
    ]))
]))
```


## References

- Talk
    - TBD
- Parser Combinator
    - [Parser Combinators in Swift](https://realm.io/news/tryswift-yasuhiro-inami-parser-combinator/) (video)
    - [Parser Combinator in Swift // Speaker Deck](https://speakerdeck.com/inamiy/parser-combinator-in-swift) (slide)


## Licence

[MIT](LICENSE)
