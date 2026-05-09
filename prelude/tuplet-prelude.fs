\ === Tuplet prelude (sw-cor24-forth flavor) ===
\
\ Each line is sent over UART to the forth.s REPL. The REPL evaluates one
\ line at a time, so every : ... ; definition lives on a single line.
\ Words come from forth.s's WORDS list (no 2DUP, no VARIABLE, no DOES>).
\ Lines beginning with `\ ` are comments and are sent as-is.
\
\ Max / min scalar.
: max OVER OVER < IF SWAP THEN DROP ;
: min OVER OVER < IF DROP ELSE SWAP DROP THEN ;
\
\ Max / min pair: (hi lo) and (lo hi).
: max2 OVER OVER < IF SWAP THEN ;
: min2 OVER OVER < 0= IF SWAP THEN ;
\
\ Single-output integer division; div2 is /MOD itself.
: div /MOD SWAP DROP ;
\
\ plot ( x y color c% -- success? ) — minimal builtin: print four args
\ separated by spaces and a newline, return -1 (Forth true).
: plot >R >R >R >R R> . R> . R> . R> . CR -1 ;
