 import tango.io.FilePath;
 import tango.io.Stdout;
 import tango.text.Util;
 void main (char[][] args)
 {
     foreach(arg; args[1..$])
     {
	 try
	 {
	    auto a = replace(arg,'\\','/');
	    auto file = new FilePath(arg);
	    if (file.exists())
	    {
		file.remove();
		Stdout.format("'{}' removed", arg).newline;
	    }
	 }
	 catch
	 {
	     Stdout.format("Error: '{}' don`t removed", arg).newline;
	 }
     }
 }
