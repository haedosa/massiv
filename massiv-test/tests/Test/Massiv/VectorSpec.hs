{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
module Test.Massiv.VectorSpec (spec) where

import Control.Applicative
import Control.DeepSeq
import Control.Exception
import Data.Bits
import Data.Massiv.Array as A
import Data.Massiv.Vector as V
import Data.Maybe
import Data.Primitive.MutVar
import qualified Data.Vector as VB
import qualified Data.Vector.Primitive as VP
import qualified Data.Vector.Storable as VS
import qualified Data.Vector.Unboxed as VU
import Data.Word
import Data.Int
import Test.Massiv.Core

import System.Random.MWC as MWC

infix 4 !==!, !!==!!

sizeException :: SizeException -> Bool
sizeException exc = exc `deepseq` True

(!==!) :: (Eq e, Show e, Prim e, Load r Ix1 e) => V.Vector r e -> VP.Vector e -> Property
(!==!) arr vec = toPrimitiveVector (convert arr) === vec

(!!==!!) :: (Eq e, Show e, Prim e, Source r Ix1 e) => V.Vector r e -> VP.Vector e -> Property
(!!==!!) arr vec = property $ do
  eRes <- try (pure $! vec)
  case eRes of
    Right vec' -> toPrimitiveVector (computeSource arr) `shouldBe` vec'
    Left (_exc :: ErrorCall) ->
      shouldThrow (pure $! computeAs P arr) sizeException

newtype SeedVector = SeedVector (VP.Vector Word32) deriving (Eq, Show)

instance Arbitrary SeedVector where
  arbitrary = SeedVector . VP.fromList <$> arbitrary

withSeed :: forall a. SeedVector -> (forall s. MWC.Gen s -> ST s a) -> a
withSeed (SeedVector seed) f = runST $ MWC.initialize seed >>= f

prop_sreplicateM :: SeedVector -> Int -> Property
prop_sreplicateM seed k =
  withSeed @(V.Vector DS Word) seed (V.sreplicateM (Sz k) . uniform)
  !==! withSeed seed (VP.replicateM k . uniform)

prop_sgenerateM :: SeedVector -> Int -> Fun Int Word -> Property
prop_sgenerateM seed k f =
  withSeed @(V.Vector DS Word) seed (genWith (V.sgenerateM (Sz k)))
  !==! withSeed seed (genWith (VP.generateM k))
  where
    genWith :: PrimMonad f => ((Int -> f Word) -> t) -> MWC.Gen (PrimState f) -> t
    genWith genM gen = genM (\i -> xor (apply f i) <$> uniform gen)


prop_siterateNM :: SeedVector -> Int -> Word -> Property
prop_siterateNM seed k a =
  withSeed @(V.Vector DS Word) seed (genWith (\f -> V.siterateNM (Sz k) f a))
  !==! withSeed seed (genWith (\f -> VP.iterateNM k f a))
  where
    genWith :: PrimMonad f => ((Word -> f Word) -> t) -> MWC.Gen (PrimState f) -> t
    genWith genM gen = genM (\prev -> xor prev <$> uniform gen)


genWithUnfoldrM ::
     PrimMonad f => ((Word -> f (Maybe (Word, Word))) -> t) -> MWC.Gen (PrimState f) -> t
genWithUnfoldrM genM gen = genM $ \prev -> do
  x <- uniform gen
  let cur = prev `xor` x
  pure $ if cur `mod` 17 == 0 then Nothing else Just (x, cur)

prop_sunfoldrM :: SeedVector -> Word -> Property
prop_sunfoldrM seed a =
  withSeed @(V.Vector DS Word) seed (genWithUnfoldrM (`V.sunfoldrM` a))
  !==! withSeed seed (genWithUnfoldrM (`VP.unfoldrM`a))

prop_sunfoldrNM :: SeedVector -> Int -> Word -> Property
prop_sunfoldrNM seed k a =
  withSeed @(V.Vector DS Word) seed (genWithUnfoldrM (\f -> V.sunfoldrNM (Sz k) f a))
  !==! withSeed seed (genWithUnfoldrM (\f -> VP.unfoldrNM k f a))

prop_sunfoldrExactNM :: SeedVector -> Int -> Word -> Property
prop_sunfoldrExactNM seed k a =
  withSeed @(V.Vector DS Word) seed (genWith (\f -> V.sunfoldrExactNM (Sz k) f a))
  !==! withSeed seed (genWith (\f -> VP.unfoldrNM k (fmap Just . f) a))
  where
    genWith :: PrimMonad f => ((Word -> f (Word, Word)) -> t) -> MWC.Gen (PrimState f) -> t
    genWith genM gen = genM $ \prev -> do
      x <- uniform gen
      pure (x, prev `xor` x)


genWithMapM :: PrimMonad m => ((Word -> m Word) -> m a) -> MWC.Gen (PrimState m) -> m a
genWithMapM genM gen = genM $ \e -> xor e <$> uniform gen
genWithMapWS :: PrimMonad m => ((Word -> MWC.Gen (PrimState m) -> m Word) -> m a) -> m a
genWithMapWS genM = genM $ \e gen -> xor e <$> uniform gen

genWithIMapM :: PrimMonad m => ((Int -> Word -> m Word) -> m a) -> MWC.Gen (PrimState m) -> m a
genWithIMapM genM gen = genM $ \i e -> do
  ir <- uniformR (0, fromIntegral i) gen
  xor ir . xor e <$> uniform gen
genWithIMapWS :: PrimMonad m => ((Int -> Word -> MWC.Gen (PrimState m) -> m Word) -> m a) -> m a
genWithIMapWS genM =
  genM $ \i e gen -> do
    ir <- uniformR (0, fromIntegral i) gen
    xor ir . xor e <$> uniform gen


genWithMapM_ :: PrimMonad m => ((Word -> m ()) -> m ()) -> MWC.Gen (PrimState m) -> m Word
genWithMapM_ genM gen = do
  ref <- newMutVar =<< uniform gen
  genM $ \e -> do
    e' <- xor e <$> uniform gen
    modifyMutVar ref (xor e')
  readMutVar ref

genWithIMapM_ :: PrimMonad m => ((Int -> Word -> m ()) -> m ()) -> MWC.Gen (PrimState m) -> m Word
genWithIMapM_ genM gen = do
  ref <- newMutVar =<< uniform gen
  genM $ \i e -> do
    ir <- uniformR (0, fromIntegral i) gen
    e' <- xor ir . xor e <$> uniform gen
    modifyMutVar ref (xor e')
  readMutVar ref

prop_straverse :: SeedVector -> Array P Ix2 Word -> Property
prop_straverse seed a =
  withSeed @(V.Vector DS Word) seed (genWithMapM (`V.straverse` a))
  !==! withSeed seed (genWithMapM (`VP.mapM` toPrimitiveVector a))

prop_smapM :: SeedVector -> Array P Ix2 Word -> Property
prop_smapM seed a =
  withSeed @(V.Vector DS Word) seed (genWithMapM (`V.smapM` a))
  !==! withSeed seed (genWithMapM (`VP.mapM` toPrimitiveVector a))

prop_smapMaybeM :: SeedVector -> Array B Ix2 Word -> Fun Word (Maybe Word16) -> Property
prop_smapMaybeM seed a gm =
  withSeed @(V.Vector DS Word16) seed (genWithMapM (\ f -> V.smapMaybeM (fmap g . f) a))
  !==! withSeed seed (genWithMapM
                      (\f -> VP.convert . VB.mapMaybe id <$> VB.mapM (fmap g . f) (toBoxedVector a)))
  where g = apply gm

prop_sitraverse :: SeedVector -> Vector P Word -> Property
prop_sitraverse seed a =
  withSeed @(V.Vector DS Word) seed (genWithIMapM (`V.sitraverse` a))
  !==! withSeed seed (genWithIMapM (\f -> VP.convert <$> VU.mapM (uncurry f) vp))
  where
    vp = VU.imap (,) $ toUnboxedVector (compute a)

prop_simapM :: SeedVector -> Vector U Word -> Property
prop_simapM seed a =
  withSeed @(V.Vector DS Word) seed (genWithIMapM (V.siforM a))
  !==! withSeed seed (genWithIMapM (\f -> VP.convert <$> VU.mapM (uncurry f) vp))
  where
    vp = VU.imap (,) $ toUnboxedVector a

prop_smapM_ :: SeedVector -> Array P Ix2 Word -> Property
prop_smapM_ seed a =
  withSeed seed (genWithMapM_ (V.sforM_ a)) ===
  withSeed seed (genWithMapM_ (VP.forM_ (toPrimitiveVector a)))

prop_simapM_ :: SeedVector -> Vector U Word -> Property
prop_simapM_ seed a =
  withSeed seed (genWithIMapM_ (V.siforM_ a)) ===
  withSeed seed (genWithIMapM_ (\f -> VU.mapM_ (uncurry f) vp))
  where
    vp = VU.imap (,) $ toUnboxedVector a

prop_sfilterM :: SeedVector -> Fun Word Bool -> Vector P Word -> Property
prop_sfilterM seed g a =
  withSeed @(V.Vector DS Word) seed (genWith (`V.sfilterM` a))
  !==! withSeed seed (genWith (`VP.filterM` toPrimitiveVector a))
  where
    genWith :: PrimMonad f => ((Word -> f Bool) -> t) -> MWC.Gen (PrimState f) -> t
    genWith genM gen = genM $ \e -> do
      x <- xor e <$> uniform gen
      pure $ apply g x

prop_sifilterM :: SeedVector -> Fun Word Bool -> Vector U Word -> Property
prop_sifilterM seed g a =
  withSeed @(V.Vector DS Word) seed (genWith (`V.sifilterM` a))
  !==! withSeed seed (genWith (\f -> VP.convert . VU.map snd <$> VU.filterM (uncurry f) vp))
  where
    vp = VU.imap (,) $ toUnboxedVector a
    genWith :: PrimMonad f => ((Int -> Word -> f Bool) -> t) -> MWC.Gen (PrimState f) -> t
    genWith genM gen = genM $ \i e -> do
      ir <- uniformR (0, fromIntegral i) gen
      x <- xor ir . xor e <$> uniform gen
      pure $ apply g x



applyFun4 :: Fun (a, b, c, d) e -> (a -> b -> c -> d -> e)
applyFun4 (Fun _ f) a b c d = f (a, b, c, d)
applyFun5 :: Fun (a, b, c, d, e) f -> (a -> b -> c -> d -> e -> f)
applyFun5 (Fun _ g) a b c d f = g (a, b, c, d, f)
applyFun6 :: Fun (a, (b, c, d, e, f)) g -> (a -> b -> c -> d -> e -> f -> g)
applyFun6 (Fun _ h) a b c d f g = h (a, (b, c, d, f, g))
applyFun7 :: Fun (a, b, (c, d, e, f, g)) h -> (a -> b -> c -> d -> e -> f -> g -> h)
applyFun7 (Fun _ i) a b c d f g h = i (a, b, (c, d, f, g, h))


prop_szipWith :: Vector P Word -> Array P Ix2 Int -> Fun (Word, Int) Int -> Property
prop_szipWith v1 v2 f =
  V.szipWith (applyFun2 f) v1 v2 !==!
  VP.zipWith (applyFun2 f) (toPrimitiveVector v1) (toPrimitiveVector v2)

prop_szipWith3 ::
     Vector P Word64
  -> Array P Ix2 Word32
  -> Array P Ix3 Word16
  -> Fun (Word64, Word32, Word16) Int
  -> Property
prop_szipWith3 v1 v2 v3 f =
  V.szipWith3 (applyFun3 f) v1 v2 v3 !==!
  VP.zipWith3 (applyFun3 f) (toPrimitiveVector v1) (toPrimitiveVector v2) (toPrimitiveVector v3)

prop_szipWith4 ::
     Vector P Word64
  -> Array P Ix2 Word32
  -> Array P Ix3 Word16
  -> Array P Ix4 Word8
  -> Fun (Word64, Word32, Word16, Word8) Int
  -> Property
prop_szipWith4 v1 v2 v3 v4 f =
  V.szipWith4 (applyFun4 f) v1 v2 v3 v4 !==!
  VP.zipWith4
    (applyFun4 f)
    (toPrimitiveVector v1)
    (toPrimitiveVector v2)
    (toPrimitiveVector v3)
    (toPrimitiveVector v4)

prop_szipWith5 ::
     Vector P Word64
  -> Array P Ix2 Word32
  -> Array P Ix3 Word16
  -> Array P Ix4 Word8
  -> Array P Ix5 Int8
  -> Fun (Word64, Word32, Word16, Word8, Int8) Int
  -> Property
prop_szipWith5 v1 v2 v3 v4 v5 f =
  V.szipWith5 (applyFun5 f) v1 v2 v3 v4 v5 !==!
  VP.zipWith5
    (applyFun5 f)
    (toPrimitiveVector v1)
    (toPrimitiveVector v2)
    (toPrimitiveVector v3)
    (toPrimitiveVector v4)
    (toPrimitiveVector v5)

prop_szipWith6 ::
     Vector DS Word64
  -> Array B Ix2 Word32
  -> Array N Ix3 Word16
  -> Array S Ix4 Word8
  -> Array U Ix5 Int8
  -> Array P Ix4 Int16
  -> Fun (Word64, (Word32, Word16, Word8, Int8, Int16)) Int
  -> Property
prop_szipWith6 v1 v2 v3 v4 v5 v6 f =
  V.szipWith6 (applyFun6 f) v1 v2 v3 v4 v5 v6 !==!
  VP.zipWith6
    (applyFun6 f)
    (toPrimitiveVector (compute v1))
    (toPrimitiveVector (compute v2))
    (toPrimitiveVector (compute v3))
    (toPrimitiveVector (compute v4))
    (toPrimitiveVector (compute v5))
    (toPrimitiveVector v6)

prop_sizipWith :: Vector DS Word64 -> Vector DS Word32 -> Fun (Ix1, Word64, Word32) Int -> Property
prop_sizipWith v1 v2 f =
  sizipWith (applyFun3 f) v1 v2 !==!
  VP.izipWith (applyFun3 f) (toPrimitiveVector (compute v1)) (toPrimitiveVector (compute v2))

prop_sizipWith3 ::
     Vector P Word64
  -> Vector D Word32
  -> Vector D Word16
  -> Fun (Ix1, Word64, Word32, Word16) Int
  -> Property
prop_sizipWith3 v1 v2 v3 f =
  sizipWith3 (applyFun4 f) v1 v2 v3 !==!
  VP.izipWith3
    (applyFun4 f)
    (toPrimitiveVector (compute v1))
    (toPrimitiveVector (compute v2))
    (toPrimitiveVector (compute v3))

prop_sizipWith4 ::
     Vector D Word64
  -> Vector DS Word32
  -> Vector P Word16
  -> Vector U Word8
  -> Fun (Ix1, Word64, Word32, Word16, Word8) Int
  -> Property
prop_sizipWith4 v1 v2 v3 v4 f =
  sizipWith4 (applyFun5 f) v1 v2 v3 v4 !==!
  VP.izipWith4
    (applyFun5 f)
    (toPrimitiveVector (compute v1))
    (toPrimitiveVector (compute v2))
    (toPrimitiveVector (compute v3))
    (toPrimitiveVector (compute v4))

prop_sizipWith5 ::
     Vector DS Word64
  -> Vector S Word32
  -> Vector P Word16
  -> Vector U Word8
  -> Vector N Int8
  -> Fun (Ix1, (Word64, Word32, Word16, Word8, Int8)) Int
  -> Property
prop_sizipWith5 v1 v2 v3 v4 v5 f =
  sizipWith5 (applyFun6 f) v1 v2 v3 v4 v5 !==!
  VP.izipWith5
    (applyFun6 f)
    (toPrimitiveVector (compute v1))
    (toPrimitiveVector (compute v2))
    (toPrimitiveVector (compute v3))
    (toPrimitiveVector (compute v4))
    (toPrimitiveVector (compute v5))

prop_sizipWith6 ::
     Vector DS Word64
  -> Vector D Word32
  -> Vector B Word16
  -> Vector N Word8
  -> Vector P Int8
  -> Vector U Int16
  -> Fun (Ix1, Word64, (Word32, Word16, Word8, Int8, Int16)) Int
  -> Property
prop_sizipWith6 v1 v2 v3 v4 v5 v6 f =
  sizipWith6 (applyFun7 f) v1 v2 v3 v4 v5 v6 !==!
  VP.izipWith6
    (applyFun7 f)
    (toPrimitiveVector (compute v1))
    (toPrimitiveVector (compute v2))
    (toPrimitiveVector (compute v3))
    (toPrimitiveVector (compute v4))
    (toPrimitiveVector (compute v5))
    (toPrimitiveVector (compute v6))


spec :: Spec
spec = do
  describe "Vector" $ do
    describe "same-as-array" $ do
      describe "traverse" $ do
        prop "straverse == traversePrim" prop_straverse_traversePrim
        prop "sitraverse == itraversePrim" prop_sitraverse_itraversePrim
        prop "sitraverse == itraverseA" prop_sitraverse_itraverseA
        prop "simapM_ == itraverseA_" prop_simapM_itraverseA_
        prop "smapM_ == traverseA_" prop_smapM_traverseA_
        prop "sforM == forM" prop_sforM_forM
        prop "siforM == iforM" prop_siforM_iforM
        prop "sforM_ == forM_" prop_sforM_forM_
        prop "siforM_ == iforM_" prop_siforM_iforM_
        prop "sforM_ == forIO_ (ParN 1)" prop_sforM_forIO_
        prop "sforM == forIO (Seq)" prop_sforM_forIO
        prop "siforM == iforIO (ParN 1)" prop_siforM_iforIO
        prop "siforM == iforIO_ (ParN 1)" prop_siforM_iforIO_
        prop "siforM == iforWS (ParN 1)" prop_siforM_iforWS
        prop "smapM == mapWS (Seq)" prop_smapM_mapWS
      describe "Enumeration" $ do
        prop "senumFromN" $ \comp (i :: Int) sz ->
          V.senumFromN i sz !==! toPrimitiveVector (compute (A.enumFromN comp i sz))
        prop "senumFromStepN" $ \comp (i :: Int) s sz ->
          V.senumFromStepN i s sz !==! toPrimitiveVector (compute (A.enumFromStepN comp i s sz))
    describe "same-as-vector-package" $ do
      describe "Accessors" $ do
        describe "Size" $ do
          it "slength" $ do
            slength (sfromList []) `shouldBe` Nothing
            slength (sfromListN 1 []) `shouldBe` Nothing
            slength (sgenerate 1 id) `shouldBe` Just 1
          it "snull" $ do
            snull sempty `shouldBe` True
            snull (fromLists' Seq [[]] :: Array P Ix2 Int) `shouldBe` True
            snull (siterateN 3 id ()) `shouldBe` False
            snull (0 ..: 1 :> 2 :> 3 :. 0) `shouldBe` True
        describe "Indexing" $ do
          prop "head' (non-empty)" $ \(ArrNE arr :: ArrNE D Ix1 Int) ->
            head' arr === evaluate' arr 0 .&&. head' arr === shead' arr
          prop "head'" $ \(arr :: Array D Ix1 Int) ->
            (singleton (head' arr) :: Array D Ix1 Int) !!==!!
            VP.singleton (VP.head (toPrimitiveVector (compute arr)))
          prop "shead'" $ \(arr :: Array P Ix1 Int) ->
            (singleton (shead' arr) :: Array D Ix1 Int) !!==!!
            VP.singleton (VP.head (toPrimitiveVector arr))
          prop "last'" $ \(arr :: Array P Ix1 Int) ->
            (singleton (last' arr) :: Array D Ix1 Int) !!==!!
            VP.singleton (VP.last (toPrimitiveVector arr))
        describe "Slicing" $ do
          prop "slice" $ \i sz (arr :: Array P Ix1 Word) ->
            V.slice i sz arr !!==!! VP.take (unSz sz) (VP.drop i (toPrimitiveVector arr))
          prop "sslice" $ \i sz (arr :: Array P Ix1 Word) ->
            computeAs B (V.sslice i sz arr) !!==!!
            VP.take (unSz sz) (VP.drop i (toPrimitiveVector arr))
          prop "slice'" $ \i sz (arr :: Array P Ix1 Word) ->
            V.slice' i sz arr !!==!! VP.slice i (unSz sz) (toPrimitiveVector arr)
          prop "init" $ \(arr :: Array P Ix1 Word) ->
            V.init arr !==! VP.reverse (VP.drop 1 (VP.reverse (toPrimitiveVector arr)))
          prop "init'" $ \(arr :: Array P Ix1 Word) ->
            V.init' arr !!==!! VP.init (toPrimitiveVector arr)
          prop "tail" $ \(arr :: Array P Ix1 Word) ->
            let vp = toPrimitiveVector arr
             in (V.tail arr !==! VP.drop 1 vp) .&&.
                (not (isEmpty arr) ==> V.tail arr !==! VP.tail vp)
          prop "tail'" $ \(arr :: Array P Ix1 Word) ->
            V.tail' arr !!==!! VP.tail (toPrimitiveVector arr)
          prop "take" $ \n (arr :: Array P Ix1 Word) ->
            V.take (Sz n) arr !==! VP.take n (toPrimitiveVector arr)
          prop "take'" $ \sz@(Sz n) (arr :: Array P Ix1 Word) ->
            V.take' sz arr !!==!! VP.slice 0 n (toPrimitiveVector arr)
          prop "stake" $ \n (arr :: Array P Ix1 Word) ->
            V.stake (Sz n) arr !==! VP.take n (toPrimitiveVector arr)
          prop "drop" $ \n (arr :: Array P Ix1 Word) ->
            V.drop (Sz n) arr !==! VP.drop n (toPrimitiveVector arr)
          prop "drop'" $ \sz@(Sz n) (arr :: Array P Ix1 Word) ->
            V.drop' sz arr !!==!! VP.slice n (unSz (size arr) - n) (toPrimitiveVector arr)
          prop "sdrop" $ \n (arr :: Array P Ix1 Word) ->
            V.sdrop (Sz n) arr !==! VP.drop n (toPrimitiveVector arr)
          prop "sliceAt" $ \sz (arr :: Array P Ix1 Word) ->
            let (larr, rarr) = V.sliceAt (Sz sz) arr
                (lvec, rvec) = VP.splitAt sz (toPrimitiveVector arr)
             in (larr !==! lvec) .&&. (rarr !==! rvec)
          prop "sliceAt'" $ \sz@(Sz n) (arr :: Array P Ix1 Word) ->
            let (larr, rarr) = V.sliceAt' sz arr
                lvec = VP.slice 0 n (toPrimitiveVector arr)
                rvec = VP.slice n (unSz (size arr) - n) (toPrimitiveVector arr)
             in (larr !!==!! lvec) .&&. (rarr !!==!! rvec)
      describe "Constructors" $ do
        describe "Initialization" $ do
          it "empty" $ toPrimitiveVector (V.empty :: V.Vector P Word) `shouldBe` VP.empty
          it "sempty" $
            toPrimitiveVector (compute (V.sempty :: V.Vector DS Word)) `shouldBe` VP.empty
          prop "singleton" $ \e -> (V.singleton e :: V.Vector P Word) !==! VP.singleton e
          prop "ssingleton" $ \(e :: Word) -> V.ssingleton e !==! VP.singleton e
          prop "replicate" $ \comp k (e :: Word) -> V.replicate comp (Sz k) e !==! VP.replicate k e
          prop "sreplicate" $ \k (e :: Word) -> V.sreplicate (Sz k) e !==! VP.replicate k e
          prop "generate" $ \comp k (f :: Fun Int Word) ->
            V.generate comp (Sz k) (apply f) !==! VP.generate k (apply f)
          prop "sgenerate" $ \k (f :: Fun Int Word) ->
            V.sgenerate (Sz k) (apply f) !==! VP.generate k (apply f)
          prop "siterateN" $ \n (f :: Fun Word Word) a ->
            V.siterateN (Sz n) (apply f) a !==! VP.iterateN n (apply f) a
        describe "Monadic initialization" $ do
          prop "sreplicateM" prop_sreplicateM
          prop "sgenerateM" prop_sgenerateM
          prop "siterateNM" prop_siterateNM
        describe "Unfolding" $ do
          prop "sunfoldr" $ \(a :: Word) ->
            let f b
                  | b > 10000 || b `div` 17 == 0 = Nothing
                  | otherwise = Just (b * b, b + 1)
             in V.sunfoldr f a !==! VP.unfoldr f a
          prop "sunfoldrN" $ \n (a :: Word) ->
            let f b
                  | b > 10000 || b `div` 19 == 0 = Nothing
                  | otherwise = Just (b * b, b + 1)
             in V.sunfoldrN (Sz n) f a !==! VP.unfoldrN n f a
          prop "sunfoldrExactN" $ \n (a :: Word) ->
            let f b = (b * b, b + 1)
             in V.sunfoldrExactN (Sz n) f a !==! VP.unfoldrN n (Just . f) a
          prop "sunfoldrM" prop_sunfoldrM
          prop "sunfoldrNM" prop_sunfoldrNM
          prop "sunfoldrExactM" prop_sunfoldrExactNM
        describe "Enumeration" $ do
          prop "senumFromN" $ \(i :: Int) n -> V.senumFromN i (Sz n) !==! VP.enumFromN i n
          prop "senumFromStepN" $ \(i :: Int) s n ->
            V.senumFromStepN i s (Sz n) !==! VP.enumFromStepN i s n
        describe "Concatenation" $ do
          prop "sappend" $ \(v1 :: Vector D Int) (v2 :: Vector P Int) ->
            V.sappend v1 v2 !==! toPrimitiveVector (compute v1) VP.++ toPrimitiveVector v2
          prop "sconcat" $ \(vs :: [Vector P Int]) ->
            V.sconcat vs !==! VP.concat (fmap toPrimitiveVector vs)
      describe "Predicates" $ do
        describe "Filtering" $ do
          prop "sfilter" $ \(v :: Vector P Word) (f :: Fun Word Bool) ->
            V.sfilter (apply f) v !==! VP.filter (apply f) (toPrimitiveVector v)
          prop "sifilter" $ \(v :: Vector P Word) (f :: Fun (Int, Word) Bool) ->
            V.sifilter (applyFun2 f) v !==! VP.ifilter (applyFun2 f) (toPrimitiveVector v)
          prop "sfilterM" prop_sfilterM
          prop "sifilterM" prop_sifilterM
          prop "smapMaybe" $ \(v :: Vector P Word) (f :: Fun Word (Maybe Int)) ->
            V.smapMaybe (apply f) v !==! VP.mapMaybe (apply f) (toPrimitiveVector v)
          prop "simapMaybe" $ \(v :: Vector P Word) (f :: Fun (Int, Word) (Maybe Int)) ->
            V.simapMaybe (applyFun2 f) v !==! VP.imapMaybe (applyFun2 f) (toPrimitiveVector v)
          prop "scatMaybes" $ \(v :: Vector D (Maybe Word)) ->
            V.scatMaybes v !==! toPrimitiveVector (compute (smap fromJust (sfilter isJust v)))
          prop "smapMaybeM" prop_smapMaybeM
          prop "fmap" $ \(v :: Vector DS Word) (f :: Fun Word Int) ->
            fmap (apply f) v !==! VP.map (apply f) (toPrimitiveVector (compute v))
          prop "<$" $ \(v :: Vector DS Word) (a :: Char) ->
            (a <$ v) !==! VP.replicate (totalElem (size v)) a
          prop "smap" $ \(v :: Vector P Word) (f :: Fun Word Int) ->
            V.smap (apply f) v !==! VP.map (apply f) (toPrimitiveVector v)
          prop "simap" $ \(v :: Vector P Word) (f :: Fun (Int, Word) Int) ->
            V.simap (applyFun2 f) v !==! VP.imap (applyFun2 f) (toPrimitiveVector v)
          prop "straverse" prop_straverse
          prop "sitraverse" prop_sitraverse
          prop "smapM" prop_smapM
          prop "simapM" prop_simapM
          prop "smapM" prop_smapM_
          prop "simapM" prop_simapM_
          prop "szipWith" prop_szipWith
          prop "szipWith3" prop_szipWith3
          prop "szipWith4" prop_szipWith4
          prop "szipWith5" prop_szipWith5
          prop "szipWith6" prop_szipWith6
          prop "sizipWith" prop_sizipWith
          prop "sizipWith3" prop_sizipWith3
          prop "sizipWith4" prop_sizipWith4
          prop "sizipWith5" prop_sizipWith5
          prop "sizipWith6" prop_sizipWith6
          prop "liftA2" $ \(v1 :: Vector DS Word) (v2 :: Vector DS Int) (f :: Fun (Word, Int) Int) ->
            liftA2 (applyFun2 f) v1 v2 !==!
            VP.zipWith
              (applyFun2 f)
              (toPrimitiveVector (compute v1))
              (toPrimitiveVector (compute v2))
      describe "Folding" $ do
        prop "sfoldl" $ \(v :: Vector P Word32) (f :: Fun (Word, Word32) Word) a0 ->
          V.sfoldl (applyFun2 f) a0 v === VP.foldl (applyFun2 f) a0 (toPrimitiveVector v)
        prop "sifoldl" $ \(v :: Vector P Word32) (f :: Fun (Word, Ix1, Word32) Word) a0 ->
          V.sifoldl (applyFun3 f) a0 v === VP.ifoldl (applyFun3 f) a0 (toPrimitiveVector v)
        prop "sfoldl1'" prop_sfoldl1'
        describe "Specialized" $ do
          prop "sor" $ \(v :: Vector S Bool) -> V.sor v === VS.or (toStorableVector v)
          prop "sand" $ \(v :: Vector S Bool) -> V.sand v === VS.and (toStorableVector v)
          prop "sany" $ \(v :: Vector P Word) (f :: Fun Word Bool) ->
            V.sany (apply f) v === VP.any (apply f) (toPrimitiveVector v)
          prop "sall" $ \(v :: Vector P Word) (f :: Fun Word Bool) ->
            V.sall (apply f) v === VP.all (apply f) (toPrimitiveVector v)
          prop "ssum" $ \(v :: Vector P Word) -> V.ssum v === VP.sum (toPrimitiveVector v)
          prop "sproduct" $ \(v :: Vector P Word) ->
            V.sproduct v === VP.product (toPrimitiveVector v)
          prop "maximum'" prop_maximum'
          prop "minimum'" prop_minimum'
          prop "maximumM" prop_maximumM
          prop "minimumM" prop_minimumM
      describe "Conversion" $
        describe "Lists" $ do
          prop "sfromList" $ \comp (xs :: [Word]) ->
            sfromList xs !==! toPrimitiveVector (fromList comp xs)
          prop "sfromList" $ \(xs :: [Word]) -> sfromList xs !==! VP.fromList xs
          prop "sfromListN" $ \sz@(Sz n) (xs :: [Word]) -> sfromListN sz xs !==! VP.fromListN n xs

prop_sfoldl1' :: Vector P Word -> Fun (Word, Word) Word -> Property
prop_sfoldl1' v f =
  V.singleton @D (V.sfoldl1' (applyFun2 f) v) !!==!!
  VP.singleton (VP.foldl1' (applyFun2 f) (toPrimitiveVector v))

prop_maximum' :: Vector P Word -> Property
prop_maximum' v =
  V.singleton @D (V.smaximum' v) !!==!! VP.singleton (VP.maximum (toPrimitiveVector v))

prop_minimum' :: Vector P Word -> Property
prop_minimum' v =
  V.singleton @D (V.sminimum' v) !!==!! VP.singleton (VP.minimum (toPrimitiveVector v))

prop_maximumM :: Vector P Word -> Property
prop_maximumM v =
  let vp = toPrimitiveVector v
   in V.smaximumM v === (guard (not (VP.null vp)) >> Just (VP.maximum vp))

prop_minimumM :: Vector P Word -> Property
prop_minimumM v =
  let vp = toPrimitiveVector v
   in V.sminimumM v === (guard (not (VP.null vp)) >> Just (VP.minimum vp))

prop_sitraverse_itraverseA :: SeedVector -> Vector S Word -> Property
prop_sitraverse_itraverseA seed a =
  withSeed @(V.Vector P Word) seed (fmap compute . genWithIMapM (`V.sitraverse` a))
  === withSeed seed (genWithIMapM (`itraverseA` a))

prop_straverse_traversePrim :: SeedVector -> Vector S Word -> Property
prop_straverse_traversePrim seed a =
  withSeed @(V.Vector P Word) seed (fmap compute . genWithIMapM (\f -> V.straverse (f 0) a))
  === withSeed seed (genWithIMapM (\f -> traversePrim (f 0) a))

prop_sitraverse_itraversePrim :: SeedVector -> Array P Ix3 Word -> Property
prop_sitraverse_itraversePrim seed a =
  withSeed @(V.Vector P Word) seed (genWithIMapM (\f -> compute <$> V.sitraverse (xorToLinear f) a))
  === withSeed seed (genWithIMapM (\f -> flatten <$> itraversePrim @P (xorToLinear f) a))
  where
    xorToLinear f i = f (foldlIndex xor 0 i)

prop_smapM_traverseA_ :: SeedVector -> Array P Ix2 Word -> Property
prop_smapM_traverseA_ seed a =
  withSeed seed (genWithMapM_ (`V.smapM_` a)) === withSeed seed (genWithMapM_ (`traverseA_` a))

prop_simapM_itraverseA_ :: SeedVector -> Array P Ix2 Word -> Property
prop_simapM_itraverseA_ seed a =
  withSeed seed (genWithIMapM_ (\f -> V.simapM_ (xorToLinear f) a)) ===
  withSeed seed (genWithIMapM_ (\f -> itraverseA_ (xorToLinear f) a))
  where
    xorToLinear f i = f (foldlIndex xor 0 i)

prop_sforM_forM :: SeedVector -> Vector S Word -> Property
prop_sforM_forM seed a =
  withSeed @(V.Vector P Word) seed (fmap compute . genWithMapM (V.sforM a))
  === withSeed seed (genWithMapM (A.forM a))

prop_siforM_iforM :: SeedVector -> Vector S Word -> Property
prop_siforM_iforM seed a =
  withSeed @(V.Vector P Word) seed (fmap compute . genWithIMapM (V.siforM a))
  === withSeed seed (genWithIMapM (iforM a))

withSeedIO :: forall a. SeedVector -> (MWC.Gen (PrimState IO) -> IO a) -> IO a
withSeedIO (SeedVector seed) f = MWC.initialize seed >>= f

prop_sforM_forIO :: SeedVector -> Vector S Word -> Property
prop_sforM_forIO seed a = property $
  withSeedIO seed (genWithMapM (forIO (setComp Seq a))) `shouldReturn`
    withSeed @(V.Vector P Word) seed (fmap compute . genWithMapM (V.sforM a))

prop_siforM_iforIO :: SeedVector -> Vector S Word -> Property
prop_siforM_iforIO seed a = property $
  withSeedIO seed (genWithIMapM (iforIO (setComp (ParN 1) a))) `shouldReturn`
    withSeed @(V.Vector P Word) seed (fmap compute . genWithIMapM (V.siforM a))

prop_sforM_forM_ :: SeedVector -> Vector S Word -> Property
prop_sforM_forM_ seed a = property $
  withSeed seed (genWithMapM_ (A.forM_ a)) `shouldBe`
    withSeed @Word seed (genWithMapM_ (V.sforM_ a))

prop_siforM_iforM_ :: SeedVector -> Vector S Word -> Property
prop_siforM_iforM_ seed a = property $
  withSeed seed (genWithIMapM_ (iforM_ a)) `shouldBe`
    withSeed @Word seed (genWithIMapM_ (V.siforM_ a))

prop_sforM_forIO_ :: SeedVector -> Vector S Word -> Property
prop_sforM_forIO_ seed a = property $
  withSeedIO seed (genWithMapM_ (forIO_ (setComp (ParN 1) a))) `shouldReturn`
    withSeed @Word seed (genWithMapM_ (V.sforM_ a))

prop_siforM_iforIO_ :: SeedVector -> Vector S Word -> Property
prop_siforM_iforIO_ seed a = property $
  withSeedIO seed (genWithIMapM_ (iforIO_ (setComp (ParN 1) a))) `shouldReturn`
    withSeed @Word seed (genWithIMapM_ (V.siforM_ a))


prop_siforM_iforWS :: SeedVector -> Vector S Word -> Property
prop_siforM_iforWS seed@(SeedVector sv) a =
  property $ do
    wsArray <-
      do ws <- initWorkerStates (ParN 1) (const (MWC.initialize sv))
         genWithIMapWS (iforWS ws a)
    wsArray `shouldBe` withSeed @(V.Vector P Word) seed (fmap compute . genWithIMapM (V.siforM a))

prop_smapM_mapWS :: SeedVector -> Vector S Word -> Property
prop_smapM_mapWS seed@(SeedVector sv) a =
  property $ do
    wsArray <-
      do ws <- initWorkerStates Seq (const (MWC.initialize sv))
         genWithMapWS (\f -> mapWS ws f a)
    wsArray `shouldBe` withSeed @(V.Vector P Word) seed (fmap compute . genWithMapM (`V.smapM` a))