package Crawler::Common;

use warnings;
use strict;

=head1 NAME

Crawler::Common - The great new Crawler::Common!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Crawler::Common;

    my $foo = Crawler::Common->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 $self->new()

Construct.

=cut

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}

=head1 FUNCTIONS

=head2 $self->checkdir()

Check directory whether exist, if not exists, create it.

=cut

sub checkdir($$)
{
	my $self = shift;
	my $dirpath = shift;
	return 1 if (-d $dirpath);
	mkdir($dirpath, 0777);
	chmod(0777, $dirpath);
	return 0;
}

=head1 FUNCTIONS

=head2 $self->geturlinfo($url, [$proxy], [$http_protocol_version])

Get page infomation through HTTP protocol.
default HTTP protocol version is 1.1.

=cut

sub geturlinfo
{
    my ($self, $url, $proxy, $http_protocol_version) = @_;
    eval("use Socket;");

	$proxy = "" unless ($proxy);
	$http_protocol_version = "1.1" unless ($http_protocol_version);
    my ($host, $port, $path);
    if ($proxy ne '' && $proxy ne 'direct')
    {
            ($host, $port) = split(/:/, $proxy);
            $port ||= 80;
            $path = $url;
            $path = "http://$path" if ($path !~ /^http:\/\//i);
    }
    else
    {
            $url =~ s/^http:\/\///isg;
            ($host, undef) = split(/\//, $url);
            $path = $url;
            $path =~ s/^$host//iso;
            ($host, $port) = split(/:/, $host);
            $port ||= 80;
            $path = "/$path" if ($path !~ /^\//);
    }

    my ($name, $aliases, $type, $len, @thataddr, $a, $b, $c, $d, $that);

    ($name, $aliases, $type, $len, @thataddr) = gethostbyname($host);
    ($a, $b, $c, $d) = unpack("C4", $thataddr[0]);
    $that = pack('S n C4 x8', 2, $port, $a, $b, $c, $d);

    return "" unless (socket(S, 2, 1, 0));
    select(S);
    $| = 1;
    select(STDOUT);
    return "" unless (connect(S, $that));

#    print S "GET $path HTTP/1.0\r\n";
    print S "GET $path HTTP/$http_protocol_version\r\n";
    print S "Host: $host\r\n";
    print S "Accept: */*\r\n";
    print S "User-Agent: Mozilla/5.0 (compatible; MSIE 6.00; Windows NT 5.2)\r\n";
    print S "Pragma: no-cache\r\n";
    print S "Cache-Control: no-cache\r\n";
    print S "Connection: close\r\n";
    print S "\r\n";

    my @results = <S>;
    close(S);
#    undef $|;
	my $content = join("", @results);
    return \$content;
}

=head1 FUNCTIONS

=head2 $self->urlencode($str)

Str encode.

=cut

sub urlencode
{
	my ($self, $str) = @_;
	return $str if ($str =~ /\%/);
	return unless (defined($str));
	$str =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/uc sprintf('%%%02x', ord($1))/eg;
	$str =~ tr/ /+/;
	return $str;
}

=head1 FUNCTIONS

=head2 $self->urldecode($str)

Str decode.

=cut

sub urldecode
{
	my ($self, $str) = @_;
	return $str if ($str =~ /\%/);
	return if !defined $str;
	$str =~ s/([^@\w\.\*\-\x20\:\/])/uc sprintf('%%%02x',ord($1))/eg;
	$str =~ tr/ /+/;
	return $str;
}

=head1 FUNCTIONS

=head2 $self->base64encode($str)

Str base64encode.

=cut

sub base64encode
{
	my $self = shift;
	my $res = pack("u", $_[0]);
	$res =~ s/^.//mg;
	$res =~ s/\n//g;
	$res =~ tr|` -_|AA-Za-z0-9+/|;
	my $padding = (3 - length($_[0]) % 3) % 3;
	$res =~ s/.{$padding}$/'=' x $padding/e if $padding;
	return $res;
}

=head1 FUNCTIONS

=head2 $self->base64decode($str)

Str base64decode.

=cut

sub base64decode
{
	local($^W) = 0;
	my ($self, $str) = @_;
	my $res = '';

	$str =~ tr|A-Za-z0-9+/||cd;
	$str =~ tr|A-Za-z0-9+/| -_|;
	while ($str =~ /(.{1,60})/gs)
	{
		my $len = chr(32 + length($1)*3/4);
		$res .= unpack("u", $len . $1 );
	}
	return $res;
}

=head1 AUTHOR

Cnangel, C<< <junliang.li at alibaba-inc.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crawler-bdzd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crawler-Common>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crawler::Common


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crawler-Common>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crawler-Common>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crawler-Common>

=item * Search CPAN

L<http://search.cpan.org/dist/Crawler-Common/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cnangel.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/bsd-license.php>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Cnangel's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Crawler::Common
