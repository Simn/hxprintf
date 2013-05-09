hxprintf
========

printf for haxe

Supported syntax: $[flags][width][.precision]type

Supported types:
 * `i`: Int
 * `f`: Float
 * `s`: String
 * `b`: Bool

Supported flags:
 * 0: pad numbers with 0 instead of space
 * [space] : add leading space to positive numbers
 * +: add leading + to positive numbers
 * -: align left
 * #: alternate form (only for floats at the moment)

Refer to http://www.cplusplus.com/reference/cstdio/printf/ for details

See https://github.com/Simn/hxprintf/blob/master/src/Main.hx for examples