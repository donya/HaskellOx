# HaskellOx
A MIDI message routing tool written in Haskell.

WINDOWS 10 USERS RUNNING THE EXECUTABLE : Microsoft really hates this
executable for some reason and may put you through multiple layers of
having to tell theOS that the executable is safe and to run it anyway.
This can happen when downloading the file (the browser may want to discard
it), andthere may be two more walls of OS obstruction when trying to
run the file (just keep clicking on options for more details and
eventually "run anyway" appears). I do apologize for this but I don't
know that there's anything I can do about it. Once you have run the
program once, Windows should stop complaining about it.

MAC USERS RUNNING THE EXECUTABLE: OS X may also complain at you that it
doesn't want to run this software because it's from a 3rd party.
Go to the executable in Finder, Ctrl+Click on the exectuable, select
"open," and then keep clicking the options to run it anyway. You should
only have to do this once.

This program was originally written to benchmark the performance
of MIDI message handling in Euterpea with the UISF library for graphics
in Haskell. There are command-line and GUI versions of the program.
The pre-compiled executables may not work on your operating system if
you have a different version that they were compiled with.

Ensure that all MIDI devices you want to connect are running and free
BEFORE you start HaskellOx. Device lists are static at program start
and if a device is in use the program may hang trying to access it
(mostly an issue on Windows).

Multithreading is no longer supported, but that should not significantly
impact performance.

Precompiled versions:
HaskellOx4.exe - for recent Windows 10 versions and newer machines (64-bit)
HaskellOx2016.exe - try this if the one above doesn't work and you have
                    an older Windows machine or an older Win10 version.
HaskellOx (no file extension) - for 64-bit Macs with 2019/later OS X version.
HaskellOx_2016 (no file extension) - try this if you have an older Mac or a
                                     really outdated version of OS X.s

WINDOWS INSTRUCTIONS:
You can double-click build.bat to compile to executable.
Compiling manually from command line: ghc HaskellOx4.lhs -O2
Execute in GUI mode: HaskellOx4.exe +RTS -N2
Execute command-line only: HaskellOx4.exe basic +RTS -N2

MAC INSTRUCTIONS:
On Mac, the MUI-based version of the program will not work due to
threading issues in the GLUT library (a dependency of HSoM).
Compile from a terminal with: ghc HaskellOx4.lhs -O2
Execute command-line only version: ./HaskellOx4 basic
