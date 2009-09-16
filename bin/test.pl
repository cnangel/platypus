#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Encode qw(from_to);

if (@ARGV != 2 && @ARGV != 3)
{
	printf("Usage: %s <QueryFile> <OutPath> [UTF-8 Encoding]\n", $0);
	exit(0);
}
# define variables
my $infile = $ARGV[0];
my $outdir = $ARGV[1] . '/out';
my $cachedir = $ARGV[1] . '/cache';
my $utf8flag = $ARGV[2] ? 1 : 0;
# define constant variables
my $host = 'http://zhidao.baidu.com';
my $url_1 = 'http://zhidao.baidu.com/q?word=';
my $url_2 = '&ct=17&pn=0&tn=ikaslist&rn=10&lm=0&fr=search';

&checkdir($outdir);
&checkdir($cachedir);

unless (-d $outdir)
{
	printf("Usage: %s <QueryFile> <OutPath>\n", $0);
	printf("OutPath must be directory!!!\n", $0);
	exit(1);
}

open my $fp, '<', $infile or die "Can't read the file: $!";
while (my $line = <$fp>)
{
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;
	next unless ($line);
	from_to($line, "UTF-8", "GBK") if ($utf8flag);
	&crawlerAndExtract(\$line);
}
close($fp);

sub crawlerAndExtract
{
	my $strref = shift;
	my $url = $url_1 . &urlencode($$strref) . $url_2;
	my $file = $cachedir.'/'.md5_hex($url).'.pl';
	my $outfile = $outdir . '/' . $$strref . '.txt';
	from_to($outfile, "GBK", "UTF-8");
	open my $op, '>', $outfile or die "Can't write the file: $!";
	our $cacheinfo;
REQUIREFILE:
	eval { require $file; };
	if ($@ && -e $file)
	{
		unlink($file);
		&getcontent($url, $file, 'cacheinfo');
		goto REQUIREFILE;
	}
	elsif (!-e $file) 
	{
		&getcontent($url, $file, 'cacheinfo');
		goto REQUIREFILE;
	}
	while ($cacheinfo =~ m/<table border="?0"? cellpadding="?0"? cellspacing="?0"?><tr><td class="?(wikif|f)"?[^>]*?>(.*?)<\/table>/sg)
	{
		my $pagetype = $1 eq "f" ? 0 : 1;
		my $block = $2;
		my ($nexturl) = $block =~ m/^.*?<a href="([^\"]+)"[^>]*?>/s;
		$nexturl = $host . $nexturl if ($nexturl =~ m#^\/#);
		&crawlerAndDetailPageExtract($op, \$nexturl, $pagetype);
	}
}

sub crawlerAndDetailPageExtract($$$)
{
	my ($op, $urlref, $pagetype) = @_;
	my $url = $$urlref;
	our $detailcacheinfo;
	my $file = $cachedir.'/'.md5_hex($url).'.pl';
REQUIREDETAIL:
	eval { require $file; };
	if ($@ && -e $file)
	{
		unlink($file);
		&getcontent($url, $file, 'detailcacheinfo');
		goto REQUIREDETAIL;
	}
	elsif (!-e $file) 
	{
		&getcontent($url, $file, 'detailcacheinfo');
		goto REQUIREDETAIL;
	}
	unless ($detailcacheinfo)
	{
		warn "Content of detail page: $url is empty!!\n";
		warn "You can see $file\n";
		return 1;
	}
	if ($pagetype)
	{
		my ($baikecontent) = $detailcacheinfo =~ /<div class="text">.*?(<h\d>.*?)\s*(?:<div class="bpctrl" style="clear:both"><\/div>).*?STAT_ONCLICK_UNSUBMIT.*?<\/div>/s;
		($baikecontent) = $detailcacheinfo =~ /<div class="text">.*?(<h\d>.*?)\s*<span.+?><a.+?STAT_ONCLICK_UNSUBMIT_CATALOG_RETUR.+><\/a>/s unless ($baikecontent);
		$baikecontent =~ s/<img[^>]+>//sg;
		print $op "$pagetype\t" . Base64encode($baikecontent) . "\n";
	}
	else
	{
		if ($detailcacheinfo =~ /<div class="ico"><div class="iok">/) 
		{
			my ($zhidaotitle, $zhidaoquestion) = $detailcacheinfo =~ /<div[^>]+?question_title"?>(.*?)<\/div>.*?<div[^>]+?question_content"?>(.*?)\s*<\/div>\s*<div[^>]+?question_author/s;
			$zhidaotitle =~ s/<[^>]+>//g;
			$zhidaoquestion =~ s/<\/cd><\/div>/<\/cd>/;
			my ($zhidaoanswer) = $detailcacheinfo =~ /div[^>]+?best_answer_content"?>\s*(.*?)\s*<\/div>\s*<div[^>]+best_answer_info/s;
			print $op "$pagetype\t" . Base64encode($zhidaotitle) . "\t" . Base64encode($zhidaoquestion) . "\t" . Base64encode($zhidaoanswer) . "\n";
		}
		else
		{
			warn "Detail page: $url not resolve!!\n";
			warn "You can see $file\n";
		}
	}
}

sub getcontent($$$)
{
	my ($url, $file, $varname) = @_;
	return 0 if (-e $file && -M $file <= 0.5);
	my $content = geturlinfo($url);
	$$content =~ s/\~/\\\~/g;
	open CACHE, ">$file" or die "Can't write the cache file:$!";
	print CACHE '$'.$varname.' = qq~' . $$content . '~;1;';
	close CACHE;
	return 1;
}

sub checkdir($)
{
	my $dirpath = shift;
	return 1 if (-d $dirpath);
	mkdir($dirpath, 0777);
	chmod(0777, $dirpath);
	return 0;
}

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

#    print S "GET $path HTTP/1.0\r\n";
    print S "GET $path HTTP/1.1\r\n";
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

sub urlencode
{
	my $str = shift;
	return $str if ($str =~ /\%/);
	return unless (defined($str));
	$str =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/uc sprintf('%%%02x', ord($1))/eg;
	$str =~ tr/ /+/;
	return $str;
}

sub urldecode
{
	my $str = shift;
	return $str if ($str =~ /\%/);
	return if !defined $str;
	$str =~ s/([^@\w\.\*\-\x20\:\/])/uc sprintf('%%%02x',ord($1))/eg;
	$str =~ tr/ /+/;
	return $str;
}

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
