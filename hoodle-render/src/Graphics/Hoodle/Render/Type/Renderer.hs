-----------------------------------------------------------------------------
-- |
-- Module      : Graphics.Hoodle.Render.Type.Renderer
-- Copyright   : (c) 2014 Ian-Woo Kim
--
-- License     : GPL-3
-- Maintainer  : Ian-Woo Kim <ianwookim@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-----------------------------------------------------------------------------

module Graphics.Hoodle.Render.Type.Renderer where

import           Control.Concurrent.STM
import           Control.Monad.Trans.Reader
import           Data.UUID
import qualified Graphics.Rendering.Cairo as Cairo
--

type Renderer = ReaderT ((UUID, (Double,Cairo.Surface)) -> IO (), TVar Int) IO

