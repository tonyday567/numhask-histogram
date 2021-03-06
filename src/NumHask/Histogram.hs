{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TupleSections #-}
{-# OPTIONS_GHC -Wall #-}

module NumHask.Histogram
  ( Histogram (..),
    DealOvers (..),
    fill,
    regular,
    makeRects,
    regularQuantiles,
    quantileFold,
    fromQuantiles,
    freq,
  )
where

import qualified Control.Foldl as L
import qualified Data.List
import qualified Data.Map as Map
import Data.Maybe
import Data.TDigest
import NumHask.Space
import Prelude

-- | a Histogram is a list of contiguous boundaries (a boundary being the lower edge of one bucket and the upper edge of another), and a count for each bucket
-- Overs and Unders are counted in key=0 and key=length cut
data Histogram
  = Histogram
      { cuts :: [Double], -- bucket boundaries
        values :: Map.Map Int Double -- bucket counts
      }
  deriving (Show, Eq)

-- | whether or not to ignore unders and overs
data DealOvers = IgnoreOvers | IncludeOvers Double

-- | fill a Histogram using pre-specified cuts
-- >>> fill [0,50,100] [1..100]
-- Histogram {cuts = [0.0,50.0,100.0], values = fromList [(1,50.0),(2,50.0)]}
fill :: (Functor f, Foldable f) => [Double] -> f Double -> Histogram
fill cs xs = Histogram cs (histMap cs xs)
  where
    histMap cs' xs' =
      L.fold count $
        (\x -> L.fold countBool (fmap (x >) cs')) <$> xs'
    count = L.premap (,1.0) countW
    countBool = L.Fold (\x a -> x + if a then 1 else 0) 0 id
    countW = L.Fold (\x (a, w) -> Map.insertWith (+) a w x) Map.empty id

-- | make a histogram using n equally spaced cuts over the entire range of the data
-- >>> regular 4 [0..100]
-- Histogram {cuts = [0.0,25.0,50.0,75.0,100.0], values = fromList [(0,1.0),(1,25.0),(2,25.0),(3,25.0),(4,25.0)]}
regular :: Int -> [Double] -> Histogram
regular n xs = fill cs xs
  where
    cs = grid OuterPos (space1 xs :: Range Double) n

-- | transform a Histogram to Rects
-- >>> makeRects IgnoreOvers (regular 4 [0..100])
-- [Rect 0.0 25.0 0.0 0.25,Rect 25.0 50.0 0.0 0.25,Rect 50.0 75.0 0.0 0.25,Rect 75.0 100.0 0.0 0.25]
makeRects :: DealOvers -> Histogram -> [Rect Double]
makeRects o (Histogram cs counts) = Data.List.zipWith4 Rect x z y w'
  where
    y = repeat 0
    w =
      zipWith
        (/)
        ((\x' -> Map.findWithDefault 0 x' counts) <$> [f .. l])
        (zipWith (-) z x)
    f = case o of
      IgnoreOvers -> 1
      IncludeOvers _ -> 0
    l = case o of
      IgnoreOvers -> length cs - 1
      IncludeOvers _ -> length cs
    w' = (/ sum w) <$> w
    x = case o of
      IgnoreOvers -> cs
      IncludeOvers outw ->
        [Data.List.head cs - outw]
          <> cs
          <> [Data.List.last cs + outw]
    z = drop 1 x

-- | approx regular n-quantiles
-- >>> regularQuantiles 4 [0..100]
-- [0.0,24.75,50.0,75.25,100.0]
regularQuantiles :: Double -> [Double] -> [Double]
regularQuantiles n = L.fold (quantileFold qs)
  where
    qs = ((1 / n) *) <$> [0 .. n]

-- | one-pass approximate quantiles fold
quantileFold :: [Double] -> L.Fold Double [Double]
quantileFold qs = L.Fold step begin done
  where
    step x a = Data.TDigest.insert a x
    begin = tdigest ([] :: [Double]) :: TDigest 25
    done x = fromMaybe (0 / 0) . (`quantile` compress x) <$> qs

-- | take a specification of quantiles and make a Histogram
-- >>> fromQuantiles [0,0.25,0.5,0.75,1] (regularQuantiles 4 [0..100])
-- Histogram {cuts = [0.0,24.75,50.0,75.25,100.0], values = fromList [(1,0.25),(2,0.25),(3,0.25),(4,0.25)]}
fromQuantiles :: [Double] -> [Double] -> Histogram
fromQuantiles qs xs = Histogram xs (Map.fromList $ zip [1 ..] (diffq qs))
  where
    diffq [] = []
    diffq [_] = []
    diffq (x : xs') = L.fold (L.Fold step (x, []) (reverse . snd)) xs'
    step (a0, xs') a = (a, (a - a0) : xs')

-- | normalize a histogram so that sum values = one
-- >>> freq $ fill [0,50,100] [1..100]
-- Histogram {cuts = [0.0,50.0,100.0], values = fromList [(1,0.5),(2,0.5)]}
freq :: Histogram -> Histogram
freq (Histogram cs vs) = Histogram cs $ Map.map (* recip (sum vs)) vs
