Media modules implementation draft
Donya Quick
Last modified: 29-May-2015

There are currently 3 kinds of media modules:
1. Read-only modules - they get data but don't send anything back.
2. Read-write modules - can both send and receive data.
3. Special modules for self-contained user interfaces that only need to write.

> module MediaModules (
>     MediaModule (..)
>     , UpdateFun
>     , ReadFun
>     , StopCond
>     , StopOp
>     , openChannel
>     , wait
>     ) where
> import Control.Concurrent
> import Control.Concurrent.STM

User-level type synonyms

> type UpdateFun a = a -> IO a
> type ReadFun a = a -> IO ()
> type StopCond a = a -> Bool
> type StopOp a = a -> IO ()
> data MediaModule a = MediaModule1 (StopCond a) (StopOp a) (ReadFun a) |  -- read only
>                      MediaModule2 (StopCond a) (StopOp a) (UpdateFun a) | -- read-write
>                      MediaModule3 ((a -> IO ()) -> IO()) -- special (for self-contained things like UISF)

Code for running a MediaModule. Pattern matching detects the type
of modle (read, read-write, or special).

> runMediaModule :: TVar a -> MediaModule a -> IO ()
> runMediaModule v m@(MediaModule1 sc so rf) = do
>     x <- atomically $ readTVar v -- read the value
>     if sc x then so x >> return () -- do we stop?
>     else rf x >> runMediaModule v m -- perform ReadFun operation and recurse
> runMediaModule v m@(MediaModule2 sc so uf) = do
>     x <- atomically $ readTVar v -- check current value
>     if sc x then so x >> return () -- is it a stop value?
>     else do  -- not a stop, so must recurse  
>         y <- uf x -- perform the update
>         atomically (writeTVar v y) -- write the new value
>         runMediaModule v m -- recurse
> runMediaModule v (MediaModule3 mm3) = mm3 (atomically . writeTVar v)


Implementation of channel opening for an arbitrary number of modules

> openChannel :: Int -> a -> [MediaModule a] -> IO ()
> openChannel n x0 ms = do
>     v <- newTVarIO x0 -- make the TVar
>     setNumCapabilities n -- how many cores to allow
>     runModules v ms -- run each media module

> runModules :: TVar a -> [MediaModule a] -> IO ()
> runModules v [m] = runMediaModule v m
> runModules v (m : ms) = forkIO (runMediaModule v m) >> runModules v ms
> runModules v [] = return ()


===================

> type Seconds = Double

> wait :: Seconds -> IO ()
> wait s = threadDelay $ round $ s * 1000000
