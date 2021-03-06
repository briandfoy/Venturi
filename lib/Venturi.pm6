#!/Applications/Rakudo/bin/perl6
need Venturi::Authority;
need Venturi::Path;
need Venturi::Query;
need Venturi::Fragment;
need Venturi::Keywords;

# https://tools.ietf.org/html/rfc3986?

=begin notes

ftp://ftp.is.co.za/rfc/rfc1808.txt

http://www.ietf.org/rfc/rfc2396.txt

ldap://[2001:db8::7]/c=GB?objectClass?one

mailto:John.Doe@example.com

news:comp.infosystems.www.servers.unix

tel:+1-816-555-1212

telnet://192.0.2.16:80/

urn:oasis:names:specification:docbook:dtd:xml:4.1.2

URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]

      hier-part   = "//" authority path-abempty
                  / path-absolute
                  / path-rootless
                  / path-empty

         foo://example.com:8042/over/there?name=ferret#nose
         \_/   \______________/\_________/ \_________/ \__/
          |           |            |            |        |
       scheme     authority       path        query   fragment
          |   _____________________|__
         / \ /                        \
         urn:example:animal:ferret:nose

=end notes

class Venturi {
	has $!scheme;

	multi method new ( :$scheme! is copy --> Venturi:D ) {
		my $subclass = join '::', 'Venturi', $scheme.lc;
		try {
			CATCH {
				default { fail "No Venturi handler for $scheme: $_" }
				}
			require ::($subclass);
			}
		my $venturi = ::($subclass).new: |%_;

		$venturi;
		}

	method default-scheme () { 'schemeless' }

	multi method new ( Str:D $url ) {
		#say "class is $class";
		my $hash = self.parse: $url;

		$hash.throw unless $hash;

		my $scheme = $hash<scheme> // self.default-scheme;

		self.new: :scheme($scheme);
		}

	method not-concrete {
		fail "{Backtrace.new.[*-3].subname} is not implemented for {self.^name}";
		}
	method authority { self.not-concrete }
	method userinfo  { self.not-concrete }
	method path      { self.not-concrete }
	method query     { self.not-concrete }
	method keywords  { self.not-concrete }
	method fragment  { self.not-concrete }

=begin rfc3986

https://tools.ietf.org/html/rfc3986

^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
 12            3  4          5       6  7        8 9

    http://www.ics.uci.edu/pub/ietf/uri/#Related

results in the following subexpression matches:

	$1 = http:
	$2 = http
	$3 = //www.ics.uci.edu
	$4 = www.ics.uci.edu
	$5 = /pub/ietf/uri/
	$6 = <undefined>
	$7 = <undefined>
	$8 = #Related
	$9 = Related

	scheme    = $2
	authority = $4
	path      = $5
	query     = $7
	fragment  = $9

=end rfc3986

	method uri-pattern () {
		state $pattern = rx/
			^
			    [ $<scheme> = ( <-[:/?#]>+ ) ':' ]?
			    [ '//' $<authority> = ( <-[/?#]>* ) ]?
			$<path>      = ( <-[?#]>* )
			    [ '?' $<query> = (<-[#]>*) ]?
			    [ '#' $<fragment>  = (\N*) ]?
			/;

		$pattern;
		}

	use Venturi::Util;

	method parse ( ::?CLASS:U : Str:D $url ) {

		my $match = $url ~~ $?CLASS.uri-pattern;

		my $hash = $match.Hash;

		if $hash<path> {
			$hash<path> = $hash<path>.Str
				.split('/')
				.map( {
					url_escape_path(
						utf8_decode( url_unescape( $_ ) )
						)
					})
				.join: '/';
			}

		if $hash<query> {
			$hash<query> = utf8_decode( url_unescape( ~$hash<query> ) );
			$hash<query> = url_escape_path( ~$hash<query> );
			}

		$hash<fragment> = Any unless try $hash<fragment>.chars;
		$hash<protocol> = $hash<scheme> ?? $hash<scheme>.lc !! Any;
		$hash<path_query> = join '?', map { $_ // Empty }, $hash<path query>;

		if $hash<authority> && $hash<authority> ~~ s/^ $<userinfo> = (<-[@]>*) \@ // {
			my $unescaped = url_unescape(~$<userinfo>);
			$hash<userinfo> = utf8_decode( $unescaped ) // $unescaped;
			if $hash<userinfo> ~~ m/ $<username> = (<-[:]>*) [':' $<password> = (.*)]? / {
				$hash<username> = ~$<username>;
				$hash<password> = $<password>.defined ?? ~$<password> !! Any;
				}
			}

		my $host-port-map = host_port( $hash<authority> ?? ~$hash<authority> !! '' );
		$hash<port>       = $host-port-map<port> if $host-port-map<port>;
		$hash<host>       = $host-port-map<host> if $host-port-map<host>;
		$hash<ihost>      = encode_ihost($host-port-map<host>);
		$hash<host_port>  = join ':', map { $_ // Empty }, $hash<ihost port>;

  		return $hash;
		}

	my sub host_port ( Str:D $auth is copy --> Map:D ) {
		my $port;
		my $host;
		$port = $<port> if $auth ~~ s/ ':' $<port> = (\d+) $//;
		$host = url_unescape $auth;
		Map.new: 'port', $port, 'host', $host;
		}

	my sub encode_ihost ( Str:D $host ) {
		use IDNA::Punycode;
		return $host unless $host ~~ / <-[\x00 .. \x7f]> /;

		return join '.',
			map { /<-[\x00 .. \x7f]> / ?? encode_punycode($_) !! $_ },
			$host.split: / '.' /
		}

	method Str ( --> Str:D ) { !!! }
	method gist ( --> Str:D ) { !!! }
	}
