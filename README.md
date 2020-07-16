# bash-arduino
bash environment and utilities for simplifying arduino-cli interactions

```
ino version 0.1.0 usage:

ino -l
ino -a [PATTERN]
ino -b FQBN [-p PORT [-u] [-t]] [-k] [-s SKETCH] [-v LEVEL] [-w]
ino -x [-b FQBN] [-p PORT [-u] [-t]] [-k] [-s SKETCH] [-v LEVEL]
ino cli ...


options:

-l              - list all boards connected to the system

-a [PATTERN]    - list all known fully-qualified board names, optionally filtered
                  by those matching PATTERN

-b FQBN         - use board with given FQBN

-p PORT         - upload to device connected to serial port at path PORT

-u              - upload without recompiling (requires: -p)

-t              - verify executable after uploading (requires: -p)

-c              - recompile sketch without uploading (verify sketch will compile).

-s SKETCH       - compile/upload sketch at path SKETCH, or uses $PWD if -s option
                  is not provided

-v LEVEL        - use verbosity LEVEL (trace debug info warning error fatal panic)

-w              - write configuration to file for use with autoconfig (-x)

-x              - use FQBN/PORT in configuration file defined in sketch directory

cli ...         - invoke arduino-cli, passing all arguments on as subcommands, but
                  using the configuration file associated with this environment
```
