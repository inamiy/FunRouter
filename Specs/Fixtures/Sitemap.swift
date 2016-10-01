import Foundation

enum Sitemap: Equatable {
    case foo(Int)       // "/R/foo/{Int}"
    case bar(Double)    // "/R/bar/{Double}"
    case baz(String)    // "/R/baz/{String}"
    case fooBar         // "/R/foo/bar

    case foo2(Int, Int)     // "/{Int}/foo/{Int}"
    case bar2(Int, Double)  // "/{Int}/bar/{Double}"
    case baz2(Int, String)  // "/{Int}/baz/{String}"
    case fooBar2(Int)       // "/{Int}/foo/bar"

    case notFound       // 404

    static func ==(lhs: Sitemap, rhs: Sitemap) -> Bool {
        switch (lhs, rhs) {
            case let (.foo(l), .foo(r)) where l == r:
                return true
            case let (.bar(l), .bar(r)) where l == r:
                return true
            case let (.baz(l), .baz(r)) where l == r:
                return true
            case (.fooBar, .fooBar):
                return true

            case let (.foo2(l), .foo2(r)) where l == r:
                return true
            case let (.bar2(l), .bar2(r)) where l == r:
                return true
            case let (.baz2(l), .baz2(r)) where l == r:
                return true
            case let (.fooBar2(l), .fooBar2(r)) where l == r:
                return true

            case (.notFound, .notFound):
                return true
            default:
                return false
        }
    }
}
