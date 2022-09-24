# z80tor2k_dbt
is a module to run CP/M on Rabbit2000!

# How do we use it?
Example 1 run 62K CP/M from an awesome code!

emz80onr2k equ $FC00

ld sp,$FB00

ld hl,$F200

call emz80onr2k

*You have to write the bios for CP/M!
