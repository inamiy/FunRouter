import Curry
import FunRouter
import XCTest
import Quick
import Nimble

private typealias Route<Value> = Route1<Value>

class Route1Spec: QuickSpec
{
    override func spec()
    {
        describe("'/Hello/{city}/{year}'") {

            it("basic") {
                let route: Route<(String, Int)> =
                    curry { ($1, $2) } <^> match("Hello") <*> string() <*> int()

                do {
                    let value = route.run(["Hello", "Budapest", "2016"])
                    expect(value?.0) == "Budapest"
                    expect(value?.1) == 2016
                }

                do {
                    let value = route.run(["Ya", "tu", "sabes"])
                    expect(value).to(beNil())
                }
            }

            it("flipCurry") {
                let route: Route<(String, Int)> =
                    /"Hello" </> string() </> int() <&!> flipCurry { ($1, $2) }

                do {
                    let value = route.run(["Hello", "Budapest", "2016"])
                    expect(value?.0) == "Budapest"
                    expect(value?.1) == 2016
                }

                do {
                    let value = route.run(["Ya", "tu", "sabes"])
                    expect(value).to(beNil())
                }
            }

        }

        describe("Complex route using `choice`") {

            it("basic") {
                let route: Route<Sitemap> =
                    match("R")
                        *> choice([
                            match("foo") *> int()       <&> Sitemap.foo,
                            match("bar") *> double()    <&> Sitemap.bar,
                            match("baz") *> string()    <&> Sitemap.baz,
                            match("foo") *> match("bar") *> pure(Sitemap.fooBar),
                        ])
                    <|> pure(Sitemap.notFound)

                expect(route.run(["R", "foo", "123"])) == .foo(123)
                expect(route.run(["R", "bar", "4.5"])) == .bar(4.5)
                expect(route.run(["R", "baz", "xyz"])) == .baz("xyz")
                expect(route.run(["R", "foo", "bar"])) == .fooBar
                expect(route.run(["R", "foo", "xxx"])) == .notFound
            }

            it("flipCurry") {
                let route: Route<Sitemap> =
                    int()
                        </> choice([
                            /"foo" *> int()     <&!> flipCurry { Sitemap.foo2($0, $1) },
                            /"bar" *> double()  <&!> flipCurry { Sitemap.bar2($0, $1) },
                            /"baz" *> string()  <&!> flipCurry { Sitemap.baz2($0, $1) },
//                            /"foo" *> /"bar"    <&!> flipCurry { Sitemap.fooBar2($0.0) }    // Expression was too complex...
                        ])
                    <|> pure(Sitemap.notFound)

                expect(route.run(["0", "foo", "123"])) == .foo2(0, 123)
                expect(route.run(["0", "bar", "4.5"])) == .bar2(0, 4.5)
                expect(route.run(["0", "baz", "xyz"])) == .baz2(0, "xyz")
//                expect(route.run(["0", "foo", "bar"])) == .fooBar2(0)
                expect(route.run(["0", "foo", "xxx"])) == .notFound
            }

        }
    }
}
