#!/usr/bin/perl

# $Id: crawler.pl,v 1.0.0-0 2009/09/04 17:03:39 Cnangel Exp $

use strict;
use warnings;
use vars qw/$starttime %ARGV/;
BEGIN { $starttime = (times)[0] + (times)[1]; }
END { printf("%d\n", ((times)[0] + (times)[1] - $starttime) * 1000) if ($ARGV{debug}); }
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
# use File::Find;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Conf::Libconfig;
use Data::Dumper;

my $man = 0;
my $help = 0;
pod2usage() if (scalar @ARGV == 0); 
GetOptions (
		"c|conf=s"			=> \$ARGV{conf},
		"debug"             => \$ARGV{debug},
		"verbose"           => \$ARGV{verbose},
		'help|?'            => \$help,
		man                 => \$man
		) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
$ARGV{conf} = "$Bin/../conf/config.cfg" unless ($ARGV && -f $ARGV{conf});
pod2usage() unless (-f $ARGV{conf});

# use vars qw/@files/;

# read config file
my $conf = Conf::Libconfig->new;
$conf->read_file($ARGV{'conf'});
my $host = $conf->lookup_value("application.host");
die 'host is null' unless ($host);

# sub GetFileFromDir
# {
# 	my $dir = shift;
# 	find(\&wanted, $dir);
# 	return \@files;
# }
# 
# sub wanted
# {
# 	push @files, $File::Find::name if (-f $_);
# }

# Base64编码函数
sub Base64encode
{
	my $res = pack("u", $_[0]);
	$res =~ s/^.//mg;
	$res =~ s/\n//g;
	$res =~ tr|` -_|AA-Za-z0-9+/|;
	my $padding = (3 - length($_[0]) % 3) % 3;
	$res =~ s/.{$padding}$/'=' x $padding/e if $padding;
	return $res;
}

# Base64解码函数
sub Base64decode
{
	local($^W) = 0;
	my $str = shift;
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

sub gethtml
{
	my $url = shift;
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	$ua->agent("MyApp/0.1 ");

	# Create a request
#	my $req = HTTP::Request->new(POST => 'http://search.cpan.org/search');
#	$req->content_type('application/x-www-form-urlencoded');
#	$req->content('query=libwww-perl&mode=dist');

	# Pass request to the user agent and get a response back
#	my $res = $ua->request($req);

	$ua->timeout(20);
	$ua->env_proxy;
 
	my $res = $ua->get($url);
	my $infos;

	# Check the outcome of the response
	if ($res->is_success)
	{
		$infos = $res->content;
	}
	else
	{
		$infos = $res->status_line;
	}
	return \$infos;
}

# 用Socket方法获得一个URL的HTML内容
sub geturlinfo
{
    my ($url, $proxy) = @_;
    eval("use Socket;");

	$proxy = "" unless ($proxy);
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

    print S "GET $path HTTP/1.0\r\n";
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
    return \@results;
}

# 检测目录是否存在
sub checkdir($)
{
	my $dirpath = shift;
	return 1 if (-e $dirpath);
	mkdir($dirpath, 0777);
	chmod(0777, $dirpath);
	return 0;
}

sub posturlinfo
{
    eval("use Socket;");
    return if ($@ ne "");
    ($host,$path,$content) = @_;
    $host =~ s/^http:\/\///isg;
    $port = 80;
    $path = "/$path" if ($path !~ /^\//);
    my ($name, $aliases, $type, $len, @thataddr, $a, $b, $c, $d, $that);
    my ($name, $aliases, $type, $len, @thataddr) = gethostbyname($host);
    my ($a, $b, $c, $d) = unpack("C4", $thataddr[0]);
    my $that = pack('S n C4 x8', 2, $port, $a, $b, $c, $d);
    return unless (socket(S, 2, 1, 0));
    select(S);
    $| = 1;
    select(STDOUT);
    return unless (connect(S, $that));
    print S "POST http://$host/$path HTTP/1.0\n";
    print S "Content-type: application/x-www-form-urlencoded\n";
    my $contentLength = length $content;
    print S "Content-length: $contentLength\n";
    print S "\n";
    print S "$content";
    @results = <S>;
    close(S);
    undef $|;
    return;
}

# 生成缓存文件
sub advanced_gethtml
{
	my ($ua, $url, $file) = @_;
	unless (-e $file && -M $file <= 0.5)
	{
		LABEL:
		my $res = $ua->get($url);
		if ($res->is_success)
		{
			my $content = $res->content;
			
			$content =~ s/\~/\\\~/g;
			open CACHE, ">$file";
			print CACHE '$cacheinfo = qq~' . $content . '~;1;';
			close CACHE;
			return 1;
		}
		else
		{
			goto LABEL;
		}
	}
	else
	{
		return 1;
	}
}

__END__

=head1 NAME

crawler.pl - Crawler

=head1 SYNOPSIS

crawler.pl -c <conf>

crawler.pl -help

=head1 OPTIONS

=over 8

=item B<-c|--conf>

Configuration for the script, default is $PROJECT_HOME/conf.

=item B<--debug>

Debug mode, you can see how much time spent in B<this program>.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof, then output result of file(s).

=head1 AUTHOR 

B<Cnangel> (I<junliang.li@alibaba-inc.com>)

=head1 HISTORY

I<2009/09/04 17:03:39> Builded.

=cut
