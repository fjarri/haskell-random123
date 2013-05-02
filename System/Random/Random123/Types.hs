{-# LANGUAGE FlexibleInstances, FlexibleContexts, UndecidableInstances #-}

-- | Type synonyms for use in function and instance declarations.
module System.Random.Random123.Types where

import Data.Bits
import Data.Word


type Array2 a = (a, a)
type Array4 a = (a, a, a, a)


-- | Class of integers with more bits than in simple types yet having fixed limited size
-- (unlike the built-in 'Integer').
class LimitedInteger a where
    liFromInteger :: Integer -> a
    liToInteger :: a -> Integer
    liBitSize :: a -> Int

-- Technically, Word32 and Word64 instances are identical,
-- but I couldn't persuade GHC to compile them in generalized form
-- (like "instance (Num a, Bits a, Integral a) => LimitedInteger (Array2 a)").

instance LimitedInteger Word32 where
    liFromInteger = fromInteger
    liToInteger = toInteger
    liBitSize = bitSize


array2FromInteger :: Bits a => Integer -> Array2 a
array2FromInteger i = (x0, x1) where
    x1 = fromInteger i
    bits = bitSize x1 -- need this because cannot use 'a' type variable
    x0 = fromInteger (i `shiftR` bits)

array4FromInteger :: Bits a => Integer -> Array4 a
array4FromInteger i = (x0, x1, x2, x3) where
    x3 = fromInteger i
    bits = bitSize x3 -- need this because cannot use 'a' type variable
    x0 = fromInteger (i `shiftR` (bits * 3))
    x1 = fromInteger (i `shiftR` (bits * 2))
    x2 = fromInteger (i `shiftR` bits)

array2ToInteger :: (Integral a, Bits a) => Array2 a -> Integer
array2ToInteger (x0, x1) = x0' + x1' where
    bits = bitSize x0
    x0' = toInteger x0 `shiftL` bits
    x1' = toInteger x1

array4ToInteger :: (Integral a, Bits a) => Array4 a -> Integer
array4ToInteger (x0, x1, x2, x3) = x0' + x1' + x2' + x3' where
    bits = bitSize x0
    x0' = toInteger x0 `shiftL` (bits * 3)
    x1' = toInteger x1 `shiftL` (bits * 2)
    x2' = toInteger x2 `shiftL` bits
    x3' = toInteger x3

instance LimitedInteger (Array2 Word32) where
    liFromInteger = array2FromInteger
    liToInteger = array2ToInteger
    liBitSize _ = bitSize (undefined :: Word32) * 2

instance LimitedInteger (Array4 Word32) where
    liFromInteger = array4FromInteger
    liToInteger = array4ToInteger
    liBitSize _ = bitSize (undefined :: Word32) * 4


instance LimitedInteger Word64 where
    liFromInteger = fromInteger
    liToInteger = toInteger
    liBitSize = bitSize

instance LimitedInteger (Array2 Word64) where
    liFromInteger = array2FromInteger
    liToInteger = array2ToInteger
    liBitSize _ = bitSize (undefined :: Word64) * 2

instance LimitedInteger (Array4 Word64) where
    liFromInteger = array4FromInteger
    liToInteger = array4ToInteger
    liBitSize _ = bitSize (undefined :: Word64) * 4


-- | Class of CBRNG counters.
class LimitedInteger a => Counter a where
    skip :: Integer -> a -> a
    skip i x = liFromInteger (liToInteger x + i)
    increment :: a -> a
    increment = skip 1


instance (LimitedInteger (Array2 a), Ord a, Num a, Bounded a) => Counter (Array2 a) where
    increment (c0, c1)
        | c1 < maxBound = (c0, c1 + 1)
        | otherwise = (c0 + 1, 0)

instance (LimitedInteger (Array4 a), Ord a, Num a, Bounded a) => Counter (Array4 a) where
    increment (c0, c1, c2, c3)
        | c3 < maxBound = (c0, c1, c2, c3 + 1)
        | c2 < maxBound = (c0, c1, c2 + 1, 0)
        | c1 < maxBound = (c0, c1 + 1, 0, 0)
        | otherwise = (c0 + 1, 0, 0, 0)


-- | Class of objects allowing the extraction of 32-bit words from a given position.
class Word32Array a where
    getWord32 :: Int -> a -> Word32
    numWords32 :: a -> Int

instance Word32Array (Array2 Word32) where
    getWord32 0 (x0, x1) = x0
    getWord32 1 (x0, x1) = x1
    numWords32 _ = 2

instance Word32Array (Array4 Word32) where
    getWord32 0 (x0, x1, x2, x3) = x0
    getWord32 1 (x0, x1, x2, x3) = x1
    getWord32 2 (x0, x1, x2, x3) = x2
    getWord32 3 (x0, x1, x2, x3) = x3
    numWords32 _ = 4

instance Word32Array (Array2 Word64) where
    getWord32 0 (x0, x1) = fromIntegral (x0 `shiftR` 32)
    getWord32 1 (x0, x1) = fromIntegral x0
    getWord32 2 (x0, x1) = fromIntegral (x1 `shiftR` 32)
    getWord32 3 (x0, x1) = fromIntegral x1
    numWords32 _ = 4

instance Word32Array (Array4 Word64) where
    getWord32 0 (x0, x1, x2, x3) = fromIntegral (x0 `shiftR` 32)
    getWord32 1 (x0, x1, x2, x3) = fromIntegral x0
    getWord32 2 (x0, x1, x2, x3) = fromIntegral (x1 `shiftR` 32)
    getWord32 3 (x0, x1, x2, x3) = fromIntegral x1
    getWord32 4 (x0, x1, x2, x3) = fromIntegral (x2 `shiftR` 32)
    getWord32 5 (x0, x1, x2, x3) = fromIntegral x2
    getWord32 6 (x0, x1, x2, x3) = fromIntegral (x3 `shiftR` 32)
    getWord32 7 (x0, x1, x2, x3) = fromIntegral x3
    numWords32 _ = 8


-- | Class of objects allowing the extraction of 64-bit words from a given position.
class Word64Array a where
    getWord64 :: Int -> a -> Word64
    numWords64 :: a -> Int

instance Word64Array (Array2 Word32) where
    getWord64 0 (x0, x1) = hi `shiftL` 32 + lo where
        lo = fromIntegral x1 :: Word64
        hi = fromIntegral x0 :: Word64
    numWords64 _ = 1

instance Word64Array (Array4 Word32) where
    getWord64 0 (x0, x1, x2, x3) = hi `shiftL` 32 + lo where
        lo = fromIntegral x1 :: Word64
        hi = fromIntegral x0 :: Word64
    getWord64 1 (x0, x1, x2, x3) = hi `shiftL` 32 + lo where
        lo = fromIntegral x2 :: Word64
        hi = fromIntegral x3 :: Word64
    numWords64 _ = 2

instance Word64Array (Array2 Word64) where
    getWord64 0 (x0, x1) = x0
    getWord64 1 (x0, x1) = x1
    numWords64 _ = 2

instance Word64Array (Array4 Word64) where
    getWord64 0 (x0, x1, x2, x3) = x0
    getWord64 1 (x0, x1, x2, x3) = x1
    getWord64 2 (x0, x1, x2, x3) = x2
    getWord64 3 (x0, x1, x2, x3) = x3
    numWords64 _ = 4
