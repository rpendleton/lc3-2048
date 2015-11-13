# lc3-2048
An implementation of 2048 created using LC-3, an educational programming
language.

## Quick Start

To execute LC-3 programs, they must be assembled into an object file and loaded
into a simulator. The tools necessary to do this can be found on McGraw Hill's
website for the [LC-3][1]. The following instructions are for *nix operating
systems, but the concepts are similar for Windows.

1. 	Download or compile the [lc3tools][1]. If you're using Mac, you can easily
	install them via my [Homebrew][2] tap:

   	```bash
   	$ brew tap rpendleton/homebrew-tap
   	$ brew install lc3tools
   	```

	Alternatively, you can compile them yourself.

	```bash
	$ unzip lc3tools_v12.zip
	$ cd lc3tools
	$ ./configure --instaldir=/path/to/install/dir
	$ make
	$ make install
	```

2. 	After you've installed the lc3tools, you need to download the project and
	assemble the object file. You can do this using `lc3as`.

   	```bash
   	$ git clone https://github.com/rpendleton/lc3-2048.git
   	$ cd lc3-2048
   	$ lc3as 2048.asm
   	```

3.	Now that the object file is ready, all that's left is to load it into the
	simulator.

	```bash
	$ lc3sim 2048.obj
	...
	(lc3sim) c
	Control the game using WASD keys.
	Are you on an ANSI terminal (y/n)? y
	+--------------------------+
	|                          |
	|                          |
	|                          |
	|                     2    |
	|                          |
	|   2                      |
	|                          |
	|                          |
	|                          |
	+--------------------------+
	```

	After starting the simulator and loading the object file,
	pressing "c" will start the program. The game takes advantage of ANSI
	terminal features, so if you're using a *nix operating system, make sure to
	press "y" when prompted. Otherwise, press "n" to avoid seeing garbage
	escape sequences.

[1]: http://highered.mheducation.com/sites/0072467509/student_view0/lc-3_simulator.html
[2]: http://brew.sh/
