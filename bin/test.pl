#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Encode qw(from_to);
use FindBin qw($Bin);
use lib $Bin . '/../lib';
use Crawler::Common;

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
my $outfile = $outdir . '/result.csv';

# init 
my $cc = new Crawler::Common;

$cc->checkdir($outdir);
$cc->checkdir($cachedir);

unless (-d $outdir)
{
	printf("Usage: %s <QueryFile> <OutPath>\n", $0);
	printf("OutPath must be directory!!!\n", $0);
	exit(1);
}

open my $op, '>', $outfile or die "Can't write the file: $!";
open my $fp, '<', $infile or die "Can't read the file: $!";
while (my $line = <$fp>)
{
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;
	next unless ($line);
	from_to($line, "UTF-8", "GBK") if ($utf8flag);
	&crawlerAndExtract($op, \$line);
}
close($fp);
close($op);

sub crawlerAndExtract($$)
{
	my ($op, $strref) = @_;
	my $url = $url_1 . $cc->urlencode($$strref) . $url_2;
	my $file = $cachedir.'/'.md5_hex($url).'.pl';
#	print $url, "\n";
#	print $file, "\n";
	from_to($outfile, "GBK", "UTF-8");
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
		print $nexturl, "\n";
		&crawlerAndDetailPageExtract($op, $strref, \$nexturl, $pagetype);
	}
}

sub crawlerAndDetailPageExtract($$$$)
{
	my ($op, $queryref, $urlref, $pagetype) = @_;
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
	if ($detailcacheinfo !~ /HTTP\/1\.\d 200 OK/)
	{
		warn "Content of detail page: $url is not right!!\n";
		warn "You can see $file\n";
		return 1;
		#unlink($file);
	}
	if ($pagetype)
	{
		my ($baikecontent) = $detailcacheinfo =~ /<div class="text">.*?(<h\d>.*?)\s*(?:<div class="bpctrl" style="clear:both"><\/div>).*?STAT_ONCLICK_UNSUBMIT.*?<\/div>/s;
		($baikecontent) = $detailcacheinfo =~ /<div class="text">.*?(<h\d>.*?)\s*<span.+?><a.+?STAT_ONCLICK_UNSUBMIT_CATALOG_RETUR.+><\/a>/s unless ($baikecontent);
		$baikecontent =~ s/<img[^>]+>//sg if ($baikecontent =~ /<img[^>]+>/s);
		$baikecontent =~ s/[\r|\n]\n?/\n/g;
		$baikecontent =~ s/\n/<br \/>/g;
		$baikecontent =~ s/<span>\[<a[^>]+?javascript[^>]+>.*?<\/a>\]<\/span>//g;
		$baikecontent =~ s/"/""/g;
		print $op qq~"$pagetype","$$queryref","$baikecontent"\n~;
	}
	else
	{
		if ($detailcacheinfo =~ /<div class="ico"><div class="iok">/) 
		{
			my ($zhidaotitle, $zhidaoquestion) = $detailcacheinfo =~ /<div[^>]+?question_title"?>(.*?)<\/div>.*?<div[^>]+?question_content"?>(.*?)\s*<\/div>\s*<div[^>]+?question_author/s;
			$zhidaotitle =~ s/<[^>]+>//sg;
			if ($zhidaoquestion =~ m/<pre>(.*?)<\/pre>.*?(<b>.*?<\/b>).*?<pre>(.*?)<\/pre>/s)
			{
				$zhidaoquestion = $1 . "<br />" . $2 . "<br />" . $3;
			}
			elsif ($zhidaoquestion =~ m/<pre>(.*?)<\/pre>/)
			{
				$zhidaoquestion = $1;
			}
			my ($zhidaoanswer) = $detailcacheinfo =~ /div[^>]+?best_answer_content"?>\s*(.*?)\s*<\/div>\s*<div[^>]+best_answer_info/s;
			if ($zhidaoanswer =~ m/<pre>(.*?)<\/pre>/s)
			{
				$zhidaoanswer = $1;
			}
#			print $op "$pagetype\t" . $cc->base64encode($zhidaotitle) . "\t" . $cc->base64encode($zhidaoquestion) . "\t" . $cc->base64encode($zhidaoanswer) . "\n";
			$zhidaotitle =~ s/"/""/g;
			$zhidaoquestion =~ s/"/""/g;
			$zhidaoanswer =~ s/"/""/g;
			print $op qq/"$pagetype","$$queryref","$zhidaotitle","$zhidaoquestion","$zhidaoanswer"\n/;
		}
		else
		{
			warn "Detail page: $url not resolve!!\n";
			warn "You can see $file\n";
		}
	}
}

sub getcontent
{
	my ($url, $file, $varname, $hpv) = @_;
	return 0 if (-e $file && -M $file <= 0.5);
	my $content = $cc->geturlinfo($url, '', $hpv);
	$$content =~ s/\~/\\\~/g;
	open CACHE, ">$file" or die "Can't write the cache file:$!";
	print CACHE '$'.$varname.' = qq~' . $$content . '~;1;';
	close CACHE;
#	prevent force-out
	srand (time());
	my $sleepsec = int(rand(5));
	sleep($sleepsec);
	return 1;
}

