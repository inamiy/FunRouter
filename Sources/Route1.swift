import Foundation

/// Function-based URL route.
public struct Route1<Value>
{
    let parse: ([String]) -> ([String], Value)?
}

extension Route1
{
    public func run(_ pathComponents: [String]) -> Value? {
        return self.parse(pathComponents).map { $0.1 }
    }
}

// MARK: Alternative

public func empty<Value>() -> Route1<Value>
{
    return Route1 { _ in nil }
}

public func <|> <Value>(route1: Route1<Value>, route2: @autoclosure @escaping () -> Route1<Value>) -> Route1<Value>
{
    return Route1 { pathComponents in
        let reply = route1.parse(pathComponents)
        switch reply {
            case .some:
                return reply
            case .none:
                return route2().parse(pathComponents)
        }
    }
}

// MARK: Applicative

public func pure<Value>(_ value: Value) -> Route1<Value>
{
    return Route1 { ($0, value) }
}

public func <*> <Value1, Value2>(route1: Route1<(Value1) -> Value2>, route2: @autoclosure @escaping () -> Route1<Value1>) -> Route1<Value2>
{
    return Route1 { pathComponents in
        let reply = route1.parse(pathComponents)
        switch reply {
            case let .some(pathComponents2, f):
                return (f <^> route2()).parse(pathComponents2)
            case .none:
                return nil
        }
    }
}

public func <**> <Value1, Value2>(route1: Route1<Value1>, route2: @autoclosure @escaping () -> Route1<(Value1) -> Value2>) -> Route1<Value2>
{
    return { a in { $0(a) } } <^> route1 <*> route2
}

public func <* <Out1, Out2>(route1: Route1<Out1>, route2: @autoclosure @escaping () -> Route1<Out2>) -> Route1<Out1>
{
    return const <^> route1 <*> route2
}

public func *> <Out1, Out2>(route1: Route1<Out1>, route2: @autoclosure @escaping () -> Route1<Out2>) -> Route1<Out2>
{
    return const(id) <^> route1 <*> route2
}

// MARK: Functor

public func <^> <Value1, Value2>(f: @escaping (Value1) -> Value2, route: Route1<Value1>) -> Route1<Value2>
{
    return Route1 { pathComponents in
        let reply = route.parse(pathComponents)
        switch reply {
            case let .some(pathComponents2, value):
                return (pathComponents2, f(value))
            case .none:
                return nil
        }
    }
}

public func <^ <Value1, Value2>(value: Value2, route: Route1<Value1>) -> Route1<Value2>
{
    return const(value) <^> route
}

public func ^> <Value1, Value2>(route: Route1<Value1>, value: Value2) -> Route1<Value2>
{
    return const(value) <^> route
}

// MARK: Route

public func capture<Value>(_ parse: @escaping (String) -> Value?) -> Route1<Value>
{
    return Route1 { pathComponents in
        if let (first, rest) = uncons(pathComponents), let parsed = parse(first) {
            return (Array(rest), parsed)
        }
        return nil
    }
}

public func int() -> Route1<Int>
{
    return capture { Int($0) }
}

public func double() -> Route1<Double>
{
    return capture { Double($0) }
}

public func string() -> Route1<String>
{
    return capture(id)
}

public func match(_ string: String) -> Route1<()>
{
    return capture { $0 == string ? () : nil }
}

public func choice<Value>(_ routes: [Route1<Value>]) -> Route1<Value>
{
    return routes.reduce(empty()) { $0 <|> $1 }
}

// MARK: Helper operators

/// Flipped `<^>`.
public func <&> <Value1, Value2>(route: Route1<Value1>, f: @escaping (Value1) -> Value2) -> Route1<Value2>
{
    return f <^> route
}

/// Flipped `<^>` with higher precedence than `<&>`.
public func <&!> <Value1, Value2>(route: Route1<Value1>, f: @escaping (Value1) -> Value2) -> Route1<Value2>
{
    return f <^> route
}

/// `associativity: right` version of `<**>`.
public func </> <Value1, Value2>(route1: Route1<Value1>, route2: @autoclosure @escaping () -> Route1<(Value1) -> Value2>) -> Route1<Value2>
{
    return route1 <**> route2
}

public prefix func / (string: String) -> Route1<()>
{
    return match(string)
}
