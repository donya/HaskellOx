HaskellOx Version 4
Donya Quick
Last modified: 12-June-2016
Updated to use Euterpea 2 and HSoM libraries

> {-# LANGUAGE Arrows #-}

> module Main where
> import Euterpea 
> import Euterpea.IO.MIDI.MidiIO hiding (Time)
> import FRP.UISF.UISF hiding (Time)
> import FRP.UISF
> import HSoM
> import System.Exit
> import System.IO
> import Control.Exception
> import Data.List
> import MediaModules
> import System.Environment

> main = do
>  hSetBuffering stdout NoBuffering
>  hSetBuffering stdin NoBuffering
>  hFlush stdout
>  args <- getArgs
>  devs <- getAllDevices
>  initializeMidi
>  if null args || head args =="mui" then openChannel 2 ([], [], False) [midiMM, MediaModule3 (muiFun devs)]
>  else openChannel 2 ([], [], False) [terminalMM devs, midiMM]

Simplified version of the above for a single option:

> main2 = do
>  hSetBuffering stdout NoBuffering
>  hSetBuffering stdin NoBuffering
>  hFlush stdout
>  args <- getArgs
>  devs <- getAllDevices
>  initializeMidi
>  let midiMM = MediaModule1 stop3 stopOpMidi readMidi
>  let muiMM = MediaModule3 (muiFun devs)
>  openChannel 2 ([], [], False) [midiMM, muiMM]

which is roughly the format:

main = do
    setupFunctions
	let m1 = MediaModule midiFunctions
	    m2 = MediaModule userInterfaceFunctions
    openChannel [m1,m2]
 
 
=====================

MIDI Back-end

MediaModule for it

> midiMM = MediaModule1 stop3 stopOpMidi readMidi

Stop operation (to be reused for the console interface)

> stop3 :: (a, b, Bool) -> Bool
> stop3 (_,_, x) = x

MIDI back-end termination

> stopOpMidi :: (a, b, Bool) -> IO ()
> stopOpMidi _ = handleCtrlC $ terminateMidi where 
>     handleCtrlC :: IO a -> IO a
>     handleCtrlC op = onException op terminateMidi

The main function to be looped by the MediaModule

> type MInfo = ([InputDeviceID], [OutputDeviceID], Bool)

> readMidi :: MInfo -> IO ()
> readMidi (devsIn, devsOut, stop) = if stop then return () else do
>     let f [] = Nothing
>         f xs = Just $ map (\m -> (0, Std $ m)) xs
>         g Nothing = []
>         g (Just (t,ms)) = ms
>     msgs <- sequence $ map getMidiInput devsIn -- get MIDI messages coming 
>     let outVal = f $ concatMap g msgs
>     sequence $ map (\d -> sendMidiOut d outVal) devsOut
>     return ()

> sendMidiOut :: OutputDeviceID -> Maybe [(Time, MidiMessage)] -> IO ()
> sendMidiOut dev ms = outputMidi dev >> 
>     maybe (return ()) (mapM_ (\(t,m) -> deliverMidiEvent dev (0, m))) ms

> getMidiInput :: InputDeviceID -> IO (Maybe (Time, [Message])) -- Codec.Midi message format
> getMidiInput dev = pollMidi dev

> foo [] = return ()
> foo ((d, Nothing):devs) = outputMidi d >> foo devs
> foo ((d, Just ms):devs) = do
>     outputMidi d >> mapM_ (\m -> deliverMidiEvent d (0, m)) ms >> foo devs


=========================

Command prompt or terminal interface

MediaModule for it

> terminalMM devs = MediaModule2 stop3 stopTerminal (updateTerminal devs)

Stop operation

> stopTerminal :: (a,b,Bool) -> IO ()
> stopTerminal _ = 
>     putStrLn "\nClosing...bye!\n\n"

Command formats for the user to add/remove connected devices.

> data Command = Add Int | Remove Int | Exit
>     deriving (Eq, Read, Show)

Type synonyms to make things a little cleaner.

> type InInfo = (InputDeviceID, DeviceInfo)
> type OutInfo = (OutputDeviceID, DeviceInfo)

Main function to be looped by the MediaModule

> updateTerminal :: ([InInfo], [OutInfo]) -> MInfo -> IO MInfo
> updateTerminal devs (devsIn, devsOut, stop) = if stop then return (devsIn, devsOut, stop) else do
>     printDevices devs
>     putStrLn ("Current inputs: "++show devsIn)
>     putStrLn ("Current outputs: "++show devsOut)
>     putStrLn "Command format: Add/Remove deviceID | Exit"
>     putStr "Command: "
>     s <- getLine
>     let cstr = reads s 
>     if null cstr then putStrLn "Bad command, please try again." >> updateTerminal devs (devsIn, devsOut, stop) 
>     else do
>         let (c,_) = head cstr
>         case c of Exit -> return (devsIn, devsOut, True) 
>                   Add i -> addDev i devs devsIn devsOut
>                   Remove i -> removeDev i devsIn devsOut

Helper code to add/remove and display devices
(this is a ugly due to the unsafeIn/Out IDs - would be worth redoing later)

> addDev i devs devsIn devsOut = 
>     let inID = unsafeInputID i
>         outID = unsafeOutputID i
>         isInput = elem inID $ map fst $ fst devs
>         isOutput = elem outID $ map fst $ snd devs
>     in  case (isInput, isOutput) of (True, _) -> return (nub (inID:devsIn), devsOut, False) 
>                                     (False, True) -> return (devsIn, nub (outID:devsOut), False) 
>                                     (False,False) -> return (devsIn, devsOut, False)

> removeDev i devsIn devsOut = 
>      let f1 = filter (/= unsafeInputID i)
>          f2 = filter (/= unsafeOutputID i)
>      in  return (f1 devsIn, f2 devsOut, False)

> printDevices (devsIn, devsOut) = do
>   let f (devid, devname) = "  "++show devid ++ "\t" ++ name devname ++ "\n"
>       strIn = concatMap f devsIn
>       strOut = concatMap f devsOut
>   putStrLn "\nInput devices: " >> putStrLn strIn 
>   putStrLn "Output devices: " >> putStrLn strOut


=====================

MUI version of interface

Note: the MediaModule has to be built inside the main function
since it needs access to the device list via getAllDevices.
  
> haskellOxUI (inDevs, outDevs) ioOp = proc _ -> do
>   inVal <- title "Input" $ checkGroup $ map nameFix inDevs -< ()
>   outVal <- title "Output" $ checkGroup $ map nameFix outDevs -< ()
>   _  <- liftAIO ioOp -< (inVal, outVal, False)
>   returnA -< ()

> nameFix (a,b) = (name b,a)

> oxParams ioOp = defaultMUIParams {uiSize=(300,300), uiTitle="Haskell Ox 3", uiClose=closeOpUI ioOp}

> closeOpUI :: (([a], [b], Bool) -> IO ()) -> IO ()
> closeOpUI ioOp = do
>     ioOp ([], [], True)
>     wait 2.0 -- wait a bit to end to let MIDI devices close
>     return ()

> muiFun devs ioOp = runMUI (oxParams ioOp) (haskellOxUI devs ioOp)

