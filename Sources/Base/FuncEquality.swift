// Hacky Function equality
// - https://gist.github.com/dankogai/b03319ce427544beb5a4
// - http://qiita.com/dankogai/items/ab407918dba590016058 (Japanese)

internal func peekFunc<A, R>(_ f: (A) -> R) -> (fp: Int, ctx: Int)
{
    let (_, low) = unsafeBitCast(f, to: (Int, Int).self)
    let offset = MemoryLayout<Int>.size == 8 ? 16 : 12  // 8 bit * 2 pointers, or 4 bit * 3 pointers
    let ptr = UnsafePointer<Int>(bitPattern: low + offset)
    return (ptr!.pointee, ptr!.successor().pointee)
}

internal func === <A, R>(lhs: (A) -> R, rhs: (A) -> R) -> Bool
{
    let (tl, tr) = (peekFunc(lhs), peekFunc(rhs))
    return tl.0 == tr.0 && tl.1 == tr.1
}

internal func < <A, R>(_ lhs: (A) -> R, _ rhs: (A) -> R) -> Bool
{
    let ((fp1, ctx1), (fp2, ctx2)) = (peekFunc(lhs), peekFunc(rhs))
    if fp1 == fp2 {
        return ctx1 < ctx2
    }
    else {
        return fp1 < fp2
    }
}
