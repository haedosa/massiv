{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE FlexibleContexts #-}
{-# OPTIONS_GHC -fno-warn-duplicate-exports #-}
-- |
-- Module      : Data.Massiv.Vector
-- Copyright   : (c) Alexey Kuleshevich 2020
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Data.Massiv.Vector
  ( Vector
  , MVector
  -- * Accessors
  -- *** Size
  , slength
  , maxSize
  , size
  , snull
  -- *** Indexing
  , (!)
  , (!?)
  , head'
  , shead'
  , last'
  -- *** Monadic Indexing
  , indexM
  , headM
  , sheadM
  , lastM
  -- ** Slicing
  , slice
  , slice'
  , sliceM
  , sslice
  , sliceAt
  , sliceAt'
  , sliceAtM
  -- *** Init
  , init
  , init'
  , initM
  -- *** Tail
  , tail
  , tail'
  , tailM
  -- *** Take
  , take
  , take'
  , takeM
  , stake
  -- *** Drop
  , drop
  , drop'
  , dropM
  , sdrop
  -- * Construction
  -- ** Initialization
  , empty
  , sempty
  , singleton
  , ssingleton
  , A.replicate
  , sreplicate
  , generate
  , sgenerate
  -- , iterateN
  -- , iiterateN
  , siterateN
  -- ** Monadic initialization
  , sreplicateM
  , sgenerateM
  , siterateNM
  -- , create
  -- , createT
  -- ** Unfolding
  , sunfoldr
  , sunfoldrM
  , sunfoldrN
  , sunfoldrNM
  , sunfoldrExactN
  , sunfoldrExactNM
  -- , constructN
  -- , constructrN
  -- ** Enumeration
  , (...)
  , (..:)
  , senumFromN
  , senumFromStepN
  -- ** Concatenation
  -- , consS -- cons
  -- , snocS -- snoc
  , sappend  -- (++)
  , sconcat -- concat
  -- -- ** Restricitng memory usage
  -- , force
  -- -- * Modifying
  -- -- ** Bulk updates
  -- , (//)
  -- , update_
  -- -- ** Accumulations
  -- , accum
  -- , accumulate_
  -- -- ** Permutations
  -- , reverse
  -- , backpermute
  -- -- ** Mutable updates
  -- , modify
  -- -- * Elementwise
  -- -- ** Mapping
  , smap
  , simap
  -- , sconcatMap
  -- ** Monadic mapping
  , straverse
  , sitraverse
  , smapM
  , smapM_
  , simapM
  , simapM_
  , sforM
  , sforM_
  , siforM
  , siforM_
  -- ** Zipping
  , szip
  , szip3
  , szip4
  , szip5
  , szip6
  , szipWith
  , szipWith3
  , szipWith4
  , szipWith5
  , szipWith6
  , sizipWith
  , sizipWith3
  , sizipWith4
  , sizipWith5
  , sizipWith6
  -- ** Monadic zipping
  , szipWithM
  , szipWith3M
  , szipWith4M
  , szipWith5M
  , szipWith6M
  , sizipWithM
  , sizipWith3M
  , sizipWith4M
  , sizipWith5M
  , sizipWith6M

  , szipWithM_
  , szipWith3M_
  , szipWith4M_
  , szipWith5M_
  , szipWith6M_
  , sizipWithM_
  , sizipWith3M_
  , sizipWith4M_
  , sizipWith5M_
  , sizipWith6M_
  -- * Predicates
  -- ** Filtering
  , sfilter
  , sifilter
  , sfilterM
  , sifilterM
  -- , uniq -- sunique?
  , smapMaybe
  , smapMaybeM
  , scatMaybes
  , simapMaybe
  , simapMaybeM
  -- , takeWhile
  -- , dropWhile
  -- -- ** Partitioning
  -- , partition
  -- , unstablePartition
  -- , partitionWith
  -- , span
  -- , break
  -- -- ** Searching
  -- , elem
  -- , notElem
  -- , find
  -- , findIndex
  -- , findIndices
  -- , elemIndex
  -- , elemIndices
  -- * Folding
  , sfoldl
  , sfoldlM
  , sfoldlM_
  , sifoldl
  , sifoldlM
  , sifoldlM_
  , sfoldl1'
  , sfoldl1M
  , sfoldl1M_
  -- ** Specialized folds
  , sor
  , sand
  , sall
  , sany
  , ssum
  , sproduct
  , smaximum'
  , smaximumM
  -- , maximumBy
  , sminimum'
  , sminimumM
  -- , minimumBy
  -- , minIndex
  -- , minIndexBy
  -- , maxIndex
  -- , maxIndexBy
  -- -- ** Prefix sums
  -- , prescanl
  -- , prescanl'
  -- , postscanl
  -- , postscanl'
  -- , scanl
  -- , scanl'
  -- , scanl1
  -- , scanl1'
  -- , prescanr
  -- , prescanr'
  -- , postscanr
  -- , postscanr'
  -- , scanr
  -- , scanr'
  -- , scanr1
  -- , scanr1'
  -- * Conversions
  -- ** Lists
  , stoList
  , fromList
  , sfromList
  , sfromListN
  -- -- ** Other vector types
  -- , convert
  -- -- ** Mutable vectors
  -- , freeze
  -- , thaw
  -- , copy
  -- , unsafeFreeze
  -- , unsafeThaw
  -- , unsafeCopy
  -- * Deprecated
  , takeS
  , dropS
  , unfoldr
  , unfoldrN
  , filterS
  , ifilterS
  , filterM
  , ifilterM
  , mapMaybeS
  , imapMaybeS
  , mapMaybeM
  , imapMaybeM
  , catMaybesS
  , traverseS
  -- ** Re-exports
  , module Data.Massiv.Core
  , module Data.Massiv.Array.Delayed
  , module Data.Massiv.Array.Manifest
  , module Data.Massiv.Array.Mutable
  ) where

import Control.Monad hiding (filterM, replicateM)
import Data.Coerce
import Data.Massiv.Array.Delayed
import Data.Massiv.Array.Delayed.Pull
import Data.Massiv.Array.Delayed.Stream
import Data.Massiv.Array.Ops.Construct
import Data.Massiv.Array.Manifest
import Data.Massiv.Array.Manifest.List (fromList)
import Data.Massiv.Array.Mutable
import qualified Data.Massiv.Array.Ops.Construct as A (makeArrayR, replicate)
import Data.Massiv.Core
import Data.Massiv.Core.Common
import qualified Data.Massiv.Vector.Stream as S
import Data.Massiv.Vector.Unsafe
import Prelude hiding (drop, init, length, null, replicate, splitAt, tail, take)

-- ========= --
-- Accessors --
-- ========= --


------------------------
-- Length information --
------------------------

-- | /O(1)/ - Get the length of a stream vector, but only if it is known exactly.
--
-- There are also `size` and `sizeMax`. Calling `size` will always give you the exact size
-- instead, but for `DS` representation it could result in evaluation of the whole
-- stream, similar to how `Data.List.length` on lists works.
--
-- ==== __Examples__
--
-- >>> slength $ sunfoldr (\x -> Just (x, x)) (0 :: Int)
-- Nothing
-- >>> slength $ sunfoldrN 10 (\x -> Just (x, x)) (0 :: Int)
-- Nothing
-- >>> slength $ sunfoldrExactN 10 (\x -> (x, x)) (0 :: Int)
-- Just (Sz1 10)
--
-- @since 0.5.0
slength :: Stream r ix e => Array r ix e -> Maybe Sz1
slength v =
  case stepsSize (toStream v) of
    Exact sz -> Just (SafeSz sz)
    _        -> Nothing
{-# INLINE slength #-}

-- | /O(1)/ - Check if a stream array is empty or not. It only looks at the exact size
-- (i.e. `slength`), if it is available, otherwise checks if there is at least one element
-- in a stream.
--
-- ==== __Examples__
--
-- >>> snull sempty
-- True
-- >>> snull (empty :: Array D Ix5 Int)
-- True
-- >>> snull $ ssingleton "A Vector with a single String element"
-- False
-- >>> snull $ sfromList []
-- True
-- >>> snull $ sfromList [1 :: Int ..]
-- False
--
-- @since 0.5.0
snull :: Stream r ix e => Array r ix e -> Bool
snull = S.unId . S.null . toStream
{-# INLINE snull #-}

--------------
-- Indexing --
--------------

-- TODO: Add to vector: headMaybe

-- | Get the first element of a `Source` vector. Throws an error on empty.
--
-- ==== __Examples__
--
-- >>> head' (Ix1 10 ..: 10000000000000)
-- 10
-- >>> head' (Ix1 10 ..: 10)
-- *** Exception: SizeEmptyException: (Sz1 0) corresponds to an empty array
--
-- @since 0.5.0
head' :: Source r Ix1 e => Vector r e -> e
head' = either throw id . headM
{-# INLINE head' #-}


-- | Get the first element of a `Source` vector. Throws an error on empty.
--
-- ==== __Examples__
--
-- >>> headM (Ix1 10 ..: 10000000000000)
-- 10
-- >>> headM (Ix1 10 ..: 10000000000000) :: Maybe Int
-- Just 10
-- >>> headM (empty :: Array D Ix1 Int) :: Maybe Int
-- Nothing
-- >>> either show (const "") $ headM (Ix1 10 ..: 10)
-- "SizeEmptyException: (Sz1 0) corresponds to an empty array"
--
-- @since 0.5.0
headM :: (Source r Ix1 e, MonadThrow m) => Vector r e -> m e
headM v
  | isEmpty v = throwM $ SizeEmptyException (size v)
  | otherwise = pure $ unsafeLinearIndex v 0
{-# INLINE headM #-}


-- | Get the first element of a `Stream` vector. Throws an error on empty.
--
-- ==== __Examples__
--
-- >>> shead' $ sunfoldr (\x -> Just (x, x)) (0 :: Int)
-- 0
-- >>> x = shead' $ sunfoldr (\_ -> Nothing) (0 :: Int)
-- >>> print x
-- *** Exception: SizeEmptyException: (Sz1 0) corresponds to an empty array
--
-- @since 0.5.0
shead' :: Stream r Ix1 e => Vector r e -> e
shead' = either throw id . sheadM
{-# INLINE shead' #-}

-- | Get the first element of a `Stream` vector. Throws an error on empty.
--
-- ==== __Examples__
--
-- >>> sheadM $ sunfoldr (\x -> Just (x, x)) (0 :: Int)
-- 0
-- >>> x <- sheadM $ sunfoldr (\_ -> Nothing) (0 :: Int)
-- *** Exception: SizeEmptyException: (Sz1 0) corresponds to an empty array
--
-- @since 0.5.0
sheadM :: (Stream r Ix1 e, MonadThrow m) => Vector r e -> m e
sheadM v =
  case S.unId (S.headMaybe (toStream v)) of
    Nothing -> throwM $ SizeEmptyException (size v)
    Just e  -> pure e
{-# INLINE sheadM #-}

-- | Get the last element of a `Source` vector. Throws an error on empty.
--
-- ==== __Examples__
--
-- >>> last' (Ix1 10 ... 10000000000000)
-- 10000000000000
-- >>> last' (fromList Seq [] :: Array P Ix1 Int)
-- *** Exception: SizeEmptyException: (Sz1 0) corresponds to an empty array
--
-- @since 0.5.0
last' :: Source r Ix1 e => Vector r e -> e
last' = either throw id . lastM
{-# INLINE last' #-}


-- | Get the last element of a `Source` vector. Throws an error on empty.
--
-- ==== __Examples__
--
-- >>> lastM (Ix1 10 ... 10000000000000)
-- 10000000000000
-- >>> lastM (Ix1 10 ... 10000000000000) :: Maybe Int
-- Just 10000000000000
-- >>> either show (const "") $ lastM (fromList Seq [] :: Array P Ix1 Int)
-- "SizeEmptyException: (Sz1 0) corresponds to an empty array"
--
-- @since 0.5.0
lastM :: (Source r Ix1 e, MonadThrow m) => Vector r e -> m e
lastM v
  | k == 0 = throwM $ SizeEmptyException (size v)
  | otherwise = pure $ unsafeLinearIndex v (k - 1)
  where k = unSz (size v)
{-# INLINE lastM #-}


-- | /O(1)/ - Take a slice of a `Source` vector. Never fails, instead adjusts the indices.
--
-- ==== __Examples__
--
-- >>> slice 10 5 (Ix1 0 ... 10000000000000)
-- Array D Seq (Sz1 5)
--   [ 10, 11, 12, 13, 14 ]
-- >>> slice (-10) 5 (Ix1 0 ... 10000000000000)
-- Array D Seq (Sz1 5)
--   [ 0, 1, 2, 3, 4 ]
-- >>> slice 9999999999998 50 (Ix1 0 ... 10000000000000)
-- Array D Seq (Sz1 3)
--   [ 9999999999998, 9999999999999, 10000000000000 ]
--
-- @since 0.5.0
slice :: Source r Ix1 e => Ix1 -> Sz1 -> Vector r e -> Vector r e
slice !i (Sz k) v = unsafeLinearSlice i' newSz v
  where
    !i' = min n (max 0 i)
    !newSz = SafeSz (min (n - i') k)
    Sz n = size v
{-# INLINE slice #-}

-- | /O(1)/ - Take a slice of a `Source` vector. Throws an error on incorrect indices.
--
-- ==== __Examples__
--
-- >>> slice' 10 5 (Ix1 0 ... 100)
-- Array D Seq (Sz1 5)
--   [ 10, 11, 12, 13, 14 ]
-- >>> slice' (-10) 5 (Ix1 0 ... 100)
-- Array D *** Exception: SizeSubregionException: (Sz1 101) is to small for -10 (Sz1 5)
-- >>> slice' 98 50 (Ix1 0 ... 100)
-- Array D *** Exception: SizeSubregionException: (Sz1 101) is to small for 98 (Sz1 50)
-- >>> slice' 9999999999998 50 (Ix1 0 ... 10000000000000)
-- Array D *** Exception: SizeSubregionException: (Sz1 10000000000001) is to small for 9999999999998 (Sz1 50)
-- >>> slice' 9999999999998 3 (Ix1 0 ... 10000000000000)
-- Array D Seq (Sz1 3)
--   [ 9999999999998, 9999999999999, 10000000000000 ]
--
-- @since 0.5.0
slice' :: Source r Ix1 e => Ix1 -> Sz1 -> Vector r e -> Vector r e
slice' i k = either throw id . sliceM i k
{-# INLINE slice' #-}


-- | /O(1)/ - Take a slice of a `Source` vector. Throws an error on incorrect indices.
--
-- ==== __Examples__
--
-- @since 0.5.0
sliceM :: (Source r Ix1 e, MonadThrow m) => Ix1 -> Sz1 -> Vector r e -> m (Vector r e)
sliceM i newSz@(Sz k) v
  | i >= 0 && k <= n - i = pure $ unsafeLinearSlice i newSz v
  | otherwise = throwM $ SizeSubregionException sz i newSz
  where
    sz@(Sz n) = size v
{-# INLINE sliceM #-}


-- | Take a slice of a `Stream` vector. Never fails, instead adjusts the indices.
--
-- Unlike `slice` it has to iterate through element until the staring index is reached,
-- therefore something like @sslice 9999999999998 50 (Ix1 0 ... 10000000000000)@ will not
-- be feasable.
--
-- ==== __Examples__
--
-- >>> sslice 10 5 (Ix1 0 ... 10000000000000)
-- Array DS Seq (Sz1 5)
--   [ 10, 11, 12, 13, 14 ]
-- >>> sslice 10 5 (sfromList [0 :: Int .. ])
-- Array DS Seq (Sz1 5)
--   [ 10, 11, 12, 13, 14 ]
-- >>> sslice (-10) 5 (Ix1 0 ... 10000000000000)
-- Array DS Seq (Sz1 5)
--   [ 0, 1, 2, 3, 4 ]
--
-- @since 0.5.0
sslice :: Stream r Ix1 e => Ix1 -> Sz1 -> Vector r e -> Vector DS e
sslice !i (Sz k) = fromSteps . S.slice i k . S.toStream
{-# INLINE sslice #-}


-- | /O(1)/ - Get a vector without the last element. Never fails.
--
-- ==== __Examples__
--
-- >>> init (0 ..: 10)
-- Array D Seq (Sz1 9)
--   [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ]
-- >>> init (empty :: Array D Ix1 Int)
-- Array D Seq (Sz1 0)
--   [  ]
--
-- @since 0.5.0
init :: Source r Ix1 e => Vector r e -> Vector r e
init v = unsafeLinearSlice 0 (Sz (coerce (size v) - 1)) v
{-# INLINE init #-}

-- | /O(1)/ - Get a vector without the last element. Throws an error on empty
--
-- ==== __Examples__
--
-- >>> init' (0 ..: 10)
-- Array D Seq (Sz1 9)
--   [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ]
-- >>> init' (empty :: Array D Ix1 Int)
-- Array D *** Exception: SizeEmptyException: (Sz1 0) corresponds to an empty array
--
-- @since 0.5.0
init' :: Source r Ix1 e => Vector r e -> Vector r e
init' = either throw id . initM
{-# INLINE init' #-}

-- | /O(1)/ - Get a vector without the last element. Throws an error on empty
--
-- ==== __Examples__
--
-- >>> initM (0 ..: 10)
-- Array D Seq (Sz1 9)
--   [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ]
-- >>> maybe 0 sum $ initM (0 ..: 10)
-- 36
-- >>> maybe 0 sum $ initM (empty :: Array D Ix1 Int)
-- 0
--
-- @since 0.5.0
initM :: (Source r Ix1 e, MonadThrow m) => Vector r e -> m (Vector r e)
initM v = do
  when (isEmpty v) $ throwM $ SizeEmptyException $ size v
  pure $ unsafeInit v
{-# INLINE initM #-}



-- | /O(1)/ - Get a vector without the first element. Never fails
--
-- ==== __Examples__
--
-- >>> tail (0 ..: 10)
-- Array D Seq (Sz1 9)
--   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
-- >>> tail (empty :: Array D Ix1 Int)
-- Array D Seq (Sz1 0)
--   [  ]
--
-- @since 0.5.0
tail :: Source r Ix1 e => Vector r e -> Vector r e
tail = drop 1
{-# INLINE tail #-}


-- | /O(1)/ - Get a vector without the first element. Throws an error on empty
--
-- ==== __Examples__
--
-- λ> tail' (0 ..: 10)
-- Array D Seq (Sz1 9)
--   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
-- λ> tail' (empty :: Array D Ix1 Int)
-- Array D *** Exception: SizeEmptyException: (Sz1 0) corresponds to an empty array
--
-- @since 0.5.0
tail' :: Source r Ix1 e => Vector r e -> Vector r e
tail' = either throw id . tailM
{-# INLINE tail' #-}


-- | /O(1)/ - Get the vector without the first element. Throws an error on empty
--
-- ==== __Examples__
--
-- >>> tailM (0 ..: 10)
-- Array D Seq (Sz1 9)
--   [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
-- >>> maybe 0 sum $ tailM (0 ..: 10)
-- 45
-- >>> maybe 0 sum $ tailM (empty :: Array D Ix1 Int)
-- 0
--
-- @since 0.5.0
tailM :: (Source r Ix1 e, MonadThrow m) => Vector r e -> m (Vector r e)
tailM v = do
  when (isEmpty v) $ throwM $ SizeEmptyException $ size v
  pure $ unsafeTail v
{-# INLINE tailM #-}



-- | /O(1)/ - Get the vector with the first @n@ elements. Never fails
--
-- ==== __Examples__
--
-- >>> take 5 (0 ..: 10)
-- Array D Seq (Sz1 5)
--   [ 0, 1, 2, 3, 4 ]
-- >>> take (-5) (0 ..: 10)
-- Array D Seq (Sz1 0)
--   [  ]
-- >>> take 100 (0 ..: 10)
-- Array D Seq (Sz1 10)
--   [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
-- >>>
--
-- @since 0.5.0
take :: Source r Ix1 e => Sz1 -> Vector r e -> Vector r e
take k = fst . sliceAt k
{-# INLINE take #-}

-- | /O(1)/ - Get the vector with the first @n@ elements. Throws an error size is less
-- than @n@.
--
-- ==== __Examples__
--
-- >>> take' 0 (0 ..: 0)
-- Array D Seq (Sz1 0)
--   [  ]
-- >>> take' 5 (0 ..: 10)
-- Array D Seq (Sz1 5)
--   [ 0, 1, 2, 3, 4 ]
-- >>> take' 15 (0 ..: 10)
-- Array D *** Exception: SizeSubregionException: (Sz1 10) is to small for 0 (Sz1 15)
--
-- @since 0.5.0
take' :: Source r Ix1 e => Sz1 -> Vector r e -> Vector r e
take' k = either throw id . takeM k
{-# INLINE take' #-}

-- | /O(1)/ - Get the vector with the first @n@ elements. Throws an error size is less than @n@
--
-- ==== __Examples__
--
-- >>> takeM 5 (0 ..: 10)
-- Array D Seq (Sz1 5)
--   [ 0, 1, 2, 3, 4 ]
-- >>> maybe 0 sum $ takeM 5 (0 ..: 10)
-- 10
-- >>> maybe (-1) sum $ takeM 15 (0 ..: 10)
-- -1
--
-- @since 0.5.0
takeM :: (Source r Ix1 e, MonadThrow m) => Sz1 -> Vector r e -> m (Vector r e)
takeM k v = do
  let sz = size v
  when (k > sz) $ throwM $ SizeSubregionException sz 0 k
  pure $ unsafeTake k v
{-# INLINE takeM #-}

-- | /O(1)/ - Get a `Stream` vector with the first @n@ elements. Never fails
--
-- ==== __Examples__
--
-- @since 0.5.0
stake :: Stream r Ix1 e => Sz1 -> Vector r e -> Vector DS e
stake n = fromSteps . S.take (unSz n) . S.toStream
{-# INLINE stake #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
drop :: Source r Ix1 e => Sz1 -> Vector r e -> Vector r e
drop k = snd . sliceAt k
{-# INLINE drop #-}

-- | Keep all but the first @n@ elements from the delayed stream vector.
--
-- ==== __Examples__
--
-- @since 0.5.0
sdrop :: Stream r Ix1 e => Sz1 -> Vector r e -> Vector DS e
sdrop n = fromSteps . S.drop (unSz n) . S.toStream
{-# INLINE sdrop #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
drop' :: Source r Ix1 e => Sz1 -> Vector r e -> Vector r e
drop' k = either throw id . dropM k
{-# INLINE drop' #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
dropM :: (Source r Ix1 e, MonadThrow m) => Sz1 -> Vector r e -> m (Vector r e)
dropM k@(Sz d) v = do
  let sz@(Sz n) = size v
  when (k > sz) $ throwM $ SizeSubregionException sz d (sz - k)
  pure $ unsafeLinearSlice d (SafeSz (n - d)) v
{-# INLINE dropM #-}


-- | Samel as `sliceAt`, except it never fails.
--
--
-- ==== __Examples__
--
-- @since 0.5.0
sliceAt :: Source r Ix1 e => Sz1 -> Vector r e -> (Vector r e, Vector r e)
sliceAt (Sz k) v = (unsafeTake d v, unsafeDrop d v)
  where
    !n = coerce (size v)
    !d = SafeSz (min k n)
{-# INLINE sliceAt #-}

-- | Same as `Data.Massiv.Array.splitAt'`, except for a flat vector.
--
-- ==== __Examples__
--
-- @since 0.5.0
sliceAt' :: Source r Ix1 e => Sz1 -> Vector r e -> (Vector r e, Vector r e)
sliceAt' k = either throw id . sliceAtM k
{-# INLINE sliceAt' #-}

-- | Same as `Data.Massiv.Array.splitAtM`, except for a flat vector.
--
-- ==== __Examples__
--
-- @since 0.5.0
sliceAtM :: (Source r Ix1 e, MonadThrow m) => Sz1 -> Vector r e -> m (Vector r e, Vector r e)
sliceAtM k v = do
  l <- takeM k v
  pure (l, unsafeDrop k v)
{-# INLINE sliceAtM #-}


-- | Create an empty delayed stream vector
--
-- ==== __Examples__
--
-- @since 0.5.0
sempty :: Vector DS e
sempty = DSArray S.empty
{-# INLINE sempty #-}

-- | Create a delayed stream vector with a single element
--
-- ==== __Examples__
--
-- @since 0.5.0
ssingleton :: e -> Vector DS e
ssingleton = DSArray . S.singleton
{-# INLINE ssingleton #-}

-- | Replicate the same element @n@ times
--
-- ==== __Examples__
--
-- @since 0.5.0
sreplicate :: Sz1 -> e -> Vector DS e
sreplicate (Sz n) = DSArray . S.replicate n
{-# INLINE sreplicate #-}

-- | Create a delayed vector of length @n@ with a function that maps an index to an
-- element. Same as `makeLinearArray`
--
-- ==== __Examples__
--
-- @since 0.5.0
generate :: Comp -> Sz1 -> (Ix1 -> e) -> Vector D e
generate = makeArrayLinear
{-# INLINE generate #-}

-- | Create a delayed stream vector of length @n@ with a function that maps an index to an
-- element. Same as `makeLinearArray`
--
-- ==== __Examples__
--
-- @since 0.5.0
sgenerate :: Sz1 -> (Ix1 -> e) -> Vector DS e
sgenerate (Sz n) = DSArray . S.generate n
{-# INLINE sgenerate #-}


-- | Create a delayed stream vector of length @n@ by repeatedly apply a function to the
-- initial value.
--
-- ==== __Examples__
--
-- @since 0.5.0
siterateN :: Sz1 -> (e -> e) -> e -> Vector DS e
siterateN n f a = fromSteps $ S.iterateN (unSz n) f a
{-# INLINE siterateN #-}


-- | Create a vector by using the same monadic action @n@ times
--
-- ==== __Examples__
--
-- @since 0.5.0
sreplicateM :: Monad m => Sz1 -> m e -> m (Vector DS e)
sreplicateM n f = fromStepsM $ S.replicateM (unSz n) f
{-# INLINE sreplicateM #-}


-- | Create a delayed stream vector of length @n@ with a monadic action that from an index
-- generates an element.
--
-- ==== __Examples__
--
-- @since 0.5.0
sgenerateM :: Monad m => Sz1 -> (Ix1 -> m e) -> m (Vector DS e)
sgenerateM n f = fromStepsM $ S.generateM (unSz n) f
{-# INLINE sgenerateM #-}


-- | Create a delayed stream vector of length @n@ by repeatedly apply a monadic action to
-- the initial value.
--
-- ==== __Examples__
--
-- @since 0.5.0
siterateNM :: Monad m => Sz1 -> (e -> m e) -> e -> m (Vector DS e)
siterateNM n f a = fromStepsM $ S.iterateNM (unSz n) f a
{-# INLINE siterateNM #-}




-- | Right unfolding function. Useful when it is unknown ahead of time on how many
-- elements the vector will have.
--
-- ====__Example__
--
-- >>> import Data.Massiv.Array as A
-- >>> sunfoldr (\i -> if i < 9 then Just (i * i, i + 1) else Nothing) (0 :: Int)
-- Array DS Seq (Sz1 9)
--   [ 0, 1, 4, 9, 16, 25, 36, 49, 64 ]
--
-- @since 0.5.0
sunfoldr :: (s -> Maybe (e, s)) -> s -> Vector DS e
sunfoldr f = DSArray . S.unfoldr f
{-# INLINE sunfoldr #-}



-- | /O(n)/ - Right unfolding function with at most @n@ number of elements.
--
-- ==== __Example__
--
-- >>> import Data.Massiv.Array as A
-- >>> sunfoldrN 9 (\i -> Just (i*i, i + 1)) (0 :: Int)
-- Array DS Seq (Sz1 9)
--   [ 0, 1, 4, 9, 16, 25, 36, 49, 64 ]
--
-- @since 0.5.0
sunfoldrN ::
     Sz1
  -- ^ @n@ - maximum number of elements that the vector will have
  -> (s -> Maybe (e, s))
  -- ^ Unfolding function. Stops when `Nothing` is returned or maximum number of elements
  -- is reached.
  -> s -- ^ Inititial element.
  -> Vector DS e
sunfoldrN (Sz n) f = DSArray . S.unfoldrN n f
{-# INLINE sunfoldrN #-}

-- | Same as `unfoldr`, by with monadic generating function.
--
-- ==== __Examples__
--
-- @since 0.5.0
sunfoldrM :: Monad m => (s -> m (Maybe (e, s))) -> s -> m (Vector DS e)
sunfoldrM f = fromStepsM . S.unfoldrM f
{-# INLINE sunfoldrM #-}

-- | Same as `unfoldrN`, by with monadic generating function.
--
-- ==== __Examples__
--
-- @since 0.5.0
sunfoldrNM :: Monad m => Sz1 -> (s -> m (Maybe (e, s))) -> s -> m (Vector DS e)
sunfoldrNM (Sz n) f = fromStepsM . S.unfoldrNM n f
{-# INLINE sunfoldrNM #-}


-- | Similar to `unfoldrN`, except the length of the resulting vector will be exactly @n@
--
-- ==== __Examples__
--
-- @since 0.5.0
sunfoldrExactN :: Sz1 -> (s -> (e, s)) -> s -> Vector DS e
sunfoldrExactN (Sz n) f = fromSteps . S.unfoldrExactN n f
{-# INLINE sunfoldrExactN #-}

-- | Similar to `unfoldrNM`, except the length of the resulting vector will be exactly @n@
--
-- ==== __Examples__
--
-- @since 0.5.0
sunfoldrExactNM :: Monad m => Sz1 -> (s -> m (e, s)) -> s -> m (Vector DS e)
sunfoldrExactNM (Sz n) f = fromStepsM . S.unfoldrExactNM n f
{-# INLINE sunfoldrExactNM #-}


-- | Enumerate from a starting number @n@ times with a step @1@
--
-- ==== __Examples__
--
-- @since 0.5.0
senumFromN :: Num e => e -> Sz1 -> Vector DS e
senumFromN x (Sz n) = DSArray $ S.enumFromStepN x 1 n
{-# INLINE senumFromN #-}

-- | Enumerate from a starting number @n@ times with a custom step value
--
-- ==== __Examples__
--
-- @since 0.5.0
senumFromStepN ::
     Num e
  => e -- ^ Starting value
  -> e -- ^ Step
  -> Sz1 -- ^ Resulting length of a vector
  -> Vector DS e
senumFromStepN x step (Sz n) = DSArray $ S.enumFromStepN x step n
{-# INLINE senumFromStepN #-}



-- | Append two vectors together
--
-- ==== __Examples__
--
-- @since 0.5.0
sappend :: (Stream r1 Ix1 e, Stream r2 Ix1 e) => Vector r1 e -> Vector r2 e -> Vector DS e
sappend a1 a2 = fromSteps (toStream a1 `S.append` toStream a2)
{-# INLINE sappend #-}


-- | Concat vectors together
--
-- ==== __Examples__
--
-- @since 0.5.0
sconcat :: Stream r Ix1 e => [Vector r e] -> Vector DS e
sconcat = DSArray . foldMap toStream
{-# INLINE sconcat #-}

-- | Convert a list to a delayed stream vector
--
-- ==== __Examples__
--
-- >>> sfromList ([] :: [Int])
-- Array DS Seq (Sz1 0)
--   [  ]
-- >>> sfromList ([1,2,3] :: [Int])
-- Array DS Seq (Sz1 3)
--   [ 1, 2, 3 ]
--
-- @since 0.5.0
sfromList :: [e] -> Vector DS e
sfromList = fromSteps . S.fromList
{-# INLINE sfromList #-}

-- | Convert a list of a known length to a delayed stream vector
--
-- ==== __Examples__
--
-- @since 0.5.0
sfromListN :: Sz1 -> [e] -> Vector DS e
sfromListN (Sz n) = fromSteps . S.fromListN n
{-# INLINE sfromListN #-}

-- | Convert an array to a list by the means of a delayed stream vector.
--
-- ==== __Examples__
--
-- @since 0.5.0
stoList :: Stream r ix e => Array r ix e -> [e]
stoList = S.toList . toStream
{-# INLINE stoList #-}






-- | Sequentially filter out elements from the array according to the supplied predicate.
--
-- ==== __Example__
--
-- >>> import Data.Massiv.Array as A
-- >>> arr = makeArrayR D Seq (Sz2 3 4) fromIx2
-- >>> arr
-- Array D Seq (Sz (3 :. 4))
--   [ [ (0,0), (0,1), (0,2), (0,3) ]
--   , [ (1,0), (1,1), (1,2), (1,3) ]
--   , [ (2,0), (2,1), (2,2), (2,3) ]
--   ]
-- >>> sfilter (even . fst) arr
-- Array DS Seq (Sz1 8)
--   [ (0,0), (0,1), (0,2), (0,3), (2,0), (2,1), (2,2), (2,3) ]
--
-- @since 0.5.0
sfilter :: S.Stream r ix e => (e -> Bool) -> Array r ix e -> Vector DS e
sfilter f = DSArray . S.filter f . S.toStream
{-# INLINE sfilter #-}


-- | Similar to `sfilter`, but map with an index aware function.
--
-- ==== __Examples__
--
-- @since 0.5.0
sifilter :: Stream r ix a => (ix -> a -> Bool) -> Array r ix a -> Vector DS a
sifilter f =
  simapMaybe $ \ix e ->
    if f ix e
      then Just e
      else Nothing
{-# INLINE sifilter #-}


-- | Sequentially filter out elements from the array according to the supplied applicative predicate.
--
-- ==== __Example__
--
-- >>> import Data.Massiv.Array as A
-- >>> arr = makeArrayR D Seq (Sz2 3 4) fromIx2
-- >>> arr
-- Array D Seq (Sz (3 :. 4))
--   [ [ (0,0), (0,1), (0,2), (0,3) ]
--   , [ (1,0), (1,1), (1,2), (1,3) ]
--   , [ (2,0), (2,1), (2,2), (2,3) ]
--   ]
-- >>> sfilterM (Just . odd . fst) arr
-- Just (Array DS Seq (Sz1 4)
--   [ (1,0), (1,1), (1,2), (1,3) ]
-- )
-- >>> sfilterM (\ix@(_, j) -> print ix >> return (even j)) arr
-- (0,0)
-- (0,1)
-- (0,2)
-- (0,3)
-- (1,0)
-- (1,1)
-- (1,2)
-- (1,3)
-- (2,0)
-- (2,1)
-- (2,2)
-- (2,3)
-- Array DS Seq (Sz1 6)
--   [ (0,0), (0,2), (1,0), (1,2), (2,0), (2,2) ]
--
-- @since 0.5.0
sfilterM :: (S.Stream r ix e, Applicative f) => (e -> f Bool) -> Array r ix e -> f (Vector DS e)
sfilterM f arr = DSArray <$> S.filterA f (S.toStream arr)
{-# INLINE sfilterM #-}


-- | Similar to `filterM`, but map with an index aware function.
--
-- Corresponds to: @filterM (uncurry f) . imap (,)@
--
-- ==== __Examples__
--
-- @since 0.5.0
sifilterM ::
     (Stream r ix a, Applicative f) => (ix -> a -> f Bool) -> Array r ix a -> f (Vector DS a)
sifilterM f =
  simapMaybeM $ \ix e ->
    (\p ->
       if p
         then Just e
         else Nothing) <$>
    f ix e
{-# INLINE sifilterM #-}


-- | Apply a function to each element of the array, while discarding `Nothing` and
-- keeping the `Maybe` result.
--
-- ==== __Examples__
--
-- @since 0.5.0
smapMaybe :: S.Stream r ix a => (a -> Maybe b) -> Array r ix a -> Vector DS b
smapMaybe f = DSArray . S.mapMaybe f . S.toStream
{-# INLINE smapMaybe #-}


-- | Similar to `smapMaybe`, but map with an index aware function.
--
-- ==== __Examples__
--
-- @since 0.5.0
simapMaybe :: Stream r ix a => (ix -> a -> Maybe b) -> Array r ix a -> Vector DS b
simapMaybe f = DSArray . S.mapMaybe (uncurry f) . toStreamIx
{-# INLINE simapMaybe #-}

-- | Similar to `smapMaybeM`, but map with an index aware function.
--
-- ==== __Examples__
--
-- @since 0.5.0
simapMaybeM ::
     (Stream r ix a, Applicative f) => (ix -> a -> f (Maybe b)) -> Array r ix a -> f (Vector DS b)
simapMaybeM f = fmap DSArray . S.mapMaybeA (uncurry f) . toStreamIx
{-# INLINE simapMaybeM #-}


-- | Keep all `Maybe`s and discard the `Nothing`s.
--
-- ==== __Examples__
--
-- @since 0.5.0
scatMaybes :: S.Stream r ix (Maybe a) => Array r ix (Maybe a) -> Vector DS a
scatMaybes = smapMaybe id
{-# INLINE scatMaybes #-}


-- | Similar to `smapMaybe`, but with the `Applicative` function.
--
-- Similar to @mapMaybe id <$> mapM f arr@
--
-- ==== __Examples__
--
-- @since 0.5.0
smapMaybeM ::
     (S.Stream r ix a, Applicative f) => (a -> f (Maybe b)) -> Array r ix a -> f (Vector DS b)
smapMaybeM f = fmap DSArray . S.mapMaybeA f . S.toStream
{-# INLINE smapMaybeM #-}



-- | Map a function over a stream vector
--
-- ==== __Examples__
--
-- @since 0.5.0
smap :: S.Stream r ix a => (a -> b) -> Array r ix a -> Vector DS b
smap f = fromSteps . S.map f . S.toStream
{-# INLINE smap #-}

-- | Map an index aware function over a stream vector
--
-- ==== __Examples__
--
-- @since 0.5.0
simap :: S.Stream r ix a => (ix -> a -> b) -> Array r ix a -> Vector DS b
simap f = fromSteps . S.map (uncurry f) . S.toStreamIx
{-# INLINE simap #-}


-- | Traverse a stream vector with an applicative function.
--
-- ==== __Examples__
--
-- @since 0.5.0
straverse :: (S.Stream r ix a, Applicative f) => (a -> f b) -> Array r ix a -> f (Vector DS b)
straverse f = fmap fromSteps . S.traverse f . S.toStream
{-# INLINE straverse #-}


-- | Traverse a stream vector with an index aware applicative function.
--
-- ==== __Examples__
--
-- @since 0.5.0
sitraverse :: (S.Stream r ix a, Applicative f) => (ix -> a -> f b) -> Array r ix a -> f (Vector DS b)
sitraverse f = fmap fromSteps . S.traverse (uncurry f) . S.toStreamIx
{-# INLINE sitraverse #-}


-- | Traverse a stream vector with a monadic function.
--
-- ==== __Examples__
--
-- @since 0.5.0
smapM :: (S.Stream r ix a, Monad m) => (a -> m b) -> Array r ix a -> m (Vector DS b)
smapM f = fromStepsM . S.mapM f . S.transStepsId . S.toStream
{-# INLINE smapM #-}

-- | Traverse a stream vector with a monadic index aware function.
--
-- Corresponds to: @mapM (uncurry f) . imap (,) v@
--
-- ==== __Examples__
--
-- @since 0.5.0
simapM :: (S.Stream r ix a, Monad m) => (ix -> a -> m b) -> Array r ix a -> m (Vector DS b)
simapM f = fromStepsM . S.mapM (uncurry f) . S.transStepsId . S.toStreamIx
{-# INLINE simapM #-}

-- | Traverse a stream vector with a monadic function, while discarding the result
--
-- ==== __Examples__
--
-- @since 0.5.0
smapM_ :: (S.Stream r ix a, Monad m) => (a -> m b) -> Array r ix a -> m ()
smapM_ f = S.mapM_ f . S.transStepsId . S.toStream
{-# INLINE smapM_ #-}

-- | Traverse a stream vector with a monadic index aware function, while discarding the result
--
-- ==== __Examples__
--
-- @since 0.5.0
simapM_ :: (S.Stream r ix a, Monad m) => (ix -> a -> m b) -> Array r ix a -> m ()
simapM_ f = S.mapM_ (uncurry f) . S.transStepsId . S.toStreamIx
{-# INLINE simapM_ #-}


-- | Same as `smapM`, but with arguments flipped.
--
-- ==== __Examples__
--
-- @since 0.5.0
sforM :: (S.Stream r ix a, Monad m) => Array r ix a -> (a -> m b) -> m (Vector DS b)
sforM = flip smapM
{-# INLINE sforM #-}

-- | Same as `simapM`, but with arguments flipped.
--
-- ==== __Examples__
--
-- @since 0.5.0
siforM :: (S.Stream r ix a, Monad m) => Array r ix a -> (ix -> a -> m b) -> m (Vector DS b)
siforM = flip simapM
{-# INLINE siforM #-}

-- | Same as `smapM_`, but with arguments flipped.
--
-- ==== __Examples__
--
-- @since 0.5.0
sforM_ :: (S.Stream r ix a, Monad m) => Array r ix a -> (a -> m b) -> m ()
sforM_ = flip smapM_
{-# INLINE sforM_ #-}

-- | Same as `simapM_`, but with arguments flipped.
--
-- ==== __Examples__
--
-- @since 0.5.0
siforM_ :: (S.Stream r ix a, Monad m) => Array r ix a -> (ix -> a -> m b) -> m ()
siforM_ = flip simapM_
{-# INLINE siforM_ #-}



-- | Zip two arrays in a row-major order together together into a flat vector. Resulting
-- length of a vector will be the smallest number of elements of the supplied arrays.
--
-- ==== __Examples__
--
-- @since 0.5.0
szip ::
     (S.Stream ra ixa a, S.Stream rb ixb b) => Array ra ixa a -> Array rb ixb b -> Vector DS (a, b)
szip = szipWith (,)
{-# INLINE szip #-}

-- |
--
-- @since 0.5.0
szip3 ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c)
  => Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Vector DS (a, b, c)
szip3 = szipWith3 (,,)
{-# INLINE szip3 #-}

-- |
--
-- @since 0.5.0
szip4 ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, S.Stream rd ixd d)
  => Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Vector DS (a, b, c, d)
szip4 = szipWith4 (,,,)
{-# INLINE szip4 #-}

-- |
--
-- @since 0.5.0
szip5 ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, S.Stream rd ixd d, S.Stream re ixe e)
  => Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> Vector DS (a, b, c, d, e)
szip5 = szipWith5 (,,,,)
{-# INLINE szip5 #-}

-- |
--
-- @since 0.5.0
szip6 ::
     ( S.Stream ra ixa a
     , S.Stream rb ixb b
     , S.Stream rc ixc c
     , S.Stream rd ixd d
     , S.Stream re ixe e
     , S.Stream rf ixf f
     )
  => Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> Array rf ixf f
  -> Vector DS (a, b, c, d, e, f)
szip6 = szipWith6 (,,,,,)
{-# INLINE szip6 #-}






-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
szipWith ::
     (S.Stream ra ixa a, S.Stream rb ixb b)
  => (a -> b -> c)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Vector DS c
szipWith f v1 v2 = fromSteps $ S.zipWith f (S.toStream v1) (S.toStream v2)
{-# INLINE szipWith #-}

-- |
--
-- @since 0.5.0
szipWith3 ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c)
  => (a -> b -> c -> d)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Vector DS d
szipWith3 f v1 v2 v3 = fromSteps $ S.zipWith3 f (S.toStream v1) (S.toStream v2) (S.toStream v3)
{-# INLINE szipWith3 #-}

-- |
--
-- @since 0.5.0
szipWith4 ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, S.Stream rd ixd d)
  => (a -> b -> c -> d -> e)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Vector DS e
szipWith4 f v1 v2 v3 v4 =
  fromSteps $ S.zipWith4 f (S.toStream v1) (S.toStream v2) (S.toStream v3) (S.toStream v4)
{-# INLINE szipWith4 #-}

-- |
--
-- @since 0.5.0
szipWith5 ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, S.Stream rd ixd d, S.Stream re ixe e)
  => (a -> b -> c -> d -> e -> f)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> Vector DS f
szipWith5 f v1 v2 v3 v4 v5 =
  fromSteps $
  S.zipWith5 f (S.toStream v1) (S.toStream v2) (S.toStream v3) (S.toStream v4) (S.toStream v5)
{-# INLINE szipWith5 #-}

-- |
--
-- @since 0.5.0
szipWith6 ::
     ( S.Stream ra ixa a
     , S.Stream rb ixb b
     , S.Stream rc ixc c
     , S.Stream rd ixd d
     , S.Stream re ixe e
     , S.Stream rf ixf f
     )
  => (a -> b -> c -> d -> e -> f -> g)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> Array rf ixf f
  -> Vector DS g
szipWith6 f v1 v2 v3 v4 v5 v6 =
  fromSteps $
  S.zipWith6
    f
    (S.toStream v1)
    (S.toStream v2)
    (S.toStream v3)
    (S.toStream v4)
    (S.toStream v5)
    (S.toStream v6)
{-# INLINE szipWith6 #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sizipWith ::
     (S.Stream ra ix a, S.Stream rb ix b)
  => (ix -> a -> b -> c)
  -> Array ra ix a
  -> Array rb ix b
  -> Vector DS c
sizipWith f v1 v2 = fromSteps $ S.zipWith (uncurry f) (S.toStreamIx v1) (S.toStream v2)
{-# INLINE sizipWith #-}

-- |
--
-- @since 0.5.0
sizipWith3 ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c)
  => (ix -> a -> b -> c -> d)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Vector DS d
sizipWith3 f v1 v2 v3 =
  fromSteps $ S.zipWith3 (uncurry f) (S.toStreamIx v1) (S.toStream v2) (S.toStream v3)
{-# INLINE sizipWith3 #-}

-- |
--
-- @since 0.5.0
sizipWith4 ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c, S.Stream rd ix d)
  => (ix -> a -> b -> c -> d -> e)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Vector DS e
sizipWith4 f v1 v2 v3 v4 =
  fromSteps $
  S.zipWith4 (uncurry f) (S.toStreamIx v1) (S.toStream v2) (S.toStream v3) (S.toStream v4)
{-# INLINE sizipWith4 #-}

-- |
--
-- @since 0.5.0
sizipWith5 ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c, S.Stream rd ix d, S.Stream re ix e)
  => (ix -> a -> b -> c -> d -> e -> f)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Array re ix e
  -> Vector DS f
sizipWith5 f v1 v2 v3 v4 v5 =
  fromSteps $
  S.zipWith5
    (uncurry f)
    (S.toStreamIx v1)
    (S.toStream v2)
    (S.toStream v3)
    (S.toStream v4)
    (S.toStream v5)
{-# INLINE sizipWith5 #-}

-- |
--
-- @since 0.5.0
sizipWith6 ::
     ( S.Stream ra ix a
     , S.Stream rb ix b
     , S.Stream rc ix c
     , S.Stream rd ix d
     , S.Stream re ix e
     , S.Stream rf ix f
     )
  => (ix -> a -> b -> c -> d -> e -> f -> g)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Array re ix e
  -> Array rf ix f
  -> Vector DS g
sizipWith6 f v1 v2 v3 v4 v5 v6 =
  fromSteps $
  S.zipWith6
    (uncurry f)
    (S.toStreamIx v1)
    (S.toStream v2)
    (S.toStream v3)
    (S.toStream v4)
    (S.toStream v5)
    (S.toStream v6)
{-# INLINE sizipWith6 #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
szipWithM ::
     (S.Stream ra ixa a, S.Stream rb ixb b, Monad m)
  => (a -> b -> m c)
  -> Array ra ixa a
  -> Array rb ixb b
  -> m (Vector DS c)
szipWithM f v1 v2 = fromStepsM $ S.zipWithM f (toStreamM v1) (toStreamM v2)
{-# INLINE szipWithM #-}

-- |
--
-- @since 0.5.0
szipWith3M ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, Monad m)
  => (a -> b -> c -> m d)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> m (Vector DS d)
szipWith3M f v1 v2 v3 = fromStepsM $ S.zipWith3M f (toStreamM v1) (toStreamM v2) (toStreamM v3)
{-# INLINE szipWith3M #-}

-- |
--
-- @since 0.5.0
szipWith4M ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, S.Stream rd ixd d, Monad m)
  => (a -> b -> c -> d -> m e)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> m (Vector DS e)
szipWith4M f v1 v2 v3 v4 =
  fromStepsM $ S.zipWith4M f (toStreamM v1) (toStreamM v2) (toStreamM v3) (toStreamM v4)
{-# INLINE szipWith4M #-}

-- |
--
-- @since 0.5.0
szipWith5M ::
     ( S.Stream ra ixa a
     , S.Stream rb ixb b
     , S.Stream rc ixc c
     , S.Stream rd ixd d
     , S.Stream re ixe e
     , Monad m
     )
  => (a -> b -> c -> d -> e -> m f)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> m (Vector DS f)
szipWith5M f v1 v2 v3 v4 v5 =
  fromStepsM $
  S.zipWith5M f (toStreamM v1) (toStreamM v2) (toStreamM v3) (toStreamM v4) (toStreamM v5)
{-# INLINE szipWith5M #-}

-- |
--
-- @since 0.5.0
szipWith6M ::
     ( S.Stream ra ixa a
     , S.Stream rb ixb b
     , S.Stream rc ixc c
     , S.Stream rd ixd d
     , S.Stream re ixe e
     , S.Stream rf ixf f
     , Monad m
     )
  => (a -> b -> c -> d -> e -> f -> m g)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> Array rf ixf f
  -> m (Vector DS g)
szipWith6M f v1 v2 v3 v4 v5 v6 =
  fromStepsM $
  S.zipWith6M
    f
    (toStreamM v1)
    (toStreamM v2)
    (toStreamM v3)
    (toStreamM v4)
    (toStreamM v5)
    (toStreamM v6)
{-# INLINE szipWith6M #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sizipWithM ::
     (S.Stream ra ix a, S.Stream rb ix b, Monad m)
  => (ix -> a -> b -> m c)
  -> Array ra ix a
  -> Array rb ix b
  -> m (Vector DS c)
sizipWithM f v1 v2 = fromStepsM $ S.zipWithM (uncurry f) (toStreamIxM v1) (toStreamM v2)
{-# INLINE sizipWithM #-}


-- |
--
-- @since 0.5.0
sizipWith3M ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c, Monad m)
  => (ix -> a -> b -> c -> m d)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> m (Vector DS d)
sizipWith3M f v1 v2 v3 =
  fromStepsM $ S.zipWith3M (uncurry f) (toStreamIxM v1) (toStreamM v2) (toStreamM v3)
{-# INLINE sizipWith3M #-}

-- |
--
-- @since 0.5.0
sizipWith4M ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c, S.Stream rd ix d, Monad m)
  => (ix -> a -> b -> c -> d -> m e)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> m (Vector DS e)
sizipWith4M f v1 v2 v3 v4 =
  fromStepsM $
  S.zipWith4M (uncurry f) (toStreamIxM v1) (toStreamM v2) (toStreamM v3) (toStreamM v4)
{-# INLINE sizipWith4M #-}

-- |
--
-- @since 0.5.0
sizipWith5M ::
     ( S.Stream ra ix a
     , S.Stream rb ix b
     , S.Stream rc ix c
     , S.Stream rd ix d
     , S.Stream re ix e
     , Monad m
     )
  => (ix -> a -> b -> c -> d -> e -> m f)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Array re ix e
  -> m (Vector DS f)
sizipWith5M f v1 v2 v3 v4 v5 =
  fromStepsM $
  S.zipWith5M
    (uncurry f)
    (toStreamIxM v1)
    (toStreamM v2)
    (toStreamM v3)
    (toStreamM v4)
    (toStreamM v5)
{-# INLINE sizipWith5M #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sizipWith6M ::
     ( S.Stream ra ix a
     , S.Stream rb ix b
     , S.Stream rc ix c
     , S.Stream rd ix d
     , S.Stream re ix e
     , S.Stream rf ix f
     , Monad m
     )
  => (ix -> a -> b -> c -> d -> e -> f -> m g)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Array re ix e
  -> Array rf ix f
  -> m (Vector DS g)
sizipWith6M f v1 v2 v3 v4 v5 v6 =
  fromStepsM $
  S.zipWith6M
    (uncurry f)
    (toStreamIxM v1)
    (toStreamM v2)
    (toStreamM v3)
    (toStreamM v4)
    (toStreamM v5)
    (toStreamM v6)
{-# INLINE sizipWith6M #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
szipWithM_ ::
     (S.Stream ra ixa a, S.Stream rb ixb b, Monad m)
  => (a -> b -> m c)
  -> Array ra ixa a
  -> Array rb ixb b
  -> m ()
szipWithM_ f v1 v2 = S.zipWithM_ f (toStreamM v1) (toStreamM v2)
{-# INLINE szipWithM_ #-}

-- |
--
-- @since 0.5.0
szipWith3M_ ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, Monad m)
  => (a -> b -> c -> m d)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> m ()
szipWith3M_ f v1 v2 v3 = S.zipWith3M_ f (toStreamM v1) (toStreamM v2) (toStreamM v3)
{-# INLINE szipWith3M_ #-}

-- |
--
-- @since 0.5.0
szipWith4M_ ::
     (S.Stream ra ixa a, S.Stream rb ixb b, S.Stream rc ixc c, S.Stream rd ixd d, Monad m)
  => (a -> b -> c -> d -> m e)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> m ()
szipWith4M_ f v1 v2 v3 v4 =
  S.zipWith4M_ f (toStreamM v1) (toStreamM v2) (toStreamM v3) (toStreamM v4)
{-# INLINE szipWith4M_ #-}

-- |
--
-- @since 0.5.0
szipWith5M_ ::
     ( S.Stream ra ixa a
     , S.Stream rb ixb b
     , S.Stream rc ixc c
     , S.Stream rd ixd d
     , S.Stream re ixe e
     , Monad m
     )
  => (a -> b -> c -> d -> e -> m f)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> m ()
szipWith5M_ f v1 v2 v3 v4 v5 =
  S.zipWith5M_ f (toStreamM v1) (toStreamM v2) (toStreamM v3) (toStreamM v4) (toStreamM v5)
{-# INLINE szipWith5M_ #-}

-- |
--
-- @since 0.5.0
szipWith6M_ ::
     ( S.Stream ra ixa a
     , S.Stream rb ixb b
     , S.Stream rc ixc c
     , S.Stream rd ixd d
     , S.Stream re ixe e
     , S.Stream rf ixf f
     , Monad m
     )
  => (a -> b -> c -> d -> e -> f -> m g)
  -> Array ra ixa a
  -> Array rb ixb b
  -> Array rc ixc c
  -> Array rd ixd d
  -> Array re ixe e
  -> Array rf ixf f
  -> m ()
szipWith6M_ f v1 v2 v3 v4 v5 v6 =
  S.zipWith6M_
    f
    (toStreamM v1)
    (toStreamM v2)
    (toStreamM v3)
    (toStreamM v4)
    (toStreamM v5)
    (toStreamM v6)
{-# INLINE szipWith6M_ #-}




-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sizipWithM_ ::
     (S.Stream ra ix a, S.Stream rb ix b, Monad m)
  => (ix -> a -> b -> m c)
  -> Array ra ix a
  -> Array rb ix b
  -> m ()
sizipWithM_ f v1 v2 = S.zipWithM_ (uncurry f) (toStreamIxM v1) (toStreamM v2)
{-# INLINE sizipWithM_ #-}


-- |
--
-- @since 0.5.0
sizipWith3M_ ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c, Monad m)
  => (ix -> a -> b -> c -> m d)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> m ()
sizipWith3M_ f v1 v2 v3 = S.zipWith3M_ (uncurry f) (toStreamIxM v1) (toStreamM v2) (toStreamM v3)
{-# INLINE sizipWith3M_ #-}

-- |
--
-- @since 0.5.0
sizipWith4M_ ::
     (S.Stream ra ix a, S.Stream rb ix b, S.Stream rc ix c, S.Stream rd ix d, Monad m)
  => (ix -> a -> b -> c -> d -> m e)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> m ()
sizipWith4M_ f v1 v2 v3 v4 =
  S.zipWith4M_ (uncurry f) (toStreamIxM v1) (toStreamM v2) (toStreamM v3) (toStreamM v4)
{-# INLINE sizipWith4M_ #-}

-- |
--
-- @since 0.5.0
sizipWith5M_ ::
     ( S.Stream ra ix a
     , S.Stream rb ix b
     , S.Stream rc ix c
     , S.Stream rd ix d
     , S.Stream re ix e
     , Monad m
     )
  => (ix -> a -> b -> c -> d -> e -> m f)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Array re ix e
  -> m ()
sizipWith5M_ f v1 v2 v3 v4 v5 =
  S.zipWith5M_
    (uncurry f)
    (toStreamIxM v1)
    (toStreamM v2)
    (toStreamM v3)
    (toStreamM v4)
    (toStreamM v5)
{-# INLINE sizipWith5M_ #-}

-- |
--
-- @since 0.5.0
sizipWith6M_ ::
     ( S.Stream ra ix a
     , S.Stream rb ix b
     , S.Stream rc ix c
     , S.Stream rd ix d
     , S.Stream re ix e
     , S.Stream rf ix f
     , Monad m
     )
  => (ix -> a -> b -> c -> d -> e -> f -> m g)
  -> Array ra ix a
  -> Array rb ix b
  -> Array rc ix c
  -> Array rd ix d
  -> Array re ix e
  -> Array rf ix f
  -> m ()
sizipWith6M_ f v1 v2 v3 v4 v5 v6 =
  S.zipWith6M_
    (uncurry f)
    (toStreamIxM v1)
    (toStreamM v2)
    (toStreamM v3)
    (toStreamM v4)
    (toStreamM v5)
    (toStreamM v6)
{-# INLINE sizipWith6M_ #-}





-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sfoldl :: Stream r ix e => (a -> e -> a) -> a -> Array r ix e -> a
sfoldl f acc = S.unId . S.foldl f acc . toStream
{-# INLINE sfoldl #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sfoldlM :: (Stream r ix e, Monad m) => (a -> e -> m a) -> a -> Array r ix e -> m a
sfoldlM f acc = S.foldlM f acc . S.transStepsId . toStream
{-# INLINE sfoldlM #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sfoldlM_ :: (Stream r ix e, Monad m) => (a -> e -> m a) -> a -> Array r ix e -> m ()
sfoldlM_ f acc = void . sfoldlM f acc
{-# INLINE sfoldlM_ #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sfoldl1' :: Stream r ix e => (e -> e -> e) -> Array r ix e -> e
sfoldl1' f = either throw id . sfoldl1M (\e -> pure . f e)
{-# INLINE sfoldl1' #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sfoldl1M :: (Stream r ix e, MonadThrow m) => (e -> e -> m e) -> Array r ix e -> m e
sfoldl1M f arr = do
  let str = S.transStepsId $ toStream arr
  nullStream <- S.null str
  when nullStream $ throwM $ SizeEmptyException (size arr)
  S.foldl1M f str
{-# INLINE sfoldl1M #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sfoldl1M_ :: (Stream r ix e, MonadThrow m) => (e -> e -> m e) -> Array r ix e -> m ()
sfoldl1M_ f = void . sfoldl1M f
{-# INLINE sfoldl1M_ #-}



-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sifoldl :: Stream r ix e => (a -> ix -> e -> a) -> a -> Array r ix e -> a
sifoldl f acc = S.unId . S.foldl (\a (ix, e) -> f a ix e) acc . toStreamIx
{-# INLINE sifoldl #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sifoldlM :: (Stream r ix e, Monad m) => (a -> ix -> e -> m a) -> a -> Array r ix e -> m a
sifoldlM f acc = S.foldlM (\a (ix, e) -> f a ix e) acc . S.transStepsId . toStreamIx
{-# INLINE sifoldlM #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sifoldlM_ :: (Stream r ix e, Monad m) => (a -> ix -> e -> m a) -> a -> Array r ix e -> m ()
sifoldlM_ f acc = void . sifoldlM f acc
{-# INLINE sifoldlM_ #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sor :: Stream r ix Bool => Array r ix Bool -> Bool
sor = S.unId . S.or . toStream
{-# INLINE sor #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sand :: Stream r ix Bool => Array r ix Bool -> Bool
sand = S.unId . S.and . toStream
{-# INLINE sand #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sany :: Stream r ix e => (e -> Bool) -> Array r ix e -> Bool
sany f = S.unId . S.or . S.map f . toStream
{-# INLINE sany #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sall :: Stream r ix e => (e -> Bool) -> Array r ix e -> Bool
sall f = S.unId . S.and . S.map f . toStream
{-# INLINE sall #-}



-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
ssum :: (Num e, Stream r ix e) => Array r ix e -> e
ssum = sfoldl (+) 0
{-# INLINE ssum #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sproduct :: (Num e, Stream r ix e) => Array r ix e -> e
sproduct = sfoldl (*) 1
{-# INLINE sproduct #-}


-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
smaximum' :: (Ord e, Stream r ix e) => Array r ix e -> e
smaximum' = sfoldl1' max
{-# INLINE smaximum' #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
smaximumM :: (Ord e, Stream r ix e, MonadThrow m) => Array r ix e -> m e
smaximumM = sfoldl1M (\e acc -> pure (max e acc))
{-# INLINE smaximumM #-}



-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sminimum' :: (Ord e, Stream r ix e) => Array r ix e -> e
sminimum' = sfoldl1' min
{-# INLINE sminimum' #-}

-- |
--
-- ==== __Examples__
--
-- @since 0.5.0
sminimumM :: (Ord e, Stream r ix e, MonadThrow m) => Array r ix e -> m e
sminimumM = sfoldl1M (\e acc -> pure (min e acc))
{-# INLINE sminimumM #-}



-- | See `stake`.
--
-- @since 0.4.1
takeS :: Stream r ix e => Sz1 -> Array r ix e -> Array DS Ix1 e
takeS n = fromSteps . S.take (unSz n) . S.toStream
{-# INLINE takeS #-}
{-# DEPRECATED takeS "In favor of `stake`" #-}

-- | See `sdrop`.
--
-- @since 0.4.1
dropS :: Stream r ix e => Sz1 -> Array r ix e -> Array DS Ix1 e
dropS n = fromSteps . S.drop (unSz n) . S.toStream
{-# INLINE dropS #-}
{-# DEPRECATED dropS "In favor of `sdrop`" #-}

-- | See `sunfoldr`
--
-- @since 0.4.1
unfoldr :: (s -> Maybe (e, s)) -> s -> Vector DS e
unfoldr = sunfoldr
{-# INLINE unfoldr #-}
{-# DEPRECATED unfoldr "In favor of `sunfoldr`" #-}


-- | See `sunfoldrN`
--
-- @since 0.4.1
unfoldrN :: Sz1 -> (s -> Maybe (e, s)) -> s -> Vector DS e
unfoldrN = unfoldrN
{-# INLINE unfoldrN #-}
{-# DEPRECATED unfoldrN "In favor of `sunfoldrN`" #-}


-- | See `sfilterM`
--
-- @since 0.4.1
filterM :: (S.Stream r ix e, Applicative f) => (e -> f Bool) -> Array r ix e -> f (Vector DS e)
filterM f arr = DSArray <$> S.filterA f (S.toStream arr)
{-# INLINE filterM #-}
{-# DEPRECATED filterM "In favor of `sfilterM`" #-}

-- | See `sfilter`
--
-- @since 0.4.1
filterS :: S.Stream r ix e => (e -> Bool) -> Array r ix e -> Array DS Ix1 e
filterS = sfilter
{-# INLINE filterS #-}
{-# DEPRECATED filterS "In favor of `sfilter`" #-}


-- | See `smapMaybe`
--
-- @since 0.4.1
mapMaybeS :: S.Stream r ix a => (a -> Maybe b) -> Array r ix a -> Vector DS b
mapMaybeS = smapMaybe
{-# INLINE mapMaybeS #-}
{-# DEPRECATED mapMaybeS "In favor of `smapMaybe`" #-}

-- | See `scatMaybes`
--
-- @since 0.4.4
catMaybesS :: S.Stream r ix (Maybe a) => Array r ix (Maybe a) -> Vector DS a
catMaybesS = scatMaybes
{-# INLINE catMaybesS #-}
{-# DEPRECATED catMaybesS "In favor of `scatMaybes`" #-}

-- | See `smapMaybeM`
--
-- @since 0.4.1
mapMaybeM ::
     (S.Stream r ix a, Applicative f) => (a -> f (Maybe b)) -> Array r ix a -> f (Vector DS b)
mapMaybeM = smapMaybeM
{-# INLINE mapMaybeM #-}
{-# DEPRECATED mapMaybeM "In favor of `smapMaybeM`" #-}

-- | See `traverseS`
--
-- @since 0.4.5
traverseS :: (S.Stream r ix a, Applicative f) => (a -> f b) -> Array r ix a -> f (Vector DS b)
traverseS = straverse
{-# INLINE traverseS #-}
{-# DEPRECATED traverseS "In favor of `straverse`" #-}

-- | See `simapMaybe`
--
-- @since 0.4.1
imapMaybeS :: Source r ix a => (ix -> a -> Maybe b) -> Array r ix a -> Array DS Ix1 b
imapMaybeS f arr =
  mapMaybeS (uncurry f) $ A.makeArrayR D (getComp arr) (size arr) $ \ix -> (ix, unsafeIndex arr ix)
{-# INLINE imapMaybeS #-}
{-# DEPRECATED imapMaybeS "In favor of `simapMaybe`" #-}

-- | See `simapMaybeM`
--
-- @since 0.4.1
imapMaybeM ::
     (Source r ix a, Applicative f) => (ix -> a -> f (Maybe b)) -> Array r ix a -> f (Array DS Ix1 b)
imapMaybeM f arr =
  mapMaybeM (uncurry f) $ A.makeArrayR D (getComp arr) (size arr) $ \ix -> (ix, unsafeIndex arr ix)
{-# INLINE imapMaybeM #-}
{-# DEPRECATED imapMaybeM "In favor of `simapMaybeM`" #-}

-- | Similar to `filterS`, but map with an index aware function.
--
-- @since 0.4.1
ifilterS :: Source r ix a => (ix -> a -> Bool) -> Array r ix a -> Array DS Ix1 a
ifilterS f =
  imapMaybeS $ \ix e ->
    if f ix e
      then Just e
      else Nothing
{-# INLINE ifilterS #-}
{-# DEPRECATED ifilterS "In favor of `sifilter`" #-}


-- | Similar to `filterM`, but map with an index aware function.
--
-- @since 0.4.1
ifilterM ::
     (Source r ix a, Applicative f) => (ix -> a -> f Bool) -> Array r ix a -> f (Array DS Ix1 a)
ifilterM f =
  imapMaybeM $ \ix e ->
    (\p ->
       if p
         then Just e
         else Nothing) <$>
    f ix e
{-# INLINE ifilterM #-}
{-# DEPRECATED ifilterM "In favor of `sifilterM`" #-}