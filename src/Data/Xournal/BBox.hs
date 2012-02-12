{-# LANGUAGE TypeFamilies, StandaloneDeriving #-}

-----------------------------------------------------------------------------
-- |
-- Module      : Data.Xournal.BBox 
-- Copyright   : (c) 2011, 2012 Ian-Woo Kim
--
-- License     : BSD3
-- Maintainer  : Ian-Woo Kim <ianwookim@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-----------------------------------------------------------------------------

module Data.Xournal.BBox where

import Control.Applicative 
import Control.Monad
import Data.ByteString hiding (map,maximum,minimum)
-- import qualified Data.Sequence as Seq
import Data.Xournal.Generic
import Data.Xournal.Simple
import Data.Xournal.Util
import Data.Strict.Tuple 
import qualified Data.Foldable as F
import Data.Monoid
import Prelude hiding (fst,snd)
import qualified Prelude as Prelude (fst,snd)


-- | bounding box type 

data BBox = BBox { bbox_upperleft :: (Double,Double) 
                 , bbox_lowerright :: (Double,Double) } 
          deriving (Show,Eq)

-- | 

data StrokeBBox = StrokeBBox { strokebbox_stroke :: Stroke 
                             , strokebbox_bbox :: BBox } 
                deriving (Show)
  
{-  
  StrokeBBox { strokebbox_tool :: ByteString
                             , strokebbox_color :: ByteString 
                             , strokebbox_width :: Double
                             , strokebbox_data :: [Pair Double Double] 
                             , strokebbox_bbox :: BBox } -}

type TLayerBBox = GLayer [] StrokeBBox 

type TPageBBox = GPage Background [] TLayerBBox 

type TXournalBBox = GXournal [] TPageBBox

instance GStrokeable StrokeBBox where  
  gFromStroke = mkStrokeBBoxFromStroke 
  gToStroke = strokeFromStrokeBBox

mkbbox :: [Pair Double Double] -> BBox 
mkbbox lst = let xs = map fst lst 
                 ys = map snd lst
             in  BBox { bbox_upperleft = (minimum xs, minimum ys)
                      , bbox_lowerright = (maximum xs, maximum ys) } 

mkbboxF :: (F.Foldable m, Functor m) => m (Double,Double) -> BBox 
mkbboxF lst = 
  let xs = fmap Prelude.fst lst  
      ys = fmap Prelude.snd lst 
  in BBox{bbox_upperleft=(F.minimum xs, F.minimum ys)
         ,bbox_lowerright=(F.maximum xs, F.maximum ys)}

bboxFromStroke :: Stroke -> BBox 
bboxFromStroke (Stroke _ _ _ dat) = mkbbox dat 
bboxFromStroke (VWStroke _ _ dat) = 
  let dat' = map ((,) <$> fst3 <*> snd3) dat 
  in mkbboxF dat'   
   

dimToBBox :: Dimension -> BBox 
dimToBBox (Dim w h) = BBox (0,0) (w,h)

-- | transform BBox
         
xformBBox :: ((Double,Double) -> (Double,Double)) -> BBox -> BBox 
xformBBox f (BBox c1 c2) = BBox (f c1) (f c2)

-- | 

moveBBoxToOrigin :: BBox -> BBox 
moveBBoxToOrigin (BBox (x0,y0) (x1,y1)) = BBox (0,0) (x1-x0,y1-y0)

-- |

moveBBoxByOffset :: (Double,Double) -> BBox -> BBox 
moveBBoxByOffset (xoff,yoff) (BBox (x0,y0) (x1,y1)) = BBox (x0+xoff,y0+yoff) (x1+xoff,y1+yoff)

moveBBoxULCornerTo :: (Double,Double) -> BBox -> BBox 
moveBBoxULCornerTo (x,y) b@(BBox (x0,y0) _) = moveBBoxByOffset (x-x0,y-y0) b 

intersectBBox :: BBox -> BBox -> Maybe BBox
intersectBBox (BBox (x1,y1) (x2,y2)) (BBox (x3,y3) (x4,y4)) = do 
  guard $ (x1 <= x3 && x3 <= x2) || (x3 <= x1 && x1 <= x4 ) 
  guard $ (y1 <= y3 && y3 <= y2) || (y3 <= y1 && y1 <= y4 )
  let x5 = if x1 <= x3 then x3 else x1 
      y5 = if y1 <= y3 then y3 else y1 
      x6 = min x2 x4 
      y6 = min y2 y4
  return (BBox (x5,y5) (x6,y6))
  
     
unionBBox :: BBox -> BBox -> BBox
unionBBox (BBox (x1,y1) (x2,y2)) (BBox (x3,y3) (x4,y4)) = 
  let x5 = if x1 < x3 then x1 else x3
      y5 = if y1 < y3 then y1 else y3
      x6 = if x2 < x4 then x4 else x2
      y6 = if y2 < y4 then y4 else y2
  in BBox (x5,y5) (x6,y6)
  
     
data ULMaybe a = Bottom | Middle a | Top      
     
deriving instance Show a => Show (ULMaybe a)

deriving instance Eq a => Eq (ULMaybe a)
                                     
newtype IntersectBBox = Intersect { unIntersect :: ULMaybe BBox } 
                        deriving (Show,Eq)

newtype UnionBBox = Union { unUnion :: ULMaybe BBox }
                    deriving (Show,Eq)
     
instance Monoid (IntersectBBox) where 
  (Intersect Bottom) `mappend` _ = Intersect Bottom
  _ `mappend` (Intersect Bottom) = Intersect Bottom 
  (Intersect Top) `mappend` x = x 
  x `mappend` (Intersect Top) = x 
  (Intersect (Middle x)) `mappend` (Intersect (Middle y)) = 
    maybe (Intersect Bottom) (Intersect . Middle) (x `intersectBBox` y)
  mempty = Intersect Top 
  
instance Monoid (UnionBBox) where
  (Union Bottom) `mappend` x = x 
  x `mappend` (Union Bottom) = x
  (Union Top) `mappend` _ = Union Top
  _ `mappend` (Union Top) = Union Top 
  (Union (Middle x)) `mappend` (Union (Middle y)) = Union (Middle (x `unionBBox` y))
  mempty = Union Bottom
  
class Maybeable a where
  type ElemType a :: *
  toMaybe :: a -> Maybe (ElemType a) 
  fromMaybe :: Maybe (ElemType a) -> a 
  
instance Maybeable IntersectBBox where
  type ElemType IntersectBBox = BBox
  toMaybe (Intersect Bottom) = Nothing  
  toMaybe (Intersect Top) = Nothing 
  toMaybe (Intersect (Middle x)) = Just x 
  fromMaybe Nothing = Intersect Top 
  fromMaybe (Just x) = Intersect (Middle x)
  
instance Maybeable UnionBBox where
  type ElemType UnionBBox = BBox
  toMaybe (Union Bottom) = Nothing 
  toMaybe (Union Top) = Nothing 
  toMaybe (Union (Middle x)) = Just x 
  fromMaybe Nothing = Union Top 
  fromMaybe (Just x) = Union (Middle x)


mkStrokeBBoxFromStroke :: Stroke -> StrokeBBox
mkStrokeBBoxFromStroke str = 
  StrokeBBox { strokebbox_stroke = str 
             , strokebbox_bbox = bboxFromStroke str
             } 

strokeFromStrokeBBox :: StrokeBBox -> Stroke 
strokeFromStrokeBBox = strokebbox_stroke 


