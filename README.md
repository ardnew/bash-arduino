# bash-arduino
### Bash environment and utilities for simplifying [arduino-cli](https://github.com/arduino/arduino-cli) interactions

Last tested with [arduino/arduino-cli](https://github.com/arduino/arduino-cli) version 0.11.0 ([466c8c2](https://github.com/arduino/arduino-cli/commit/466c8c2f8471736d755079ec0e6e2a4a19dad413)).

## Example usage for primary functions

The following assume the `arduino-cli.env.bash` script has been sourced already. If not, see [Installation](#installation) below.
```sh
# list all connected USB devices and their                          
$ ino -l

[ ... TODO ... ]
```

## Installation

No dependencies (other than `arduino-cli` of course) are required. 

1. Fetch the repo

```sh
# clone (create) `bash-arduino` repo in current directory
$ git clone https://github.com/ardnew/bash-arduino 
```

2. Configure paths in `bash-arduino/arduino-cli.env.bash`

```sh
#  helper function included for posterity (not required)
arduino-prefix() { echo "/usr/local"; }       

# +REQUIRED
# directory containing config files, target BSP(s), library indices, etc. 
# Equivalent to the traditional Arduino IDE's `~/.arduino15` directory, but
# was changed to `${XDG_CONFIG_HOME}` in `arduino-cli`. 
# My installation uses neither of these. A moral decision.
arduino-root() { echo "${prefix}/lib/arduino"; }  

# +REQUIRED
# Path to directory containing all of your sketch root directories.
arduino-sketchbook() { echo "${prefix}/src/arduino"; }   

# +REQUIRED
# Path to the arduino-cli-specific config.yaml.
arduino-cli-config-file() { echo "${root}/config.yaml"; }     
```
There are a number of other parameters you can modify to your liking, but their defaults are relatively safe and can be used as-is.

3. Finally, decide how you'd like to load the script functions at runtime.

- Always load script automatically:

Add a line like `. '/path/to/arduino-cli.env.bash'` to your `~/.bashrc`.

- Load script only when requested explicitly:

Add an alias like `alias ino-source=". '/path/to/arduino-cli.env.bash'"` to your `~/.bashrc`. Then just run the command `ino-source` to instantly pull in `arduino-cli.env.bash` functionality from wherever you are.

## Help
```
ino version 0.2.0 usage:

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
