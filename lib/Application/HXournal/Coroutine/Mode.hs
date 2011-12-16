module Application.HXournal.Coroutine.Mode where

import Application.HXournal.Type.Event
import Application.HXournal.Type.Coroutine
import Application.HXournal.Type.XournalState
import Application.HXournal.Accessor

import Data.Xournal.Map

import Control.Monad.Trans

import Control.Applicative
import Control.Category
import Data.Label
import Prelude hiding ((.),id)

import Data.Xournal.Generic
import Graphics.Xournal.Render.BBoxMapPDF

modeChange :: MyEvent -> Iteratee MyEvent XournalStateIO ()
modeChange ToViewAppendMode = do 
  xstate <- getSt
  let xojstate = get xournalstate xstate
  case xojstate of 
    ViewAppendState _ -> return () 
    SelectState txoj -> do 
      liftIO $ putStrLn "to view append mode"
      putSt 
        . set xournalstate (ViewAppendState (GXournal (gselectTitle txoj) (gselectAll txoj)))
        $ xstate  
modeChange ToSelectMode = do 
  xstate <- getSt
  let xojstate = get xournalstate xstate
  case xojstate of 
    ViewAppendState xoj -> do 
      liftIO $ putStrLn "to select mode"
      putSt
        . set xournalstate (SelectState (GSelect (get g_title xoj) (gpages xoj) Nothing))
        $ xstate  
    SelectState _ -> return ()
modeChange _ = return ()
