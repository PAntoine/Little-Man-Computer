Little Man Computer
===================

By Peter Antoine
Copyright (c) 2011 Peter Antoine
Released under the Artistic Licence

Why?
----

Because I can. That's it.

More verbosely, this version is simply so that I can write both a compiler and a
processor. I have at least 5 designs for processors and none of them
ever get more than half-way finished (mostly as they are too big and
I get board). So this is a perfect processor to implement as it is
quite small and the compiler only took me a day to code.

What?
-----

This is mostly based on the version by York University, Canada.

The original LMC was created by Dr. Stuart Madrick and is a basic 
representation of a von Neumann architecture machine. It purpose was
to show the basic workings of a computer without all the logicy stuff
getting in the way.

Search Wikipedia for it and you will get the gist of what it is about.

So?
---

This does slight deviate from the LMC as specified on Wikipedia as it is
HEX (makes it easier for me to code) and the size of the mailboxes are
defined by the users.

The memory organisation is a little weird. The standard Lda and Sta 
commands will only write to the bottom 256 bytes of memory. The same
with the br? commands. This simply a hack to be able to have a boot
loader running from ROM, so the page read/write (PLD and PST) functions
will be able to access a bigger memory space. Also, note that the PC
will handle the larder address space so that the bootload/bootstrap
code can run from ROM.

Also, will need to be able to handle exceptions and interrupts.

The instruction format will be as follows:

                        +--------+--------+
                        | op code|operand |
                        +--------+--------+

The following op codes are supported:

	0x00		Halt
	0x01		Add
	0x02		Sub
	0x03		Sta (store)
	0x04		Lda (load)
	0x05		Bra	(branch conditional)
	0x06		Brz (branch if zero)
	0x07		Brp	(branch if positive)
	0x08		INP	(input from input port)
	0x09		OUT (outputto output port)

	Non-standard operand:
	0x0a		INT (interrupt)
	0x0b		IRT (return from interrupt)
	0x0c		LPG	(load page register)
	0x0d		PLO	(page load)
	0x0e		PST	(page store)

	Registers:

	INBOX = external read port
	OUTBOX = external write port
	ACCUMULATOR

	(non-standard register)
	IVECTOR = interrupt vector.
	PAGE_REG = 16 bit access register.
 
What is implemented?
--------------------

The basic LMC works (in simulation - Xilinx ISE) and builds for the
FPGA (basic spartan3 - XC3S50).

If you build the Bridge Chip,RAM,ROM,LMC and the test_bed it will run
an example program that is compiled into the RAM/ROM. (PS: ignore the
ROM I am in the middle of implementing the boot loader - but I'll have
to extend the instruction set to make it work).

This will show you the basics of the code working. I have hard-coded the
INP data in the bridge chip as I need to port a UART for serial control
from another design so the PC can drive this.

PS: I am only half way thought implementing the PST/PLD functions as I have
run out of time that I should not have spent on this. :)

What's left to do?
------------------

I need to implement all the hardware features in the bridge chip and 
extended to instructions to let me be able to boot from rom and leave
the RAM empty as it should be. Also, need to access external RAM, so
the bridge chip will need to be extended to do this.

I have started some of the above but I am unlikely to finish it as I
have other things I should be doing and not p*ssing about with pointless
processors.

But, it has been fun at last to actually see instructions running on
a processor that I designed*.

Anyway,

That's it, I might update this someday and finish properly, but I have
real work I should be doing. [back to being a start-up :) ]

Enjoy, the stupidity of the above.
Peter Antoine.

7th March 2011

