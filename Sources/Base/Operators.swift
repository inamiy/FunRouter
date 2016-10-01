/// infixr 1
precedencegroup Composition { associativity: right }
infix operator >>> : Composition
infix operator <<< : Composition

/// infixl 1
precedencegroup Monad { associativity: left higherThan: FunctorFlipped }
infix operator >>- : Monad

/// infixl 3
precedencegroup Alternative { associativity: left higherThan: Monad }
infix operator <|> : Alternative

/// Infixl 4
precedencegroup Applicative { associativity: left higherThan: Alternative }
infix operator <*>  : Applicative
infix operator <**> : Applicative
infix operator <*   : Applicative
infix operator *>   : Applicative

/// infixl 4
precedencegroup Functor { associativity: left higherThan: Applicative }
infix operator <^> : Functor
infix operator <^  : Functor
infix operator ^>  : Functor

/// infixl 1 (defined in Control.Lens)
precedencegroup FunctorFlipped { associativity: left higherThan: Composition }
infix operator <&> : FunctorFlipped

precedencegroup FunctorFlippedHigh { associativity: left higherThan: ApplicativeRight }
infix operator <&!> : FunctorFlippedHigh

precedencegroup ApplicativeRight { associativity: right higherThan: Applicative }
infix operator </> : ApplicativeRight

prefix operator /
