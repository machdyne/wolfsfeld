# Wolfsfeld

Wolfsfeld is an ultra-low-power stand-alone open-source handheld FPGA computer with a minimal interface intended for educational purposes and survival computing.

![Wolsfeld](https://github.com/machdyne/wolfsfeld/blob/47986875d0e0c8f5599bc599d6db0b98eefcbdc3/wolfsfeld.png)

Wolfsfeld currently boots to BIOS and can perform some tests. The OS isn't working yet.

The Wolfsfeld SOC is a partial fork of [Zeitlos](https://github.com/machdyne/zeitlos).

### LLM-generated code

To the extent that there is LLM-generated code in this repo, it should be space indented. Any space indented code should be carefully audited and then converted to tabs (eventually).

## License

The contents of this repo are released under the [Lone Dynamics Open License](LICENSE.md) with the following exceptions:

- rtl/cpu/picorv32 uses the ISC license.
- rtl/ext/uart16550 uses the LGPL license.
