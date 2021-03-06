#!/Applications/Rakudo/bin/perl6

use lib $*PROGRAM.parent.parent.child( 'lib' );
need Venturi;

{
put 'http ', '-' x 50;
my $url = Venturi.new:
	:scheme('http'),
	:host('www.example.com'),
	:port(8080)
	;

put $url;
put "Fragment is {$url.fragment // '(no fragment)'}";
}

{
put 'http ', '-' x 50;
my $url = Venturi.new:
	:scheme('http'),
	:host('www.example.com'),
	:port(8080),
	:fragment('monkey'),
	;

put $url;
put "Fragment is {$url.fragment // '(no fragment)'}";
}

{
put 'https ', '-' x 50;
my $url = Venturi.new:
	:scheme('https'),
	:host('www.example.com'),
	:path('dir/dir2/foo' ),
	;
put $url;
}

{
put 'ftp ', '-' x 50;
my $url = Venturi.new:
	:scheme('ftp'),
	:host('www.example.com'),
	;
put $url;
}

{
put 'mailto', '-' x 50;
my $url  = Venturi.new:
	:scheme('mailto'),
	:user('hamadryas'),
	:host('www.example.com'),
	;
put $url;
}
