{-# LANGUAGE BangPatterns          #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE UndecidableInstances  #-}
-- |
-- Module      : Data.Massiv.Array.Delayed.Interleaved
-- Copyright   : (c) Alexey Kuleshevich 2018
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Data.Massiv.Array.Delayed.Interleaved
  ( DI(..)
  , toInterleaved
  , fromInterleaved
  ) where

import           Data.Massiv.Array.Delayed.Internal
import           Data.Massiv.Core.Common


-- | Delayed array that will be loaded in an interleaved fasion during parallel
-- computation.
data DI = DI

type instance EltRepr DI ix = DI

newtype instance Array DI ix e = DIArray { diArray :: Array D ix e }

instance Index ix => Construct DI ix e where
  setComp c arr = arr { diArray = (diArray arr) { dComp = c } }
  {-# INLINE setComp #-}

  unsafeMakeArray c sz = DIArray . unsafeMakeArray c sz
  {-# INLINE unsafeMakeArray #-}

instance Functor (Array DI ix) where
  fmap f (DIArray arr) = DIArray (fmap f arr)


instance Index ix => Resize Array DI ix where
  unsafeResize sz = DIArray . unsafeResize sz . diArray
  {-# INLINE unsafeResize #-}

instance Index ix => Extract DI ix e where
  unsafeExtract sIx newSz = DIArray . unsafeExtract sIx newSz . diArray
  {-# INLINE unsafeExtract #-}


instance Index ix => Load DI ix e where
  unsafeSize (DIArray arr) = unsafeSize arr
  {-# INLINE unsafeSize #-}
  getComp = dComp . diArray
  {-# INLINE getComp #-}
  loadArray numWorkers' scheduleWork' (DIArray (DArray _ sz f)) unsafeWrite =
    loopM_ 0 (< numWorkers') (+ 1) $ \ !start ->
      scheduleWork' $
      iterLinearM_ sz start (totalElem sz) numWorkers' (<) $ \ !k -> unsafeWrite k . f
  {-# INLINE loadArray #-}

instance Index ix => StrideLoad DI ix e where
  loadArrayWithStride numWorkers' scheduleWork' stride resultSize arr unsafeWrite =
    let strideIx = unStride stride
        DIArray (DArray _ _ f) = arr
    in loopM_ 0 (< numWorkers') (+ 1) $ \ !start ->
          scheduleWork' $
          iterLinearM_ resultSize start (totalElem resultSize) numWorkers' (<) $
            \ !i ix -> unsafeWrite i (f (liftIndex2 (*) strideIx ix))
  {-# INLINE loadArrayWithStride #-}

-- | Convert a source array into an array that, when computed, will have its elemets evaluated out
-- of order (interleaved amoungs cores), hence making unbalanced computation better parallelizable.
toInterleaved :: (Load r ix e, Source r ix e) => Array r ix e -> Array DI ix e
toInterleaved = DIArray . delay
{-# INLINE toInterleaved #-}

-- | /O(1)/ - Unwrap the interleved array.
--
-- @since 0.2.1
fromInterleaved :: Array DI ix e -> Array D ix e
fromInterleaved = diArray
{-# INLINE fromInterleaved #-}
