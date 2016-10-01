import Foundation
import FunRouter
import Curry

//: ## Function-based URL route
typealias Route<Value> = Route1<Value>

//: ### Basic routing

do {
    /// Parses "/Hello/{city}/{year}".
    let route: Route<(String, Int)> =
        curry { ($1, $2) } <^> match("Hello") <*> string() <*> int()

    // or, more fancy flipped way:
//     let route: Route<(String, Int)> =
//        /"Hello" </> string() </> int() <&!> flipCurry { ($1, $2) }

    let value1 = route.run(["Hello", "Budapest", "2016"])
    let value2 = route.run(["Ya", "tu", "sabes"])
}

//: ### More complex routing

enum Sitemap {
    case foo(Int)       // "/R/foo/{Int}"
    case bar(Double)    // "/R/bar/{Double}"
    case baz(String)    // "/R/baz/{String}"
    case fooBar         // "/R/foo/bar"
    case notFound       // 404
}

do {
    let route: Route<Sitemap> =
        match("R")
            *> choice([
                match("foo") *> int() <&> Sitemap.foo,
                match("bar") *> double() <&> Sitemap.bar,
                match("baz") *> string() <&> Sitemap.baz,
                match("foo") *> match("bar") *> pure(Sitemap.fooBar),
            ])
        <|> pure(Sitemap.notFound)

    route.run(["R", "foo", "123"])
    route.run(["R", "bar", "456"])
    route.run(["R", "baz", "xyz"])
    route.run(["R", "foo", "bar"])
    route.run(["R", "foo", "xxx"]) // notFound
}
