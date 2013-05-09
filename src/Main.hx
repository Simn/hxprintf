import haxe.PosInfos;
import Printf.sprintf;

class Main {
	static var count = 0;
	
	static public function main () {
		eq(sprintf("$i", 123456789), "123456789");
		eq(sprintf("$+i", 123456789), "+123456789");
		eq(sprintf("$+i", -123456789), "-123456789");
		eq(sprintf("$ i", 123456789), " 123456789");
		eq(sprintf("$ i", -123456789), "-123456789");
		eq(sprintf("$10i", 123456789), " 123456789");
		eq(sprintf("$010i", 123456789), "0123456789");
		eq(sprintf("$-10i", 123456789), "123456789 ");
		eq(sprintf("$.10i", 123456789), "0123456789");
		eq(sprintf("$15.10i", 123456789), "     0123456789");
		eq(sprintf("$+15.10i", 123456789), "    +0123456789");
		eq(sprintf("$f", 123.45678), "123.456780");
		eq(sprintf("$f", 123), "123.000000");
		eq(sprintf("$.0f", 123), "123");
		eq(sprintf("$#.0f", 123), "123.");
		eq(sprintf("$+f", 123.45678), "+123.456780");
		eq(sprintf("$+f", -123.45678), "-123.456780");
		eq(sprintf("$ f", 123.45678), " 123.456780");
		eq(sprintf("$ f", -123.45678), "-123.456780");
		eq(sprintf("$15f", 123.45678), "     123.456780");
		eq(sprintf("$015f", 123.45678), "00000123.456780");
		eq(sprintf("$-15f", 123.45678), "123.456780     ");
		eq(sprintf("$015.12f", 123.45678), "123.456780000000");
		eq(sprintf("$s", "foobar"), "foobar");
		eq(sprintf("$10s", "foobar"), "    foobar");
		eq(sprintf("$.3s", "foobar"), "foo");
		eq(sprintf("$10.3s", "foobar"), "       foo");
		eq(sprintf("$-s", "foobar"), "foobar");
		eq(sprintf("$-10s", "foobar"), "foobar    ");
		eq(sprintf("$-.3s", "foobar"), "foo");
		eq(sprintf("$-10.3s", "foobar"), "foo       ");

		var fmt = "$015.12f";
		eq(sprintf(fmt, 123.45678), "123.456780000000");
		
		Printf.printf("[Done: $05i tests]", count);
	}
	
	static function eq<T>(s1:T, s2:T, ?pos:haxe.PosInfos) {
		count++;
		if (s1 != s2) {
			haxe.Log.trace('$s1 should be $s2', pos);
		}
	}
}