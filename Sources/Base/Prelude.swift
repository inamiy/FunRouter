/// Identity function.
internal func id<A>(_ a: A) -> A
{
    return a
}

/// Constant function.
internal func const<A, B>(_ a: A) -> (B) -> A
{
    return { _ in a }
}

/// Unary negation.
internal func negate<N: SignedNumber>(_ x: N) -> N
{
    return -x
}

/// Haskell `(:)` (cons operator) for replacing slow `[x] + xs`.
internal func cons<C: RangeReplaceableCollection>(_ x: C.Iterator.Element) -> (C) -> C
{
    return { xs in
        var xs = xs
        xs.insert(x, at: xs.startIndex)
        return xs
    }
}

/// Extracts head and tail of `Collection`, returning nil if it is empty.
internal func uncons<C: Collection>(_ xs: C) -> (C.Iterator.Element, C.SubSequence)?
{
    if let head = xs.first {
        let secondIndex = xs.index(after: xs.startIndex)
        return (head, xs.suffix(from: secondIndex))
    }
    else {
        return nil
    }
}

/// `splitAt(count)(xs)` returns a tuple of `xs.prefix(upTo: count)` and `suffix(from: count)`,
/// but either of those may be empty.
/// - Precondition: `count >= 0`
internal func splitAt<C: Collection>(_ count: C.IndexDistance) -> (C) -> (C.SubSequence, C.SubSequence)
{
    precondition(count >= 0, "`splitAt(count)` must have `count >= 0`.")

    return { xs in
        let midIndex = xs.index(xs.startIndex, offsetBy: count)
        if count <= xs.count {
            return (xs.prefix(upTo: midIndex), xs.suffix(from: midIndex))
        }
        else {
            return (xs.prefix(upTo: midIndex), xs.suffix(0))
        }
    }
}

/// Haskell's `mapMaybe`.
internal func filterMap<C: Collection, Element2>(_ f: @escaping (C.Iterator.Element) -> Element2?) -> (C) -> [Element2]
{
    return { xs in
        guard !xs.isEmpty else { return [] }

        var ys = [Element2]()
        for x in xs {
            if let y = f(x) {
                ys.append(y)
            }
        }
        return ys
    }
}

/// `span(predicate)(xs)` returns a tuple where first element is longest prefix (possibly empty) of `xs`
/// that satisfy `predicate` and second element is the remainder of `xs`.
internal func span<C: RangeReplaceableCollection>(_ predicate: @escaping (C.Iterator.Element) -> Bool) -> (C) -> (C, C)
    where C.SubSequence == C
{
    return { xs in
        if let (x, xs2) = uncons(xs), predicate(x) {
            let (ys, zs) = span(predicate)(xs2)
            return (cons(x)(ys), zs)
        }
        else {
            return (C(), xs)
        }
    }
}

/// `groupBy(eq)(xs)` returns an array of `RangeReplaceableCollection`
/// where first element in `xs` is tested and concatenated with next elements while `eq` is satisfied,
/// then use its remainder to repeat until all elements are tested.
internal func groupBy<C: RangeReplaceableCollection>(_ eq: @escaping (C.Iterator.Element) -> (C.Iterator.Element) -> Bool) -> (C) -> [C]
    where C.SubSequence == C
{
    return { xs in
        if let (x, xs2) = uncons(xs) {
            let (ys, zs) = span(eq(x))(xs2)
            return cons(cons(x)(ys))(groupBy(eq)(zs))
        }
        else {
            return []
        }
    }
}

/// Flips 1st and 2nd argument of binary operation.
internal func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C
{
    return { b in { a in f(a)(b) } }
}

/// Right-to-left composition.
internal func <<< <A, B, C>(f: @escaping (B) -> C, g: @escaping (A) -> B) -> (A) -> C
{
    return { f(g($0)) }
}

/// Left-to-right composition.
internal func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C
{
    return { g(f($0)) }
}

/// Fixed-point combinator.
internal func fix<T, U>(_ f: @escaping ((T) -> U) -> (T) -> U) -> (T) -> U
{
    return { f(fix(f))($0) }
}

/// Haskell's `error`.
internal func undefined<T>(_ hint: String = "", file: StaticString = #file, line: UInt = #line) -> T
{
    let message = hint == "" ? "" : ": \(hint)"
    fatalError("undefined \(T.self)\(message)", file: file, line: line)
}
