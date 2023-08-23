# mips-architecture
A learning project undertaken after finishing my degree to help me learn VHDL. The project implements a MIPs processor.


# mips-assembler

To enable more useful verification, an assembler has been written in Python. To see how to use the script, simply run the script with the following argument:
```
python3 assembler.py --help
```
An example command uses the tool to assembles ``main.asm``, using the description file ``description.json``, into a program, ``program.hex``, with its corresponding memory initialisation file, ``data_memory.hex``. The command will also generate a VHDL package that contains registers and instructions as enumerated types for use in the users HDL.<br>
```
python3 assembler.py -s main.asm -d description.json -m "data_memory.hex" -o "program.hex" -v "vhdl"
```
