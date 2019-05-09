# HaskellOx
A MIDI message routing tool written in Haskell. 

This program was originally written to benchmark the performance of MIDI message handling in Euterpea with the 
UISF library for graphics in Haskell. There are command-line and GUI versions of the program.
The pre-compiled executables may not work on your operating system if you have 
a different version that they were compiled with. 

WINDOWS INSTRUCTIONS: 
You can double-click build.bat to compile to executable.
Compiling manually from command line: ghc HaskellOx4.lhs -O2 -rtsopts -threaded
Execute in GUI mode: HaskellOx4.exe +RTS -N2
Execute command-line only: HaskellOx4.exe basic +RTS -N2

MAC INSTRUCTIONS: 
On Mac, the MUI-based version of the program will not work due to
threading issues in the GLUT library (a dependency of HSoM).
Compile from a terminal with: ghc HaskellOx4.lhs -O2 -rtsopts -threaded
Execute command-line only version: ./HaskellOx4 basic +RTS -N2
