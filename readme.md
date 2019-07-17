[numhask-range](https://github.com/tonyday567/numhask-range)
===

[![Build Status](https://travis-ci.org/tonyday567/numhask-range.svg)](https://travis-ci.org/tonyday567/numhask-range) [![Hackage](https://img.shields.io/hackage/v/numhask-range.svg)](https://hackage.haskell.org/package/numhask-range) [![lts](https://www.stackage.org/package/numhask-range/badge/lts)](http://stackage.org/lts/package/numhask-range) [![nightly](https://www.stackage.org/package/numhask-range/badge/nightly)](http://stackage.org/nightly/package/numhask-range) 

A `Space` represents an interval over a type.  The main instance of a Space, a `Range`, consists of a lower and upper value, though `lower > upper` is allowed, and leads to a useful definition of a negative space. A `Rect` is a wrapped `Compose Pair Range` and so a two-dimensional Space.

spatial zeros and ones
---

This library emerged as a bridge between `chart-unit`, an effort to create a clean, minimalist chart api, and `numhask`, an effort to create clean, minimalist numerical classes.

If you ask yourself what a chart is, sifting through the cruft of accumulated practice, nomenclature and usage, digging deep for charting's essence, and if you ask the question in haskell, here's the simplest object you find:

[![unitSquare](other/src_Diagrams_TwoD_Shapes_unitSquareEx.svg)](other/src_Diagrams_TwoD_Shapes_unitSquareEx.svg)

To a first approximation, charting is transforming and placing this unit on a physical XY plane, such as a screen, or on graph paper.  A rectangle is a distended square; a line is a very thin rectangle; a histogram is a series of rectangles, and axes are nothing more than a collection of squares. The main thing on a chart that isn't a square is text, but even then we use square pixels to render.

one
---

As a well-meaning, but eternally confused student of category theory, I had learnt to pay attention to the simplest thing I could find within a problem domain. To quote from the [haddock](https://www.stackage.org/haddock/lts-8.24/diagrams-lib-1.4.1.2/Diagrams-TwoD-Shapes.html#v:unitSquare), a unitSquare is "a square with its center at the origin and sides of length 1, oriented parallel to the axes." When we first learn to chart, the origin of a graph is usually at the bottom left, and only moves to the center once we learn our negative numbers. The origin for html/svg/css is at top left, however, and the y-axis heads down not up. So what makes this co-ordinate system the right one?

Reducing down to the one dimension case, the diagrams unit boils down to a range along a dimension of -0.5 to 0.5, or `Range -0.5 0.5`.  Length is 1 and the mid-point is 0, so if we define `Range -0.5 0.5` as `one`, the multiplicative unit, we get the very neat:

    mid one == zero
    width one == one

which absolutely nails the correct co-ordinate system, once you see how it easily it can extend to the two-dimensional case: 

    mid (one :: Rect a) == zero :: Pair a
    width (one :: Rect a) == one :: Pair a

zero
---

As a card carrying member of the `+ and <> should be the same thing` committee, I gravitated towards a monoidally additive definition:

    zero = Range infinity neginfinity
    (+) (Range l u) (Range l' u') = Range (min l l') (max u u')
    (<>) = (+)
    mempty = zero

Known as a convex hull union, this operation is the bread-and-butter of charting.  If you have an object at Range 2 3 and one at Range 0 1, then you're going to have to draw over Range 0 3 to get it all on the page.

It's very similar to a tropical semiring, which sets infinity as zero, min as +, and + as *, often summarised as (infinity,min,+) versus the usual (0,+,*) semiring. Reading up on star-semirings [here](http://r6.ca/blog/20110808T035622Z.html), I suspect that an operation that doesn't fill in the holes, that remembers contiguous and non-contiguous intervals in a space, will complete this mempty and plus definition to form a star-semiring.  But the unification of charting and regular expressions is another tale.

space
---

If spatial one and zero are the inspiration of the library, then NumHask.Space is the perspiration.  The Space class are all the various bits and bobs that made up earlier versions of chart operations, refactored a hundred times and slowly reduced to a managable and coherent class.

The Space class came out of common functionality between Range and Rect.  If current trends continue, Space will consume the remaining components of the Range class.  To effect this, however, requires the number heirarchy to be defined for the Space class, which currently leads to compiler whining about orphans, ambiguity and undecidables.  It may be that the consumption of Range ideas will lead to the necessity of wrapping Space in a newtype and that wrapper name may best be Range.  The grind continues.


numhask-histogram
===

[![Hackage](https://img.shields.io/hackage/v/numhask-histogram.svg)](https://hackage.haskell.org/package/numhask-histogram) [![lts](https://www.stackage.org/package/numhask-histogram/badge/lts)](http://stackage.org/lts/package/numhask-histogram) [![nightly](https://www.stackage.org/package/numhask-histogram/badge/nightly)](http://stackage.org/nightly/package/numhask-histogram)

A histogram is a series of ranges with an annotated value attached to each range, at a squint.



