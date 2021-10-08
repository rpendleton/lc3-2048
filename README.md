# lc3-2048
An implementation of 2048 created using LC-3, an educational programming
language.

## History

This program was originally written for my final project while taking CS 2810
(Computer Organization and Architecture) at Utah Valley University. A few
semesters later, my professor asked if I would be willing to make my source
public as a resource to future students, which led to this GitHub project.

Since 2014, I've continued to explore LC-3 and have worked on [several related
projects](#related-projects). Although the source code remains largely similar to
what I submitted for my final project back in 2014, I've made a few
modifications to it as appropriate for these other projects.

Along those lines, since I don't use Windows anymore, I haven't tested any of my
recent modifications with the official LC-3 client. If you run into issues, I'd
recommend looking through the Git history for the original version.

## Quick Start

An online version of this program is available as part of my [JavaScript
simulator][lc3sim-js-web].

## Assembling and Running Manually

To execute LC-3 programs, they must be assembled into an object file and loaded
into a simulator. McGraw Hill's website for the [LC-3][lc3tools] includes
official tools that can assemble and run programs. Alternatively, you can find
numerous third-party assemblers and simulators online by searching for LC-3.

For the best experience with this program, I'd recommend a simulator that's
capable of handling ANSI escape sequences. For the rest of this quick start,
I'll be using the official *nix tools, but the concepts are similar for
Windows and other environments.

1. 	Download or compile the [lc3tools][lc3tools]. If you're using Mac, you can easily
	install them via my [Homebrew][homebrew] tap:

   	```
   	$ brew tap rpendleton/homebrew-tap
   	$ brew install lc3tools
   	```

	Alternatively, you can compile them yourself.

	```
	$ unzip lc3tools_v12.zip
	$ cd lc3tools
	$ ./configure --installdir /path/to/install/dir
	$ make
	$ make install
	```

2. 	After you've installed the lc3tools, you need to download the project and
	assemble the object file. You can do this using `lc3as`.

   	```
   	$ git clone https://github.com/rpendleton/lc3-2048.git
   	$ cd lc3-2048
   	$ lc3as 2048.asm
   	```

3.	Now that the object file is ready, all that's left is to load it into the
	simulator.

	```
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

	After starting the simulator and loading the object file, pressing `c` will
	start the program. The game takes advantage of ANSI terminal features, so if
	you're using a *nix operating system, make sure to press `y` when prompted.
	Otherwise, press `n` to avoid seeing garbage escape sequences.

[lc3sim-js-web]: https://rpendleton.github.io/lc3sim-js/
[lc3tools]: http://highered.mheducation.com/sites/0072467509/student_view0/lc-3_simulator.html
[homebrew]: http://brew.sh/

## Related Projects

* [justinmeiners/lc3-vm]: A tutorial on how to write your own LC-3 virtual machine
* [rpendleton/lc3sim-c][rpendleton/lc3sim-c]: A C implementation of the LC-3 virtual machine
* [rpendleton/lc3sim-js][rpendleton/lc3sim-js]: A JavaScript implementation of the LC-3 virtual machine

[justinmeiners/lc3-vm]: https://github.com/justinmeiners/lc3-vm
[rpendleton/lc3sim-c]: https://github.com/rpendleton/lc3sim-c
[rpendleton/lc3sim-js]: https://github.com/rpendleton/lc3sim-js
