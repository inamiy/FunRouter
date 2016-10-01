import Foundation

/// Enum-based URL route (optimizable).
public indirect enum Route2<Value>
{
    case match(String, Route2<Value>)
    case capture(String, (String) -> Any?, (Any) -> Route2<Value>)  // (description, parse, convert)
    case choice([Route2<Value>])
    case term(Value)
    case zero
}

extension Route2
{
    public func run(_ pathComponents: [String]) -> Value?
    {
        switch self {
            case let .match(string, route2):
                if let (head, tail) = uncons(pathComponents), string == head {
                    return route2.run(Array(tail))
                }
                else {
                    return nil
                }
            case let .capture(_, parse, convert):
                if let (head, tail) = uncons(pathComponents) {
                    if let parsed = parse(head) {
                        return convert(parsed).run(Array(tail))
                    }
                    else {
                        return nil
                    }
                }
                else {
                    return nil
                }
            case let .choice(routes):
                if let (head, tail) = uncons(routes) {
                    if let value1 = head.run(pathComponents) {
                        return value1
                    }
                    else {
                        return Route2<Value>.choice(Array(tail)).run(pathComponents)
                    }
                }
                else {
                    return nil
                }
            case let .term(value):
                return value
            case .zero:
                return nil
        }
    }

    fileprivate var _match: (String, Route2<Value>)?
    {
        guard case let .match(string, route) = self else {
            return nil
        }
        return (string, route)
    }

    fileprivate var _capture: (String, (String) -> Any?, (Any) -> Route2<Value>)?
    {
        guard case let .capture(desc, parse, convert) = self else {
            return nil
        }
        return (desc, parse, convert)
    }
}

extension Route2: CustomStringConvertible
{
    public var description: String
    {
        switch self {
            case let .match(string, route2):
                return ".match(\"\(string)\", \(route2))"
            case let .capture(desc, _, _):
                return ".capture(\(desc))"
            case let .choice(routes):
                return ".choice(\(routes))"
            case let .term(value):
                return ".term(\(value))"
            case .zero:
                return ".zero"
        }
    }
}

// MARK: Alternative

public func empty<Value>() -> Route2<Value>
{
    return .zero
}

public func <|> <Value>(route1: Route2<Value>, route2: @autoclosure @escaping () -> Route2<Value>) -> Route2<Value>
{
    return .choice([route1, route2()])
}

// MARK: Applicative

public func pure<Value>(_ value: Value) -> Route2<Value>
{
    return .term(value)
}

public func <*> <Value1, Value2>(route1: Route2<(Value1) -> Value2>, route2: @autoclosure @escaping () -> Route2<Value1>) -> Route2<Value2>
{
    switch route1 {
        case let .match(string, route1b):
            return .match(string, route1b <*> route2())
        case let .capture(desc, parse, convert):
            return .capture(desc, parse, { convert($0) <*> route2() })
        case let .choice(routes):
            return .choice(routes.map { $0 <*> route2() })
        case let .term(f):
            return f <^> route2()
        case .zero:
            return .zero
    }
}

public func <**> <Value1, Value2>(route1: Route2<Value1>, route2: @autoclosure @escaping () -> Route2<(Value1) -> Value2>) -> Route2<Value2>
{
    return { a in { $0(a) } } <^> route1 <*> route2
}

public func <* <Out1, Out2>(route1: Route2<Out1>, route2: @autoclosure @escaping () -> Route2<Out2>) -> Route2<Out1>
{
    return const <^> route1 <*> route2
}

public func *> <Out1, Out2>(route1: Route2<Out1>, route2: @autoclosure @escaping () -> Route2<Out2>) -> Route2<Out2>
{
    return const(id) <^> route1 <*> route2
}

// MARK: Functor

public func <^> <Value1, Value2>(f: @escaping (Value1) -> Value2, route: Route2<Value1>) -> Route2<Value2>
{
    switch route {
        case let .match(string, route2):
            return .match(string, f <^> route2)
        case let .capture(desc, parse, convert):
            return .capture(desc, parse, { f <^> convert($0) })
        case let .choice(routes):
            return .choice(routes.map { f <^> $0 })
        case let .term(value):
            return .term(f(value))
        case .zero:
            return .zero
    }
}

public func <^ <Value1, Value2>(value: Value2, route: Route2<Value1>) -> Route2<Value2>
{
    return const(value) <^> route
}

public func ^> <Value1, Value2>(route: Route2<Value1>, value: Value2) -> Route2<Value2>
{
    return const(value) <^> route
}

// MARK: Route

public func capture<Value>(_ description: String, _ parse: @escaping (String) -> Value?) -> Route2<Value>
{
    return .capture(description, parse, { .term($0 as! Value) })
}

public func int() -> Route2<Int>
{
    return capture("int") { Int($0) }
}

public func double() -> Route2<Double>
{
    return capture("double") { Double($0) }
}

public func string() -> Route2<String>
{
    return capture("string", id)
}

public func match(_ string: String) -> Route2<()>
{
    return .match(string, .term(()))
}

public func choice<Value>(_ routes: [Route2<Value>]) -> Route2<Value>
{
    return .choice(routes)
}

public func optimize<Value>(_ route: Route2<Value>) -> Route2<Value>
{
    switch route {
        case let .match(string, route2):
            return .match(string, optimize(route2))
        case let .capture(desc, parse, convert):
            return .capture(desc, parse, { optimize(convert($0)) })
        case let .choice(routes):
            return _optimizeChoice(routes)
        case .term, .zero:
            return route
    }
}

private func _optimizeChoice<Value>(_ routes: [Route2<Value>]) -> Route2<Value>
{
    /// Ascending order, e.g. `.match("a") < .match("z") < .capture(_, lowerAddress, _) < .capture(_, higherAddress, _) < other`,
    /// to reorder before optimization.
    func isAscending(_ route1: Route2<Value>, _ route2: Route2<Value>) -> Bool
    {
        switch (route1, route2) {
            case let (.match(string1, nextRoute1), .match(string2, nextRoute2)):
                if string1 == string2 {
                    return isAscending(nextRoute1, nextRoute2)
                }
                else {
                    return string1 < string2
                }
            case (.match, _):
                return true
            case let (.capture(_, parse1, _), .capture(_, parse2, _)):
                return parse1 < parse2
            case (.capture, _):
                return true
            default:
                return false
        }
    }

    func isSameRouteHead(_ route1: Route2<Value>) -> (Route2<Value>) -> Bool
    {
        return { route2 in
            switch (route1, route2) {
                case let (.match(string1, _), .match(string2, _)) where string1 == string2:
                    return true
                case let (.capture(_, parse1, _), .capture(_, parse2, _)) where parse1 === parse2:
                    return true
                default:
                    return false
            }
        }
    }

    func flatten<C: Collection>(_ routes: C) -> Route2<Value>
        where C.SubSequence: Collection, C.Iterator.Element == Route2<Value>
    {
        guard let (r, rs) = uncons(routes) else {
            return .zero
        }

        guard !rs.isEmpty else {
            return r
        }

        switch r {
            case let .match(string, _):
                let subRoutes = filterMap({ $0._match?.1 })(routes)
                return .match(string, _optimizeChoice(subRoutes))
            case let .capture(desc, parse, _):
                let converts = filterMap({ $0._capture?.2 })(routes)
                return .capture(desc, parse, { parsed in
                    let routes = converts.map { $0(parsed) }
                    return _optimizeChoice(routes)
                })
            default:
                return .zero
        }
    }

    if routes.isEmpty {
        return .zero
    }

    // Sort, group by the same route-head, and flatten.
    let sortedRoutes = routes.sorted(by: isAscending)
    let arrangedRoutes = groupBy(isSameRouteHead)(ArraySlice(sortedRoutes)).map(flatten)

    return choice(arrangedRoutes)
}

// MARK: Route operators

/// Flipped `<^>`.
public func <&> <Value1, Value2>(route: Route2<Value1>, f: @escaping (Value1) -> Value2) -> Route2<Value2>
{
    return f <^> route
}

/// Flipped `<^>` with higher precedence than `<&>`.
public func <&!> <Value1, Value2>(route: Route2<Value1>, f: @escaping (Value1) -> Value2) -> Route2<Value2>
{
    return f <^> route
}

/// `associativity: right` version of `<**>`.
public func </> <Value1, Value2>(route1: Route2<Value1>, route2: @autoclosure @escaping () -> Route2<(Value1) -> Value2>) -> Route2<Value2>
{
    return route1 <**> route2
}

public prefix func / (string: String) -> Route2<()>
{
    return match(string)
}
