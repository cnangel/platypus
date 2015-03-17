use strict;
use lib '.';
use inc::Module::Install;

name     'Crawler-BDZD';
all_from 'lib/Crawler/BDZD.pm';
author   q{Cnangel <cnangel@gmail.com>};
license  'bsd';

requires 'Digest::MD5' => 2.35;
requires 'Encode' => 2.12;
build_requires 'Test::More';

no_index( directory => qw< t inc conf data bin > );

install_script ('bin/crawler.pl');
install_script ('bin/test.pl');
auto_install;

WriteAll;

