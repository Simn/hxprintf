import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;
using haxe.macro.ExprTools;

typedef PlaceholderConfig = {
	plus:Bool,
	space:Bool,
	minus:Bool,
	zero:Bool,
	alt:Bool,
	width:Int,
	precision:Int
}

enum ParserState {
	Normal;
	Placeholder;
	Width;
	Precision;
}

enum Value<T> {
	Int:Value<Int>;
	Str:Value<String>;
	Bool:Value<Bool>;
	Float:Value<Float>;
}

enum Fmt<A,B> {
	Lit(s:String):Fmt<A,A>;
	Val<C>(v:Value<C>, cfg:PlaceholderConfig):Fmt<A,C->A>;
	Cat<C>(a:Fmt<B,C>, b:Fmt<A,B>):Fmt<A,C>;
}

class Printf {

	macro static public function sprintf(fmt:ExprOf<String>, args:Array<Expr>) {
		var s = switch(fmt.expr) {
			case EConst(CString(s)): s;
			case _: return macro Printf.sprintfRuntime($fmt, $a{args});
		}
		var f = parse(s, fmt.pos);
		var e = macro Printf.eval($v{f}, function(x) return x);
		for (arg in args)
			e = macro $e($arg);
		return e;
	}
	
	macro static public function printf(fmt:ExprOf<String>, args:Array<Expr>) {
		args.unshift(fmt);
		return macro @:pos(Context.currentPos()) trace(Printf.sprintf($a{args}));
	}
	
	static function parse(s:String, pos:Position) {
		var buf = new StringBuf();
		var p = 0;
		var c = s.fastCodeAt(p);
		var state = Normal;
		var out:Fmt<Dynamic, Dynamic> = Lit("");
		#if macro
		function mkPos() {
			var pos = Context.getPosInfos(pos);
			pos.min += p + 1;
			pos.max = pos.min + 1;
			return Context.makePosition(pos);
		}
		function error(s, pos) {
			Context.error(s, pos);
		}
		#else
		function mkPos() {
			return null;
		}
		function error(s, pos) {
			throw s;
		}
		#end
		function defaultConfig():PlaceholderConfig {
			return {
				plus: false,
				space: false,
				minus: false,
				zero: false,
				alt: false,
				width: -1,
				precision: -1,
			}
		}
		var config = defaultConfig();
		while (!StringTools.isEof(c)) {
			switch [c,state] {
				case ['$'.code, Normal]:
					out = Cat(out, Lit(buf.toString()));
					buf = new StringBuf();
					config = defaultConfig();
					state = Placeholder;
				case [_, Normal]:
					buf.addChar(c);
				case ['$'.code, Placeholder]:
					buf.add("$");
					state = Normal;
				case ['+'.code, Placeholder] if (!config.plus):
					config.plus = true;
				case [' '.code, Placeholder] if (!config.space):
					config.space = true;
				case ['#'.code, Placeholder] if (!config.space):
					config.alt = true;
				case ['-'.code, Placeholder] if (!config.minus):
					if (config.zero) error("Conflicting flags: - and 0", mkPos());
					config.minus = true;
				case ['0'.code, Placeholder] if (!config.zero):
					if (config.minus) error("Conflicting flags: - and 0", mkPos());
					config.zero = true;
				case ['1'.code | '2'.code | '3'.code | '4'.code | '5'.code | '6'.code | '7'.code | '8'.code | '9'.code, Placeholder]:
					config.width = c - 48;
					state = Width;
				case ['0'.code | '1'.code | '2'.code | '3'.code | '4'.code | '5'.code | '6'.code | '7'.code | '8'.code | '9'.code, Width]:
					config.width = config.width * 10 + (c - 48);
				case ['.'.code, Width | Placeholder]:
					config.precision = 0;
					state = Precision;
				case ['0'.code | '1'.code | '2'.code | '3'.code | '4'.code | '5'.code | '6'.code | '7'.code | '8'.code | '9'.code, Precision]:
					config.precision = config.precision * 10 + (c - 48);
				case ['i'.code | 'd'.code, Placeholder | Width | Precision]:
					if (config.precision != -1 && config.zero) error("Conflicting flags: 0 cannot be used with precision on i", mkPos());
					out = Cat(out, Val(Int, config));
					state = Normal;
				case ['s'.code, Placeholder | Width | Precision]:
					out = Cat(out, Val(Str, config));
					state = Normal;
				case ['b'.code, Placeholder | Width | Precision]:
					out = Cat(out, Val(Bool, config));
					state = Normal;
				case ['f'.code, Placeholder | Width | Precision]:
					out = Cat(out, Val(Float, config));
					state = Normal;
				case _:
					error('Unexpected ${String.fromCharCode(c)}', mkPos());
			}
			c = s.fastCodeAt(++p);
		}
		return Cat(out, Lit(buf.toString()));
	}
		
	static function sprintfRuntime(fmt:String, args:Array<Dynamic>) {
		var f = parse(fmt, null);
		var func:Dynamic = eval(f, function(x) return x);
		for (arg in args) {
			func = func(arg);
		}
		return func;
	}
	
	static function eval<A,B>(fmt:Fmt<A,B>, f:String -> A):B {
		function round(s:String, d, f) {
			var i = s.indexOf(".");
			if (i == -1) {
				if (f || d > 0)
					return (s + ".").rpad("0", d + s.length + 1);
				else
					return s;
			}
			return (s.substr(0, i) + s.substr(i, d + 1)).rpad("0", i + d + 1);
		}
		function handleNumeric(s:String, x:Float, cfg:PlaceholderConfig) {
			if (x > 0 && cfg.plus) s = "+" + s;
			else if (x > 0 && cfg.space) s = " " + s;
			if (s.length < cfg.width) {
				if (cfg.minus)
					s = s.rpad(" ", cfg.width);
				else
					s = s.lpad(cfg.zero ? "0" : " ", cfg.width);
			}
			return s;
		}
		return switch(fmt) {
			case Lit(str):
				f(str);
			case Val(Float, cfg):
				function(x) {
					var s = Std.string(x);
					s = round(s, cfg.precision == -1 ? 6 : cfg.precision, cfg.alt);
					s = handleNumeric(s, x, cfg);
					return f(s);
				}
			case Val(Int, cfg):
				function(x) {
					var s = Std.string(x);
					if (cfg.precision != -1) {
						cfg.zero = false;
						s = s.lpad("0", cfg.precision);
					}
					s = handleNumeric(s, x, cfg);
					return f(s);
				}
			case Val(Str, cfg) | Val(Bool, cfg):
				function(x) {
					var s = Std.string(x);
					if (cfg.precision != -1)
						s = s.substr(0, cfg.precision);
					if (cfg.width != -1) {
						if (cfg.minus)
							s = s.rpad(" ", cfg.width);
						else
							s = s.lpad(" ", cfg.width);
					}
					return f(s);
				}
			case Cat(a, b):
				eval(a, function(sa) return eval(b, function(sb) return f(sa + sb)));
		}
	}
}