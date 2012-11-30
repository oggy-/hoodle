{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

-- {-# LANGUAGE ExistentialQuantification, OverloadedStrings, 
--              FlexibleInstances, FlexibleContexts,  
--              TypeFamilies, CPP #-}

-----------------------------------------------------------------------------
-- |
-- Module      : Graphics.Hoodle.Render.PDFBackground 
-- Copyright   : (c) 2011, 2012 Ian-Woo Kim
--
-- License     : BSD3
-- Maintainer  : Ian-Woo Kim <ianwookim@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-----------------------------------------------------------------------------

module Graphics.Hoodle.Render.Background where

import           Control.Monad.State hiding (mapM_)
import           Data.ByteString hiding (putStrLn,filter)
import           Data.Foldable (mapM_)
import           Graphics.Rendering.Cairo
--
#ifdef POPPLER
import qualified Data.ByteString.Char8 as C
import           Data.Monoid
import qualified Graphics.UI.Gtk.Poppler.Document as Poppler
import qualified Graphics.UI.Gtk.Poppler.Page as PopplerPage
#endif
-- from hoodle-platform
import           Data.Hoodle.BBox
import           Data.Hoodle.Predefined 
--
import Prelude hiding (mapM_)
  
  
#ifdef POPPLER
popplerGetDocFromFile :: ByteString -> IO (Maybe Poppler.Document)
popplerGetDocFromFile fp = 
  Poppler.documentNewFromFile 
    (C.unpack ("file://localhost" `mappend` fp)) Nothing 
#endif

#ifdef POPPLER             
popplerGetPageFromDoc :: Poppler.Document 
                      -> Int -- ^ page number 
                      -> IO (Maybe Poppler.Page, Maybe Surface)
popplerGetPageFromDoc doc pn = do   
  -- n <- Poppler.documentGetNPages doc  
  -- putStrLn $ "pages : " ++ (show n)
  -- putStrLn $ "current page = " ++ show pn
  pg <- Poppler.documentGetPage doc (pn-1) 
  (w,h) <- PopplerPage.pageGetSize pg
  sfc <- createImageSurface FormatARGB32 (floor w) (floor h)
  renderWith sfc $ do   
    setSourceRGBA 1 1 1 1
    rectangle 0 0 w h 
    fill
    PopplerPage.pageRender pg
  return (Just pg, Just sfc)
#endif

-- | draw ruling all 
drawRuling :: Double -> Double -> ByteString -> Render () 
drawRuling w h style = do
  let drawHorizRules = do 
      let (r,g,b,a) = predefined_RULING_COLOR         
      setSourceRGBA r g b a 
      setLineWidth predefined_RULING_THICKNESS
      let drawonerule y = do 
            moveTo 0 y 
            lineTo w y
            stroke  
      mapM_ drawonerule [ predefined_RULING_TOPMARGIN 
                        , predefined_RULING_TOPMARGIN+predefined_RULING_SPACING
                        .. 
                        h-1 ]
  case style of 
    "plain" -> return () 
    "lined" -> do 
      drawHorizRules
      let (r2,g2,b2,a2) = predefined_RULING_MARGIN_COLOR
      setSourceRGBA r2 g2 b2 a2 
      setLineWidth predefined_RULING_THICKNESS
      moveTo predefined_RULING_LEFTMARGIN 0 
      lineTo predefined_RULING_LEFTMARGIN h
      stroke
    "ruled" -> drawHorizRules 
    "graph" -> do 
      let (r3,g3,b3,a3) = predefined_RULING_COLOR 
      setSourceRGBA r3 g3 b3 a3 
      setLineWidth predefined_RULING_THICKNESS
      let drawonegraphvert x = do 
            moveTo x 0 
            lineTo x h
            stroke  
      let drawonegraphhoriz y = do 
            moveTo 0 y
            lineTo w y
            stroke
      mapM_ drawonegraphvert  [0,predefined_RULING_GRAPHSPACING..w-1] 
      mapM_ drawonegraphhoriz [0,predefined_RULING_GRAPHSPACING..h-1]
    _ -> return ()     



-- | draw ruling  in bbox 
drawRuling_InBBox :: BBox -> Double -> Double -> ByteString -> Render () 
drawRuling_InBBox (BBox (x1,y1) (x2,y2)) w h style = do
  let drawonerule y = do 
        moveTo x1 y 
        lineTo x2 y
        stroke  
  let drawonegraphvert x = do 
        moveTo x y1 
        lineTo x y2
        stroke  
  let drawonegraphhoriz y = do 
        moveTo x1 y
        lineTo x2 y
        stroke
      fullRuleYs = [ predefined_RULING_TOPMARGIN 
                   , predefined_RULING_TOPMARGIN+predefined_RULING_SPACING
                   .. 
                   h-1 ]
      ruleYs = filter (\y-> (y <= y2) && (y >= y1)) fullRuleYs
      fullGraphXs = [0,predefined_RULING_GRAPHSPACING..w-1]          
      fullGraphYs = [0,predefined_RULING_GRAPHSPACING..h-1]
      graphXs = filter (\x->(x<=x2)&&(x>=x1)) fullGraphXs
      graphYs = filter (\y->(y<=y2)&&(y>=y1)) fullGraphYs 
  let drawHorizRules = do 
      let (r,g,b,a) = predefined_RULING_COLOR         
      setSourceRGBA r g b a 
      setLineWidth predefined_RULING_THICKNESS
      mapM_ drawonerule ruleYs
  case style of 
    "plain" -> return () 
    "lined" -> do 
      drawHorizRules
      let (r2,g2,b2,a2) = predefined_RULING_MARGIN_COLOR
      setSourceRGBA r2 g2 b2 a2 
      setLineWidth predefined_RULING_THICKNESS
      moveTo predefined_RULING_LEFTMARGIN 0 
      lineTo predefined_RULING_LEFTMARGIN h
      stroke
    "ruled" -> drawHorizRules 
    "graph" -> do 
      let (r3,g3,b3,a3) = predefined_RULING_COLOR 
      setSourceRGBA r3 g3 b3 a3 
      setLineWidth predefined_RULING_THICKNESS
      mapM_ drawonegraphvert  graphXs 
      mapM_ drawonegraphhoriz graphYs
    _ -> return ()     




-- instance RenderOptionable (BackgroundPDFDrawable,Dimension) where
      

