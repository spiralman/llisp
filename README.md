llisp
=====

A Lisp interpreter implemented in LLVM IR.

# Inspiration #

Peter Norvig's [lis.py](http://norvig.com/lispy.html) both inspired me
to attempt this project and guided my implementation of it. The reader
algorithm in `llisp` is a simplified implementation of that described
in the
[Reader Algorithm](http://www.lispworks.com/documentation/lw70/CLHS/Body/02_b.htm)
section (2.2) of the [Common Lisp HyperSpec](http://www.lispworks.com/documentation/lw70/CLHS/Front/index.htm).

# Building #

Run `make` to build it; run `make test` to run the test suite. You
will need LLVM installed.

For fun, run `make count` to count the number of source lines in the
project (excluding tests).

# Using #

After building it, run `./llisp` to get an interactive REPL, or
`./llisp somefile.llisp` to execute the code in a file. When executing
a file, the result of the last form in the file will be printed to
standard out.

## The language ##

`llisp` implements an extremely limited lisp-like language (maybe a
proto-lisp?), the goal of which is to explore an extremely simple
implementation of a lisp in an implementation language (LLVM IR) which
makes any "hidden" complexities painfully obvious.

As such, there isn't much to it, but you can perform computations with
it.

### `false` | `nil` | `()` ###

The simplest value is `()`, which is an empty list, and is often
spelled `nil`. `false` is also defined as an alias for `nil`.

### `true` ###

The symbol `true` evaluates to the token `true`, which, since it is
not `nil`, is "true" in the boolean sense of the word.

### `define` ###

You can define a symbol using `define`, which adds the symbol to the
global namespace:

```lisp
(define my-truth true)
```

### `if` ###

You can conditionally evaluate expressions using `if`. The first
expression is always evaluated. If it evaluates to non-nil, the second
expression will be evaluated. If it evaluates to nil, the third
expression will be evaluated. The third expressions is optional, in
which case `nil` will be returned when the condition evaluates to
`nil`.

```lisp
(if cond then else)
```

Example:

```
llisp> (if true false true)
nil
```

### `lambda` ###

You can define an anonymous function using `lambda`. The first
form should be a list naming parameters, and the second form will be
evaluated when the function is invoked, and its return value will be
the return value of the invocation.

You invoke a function by making it the first argument to a list.

```lisp
(lambda (params) body)
```

Example:

```
llisp> ((lambda (x) (if x false true)) nil)
true
```

You can name functions using `define`:

```
llisp> (define not (lambda (x) (if x false true)))
nil
llisp> (not true)
nil
llisp> (not false)
true
```

### `cons` ###

`cons` returns a new list in which the first argument is the first
element of the list, and the second argument is the rest of the
list. For convenience, if the second argument is not a list, `cons`
will create a list of one element using the second argument.

```lisp
(cons first rest)
```

Example:

```
llisp> (cons true nil)
(true)
llisp> (cons true true)
(true true)
llisp> (cons true (cons nil (cons true nil)))
(true nil true)
```

### `first` ###

`first` returns the first element of a list.

```lisp
(first a-list)
```

Example:

```
llisp> (first (cons true true))
true
```

### `rest` ###

`rest` returns a list containing all the elements of the list except
the first element.

```lisp
(rest a-list)
```

Example:

```
llisp> (rest (cons true true))
(true)
llisp> (rest (cons true nil))
nil
```
