-----------------------------------------------------------------------------
-- |
-- Module      : Hoodle.Coroutine.Highlighter 
-- Copyright   : (c) 2011-2013 Ian-Woo Kim
--
-- License     : BSD3
-- Maintainer  : Ian-Woo Kim <ianwookim@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-----------------------------------------------------------------------------

module Hoodle.Coroutine.Highlighter where

import Hoodle.Device 
import Hoodle.Type.Coroutine
import Hoodle.Type.Canvas
import Hoodle.Coroutine.Pen 

-- | 

highlighterStart :: CanvasId -> PointerCoord 
                 -> MainCoroutine (Maybe (Maybe (Maybe ())))
highlighterStart cid pcoord = penStart cid pcoord
