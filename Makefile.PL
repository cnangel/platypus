use strict;
use lib '.';
use inc::Module::Install;

name     'Crawler-BDZD';
all_from 'lib/Crawler/BDZD.pm';
author   q{Cnangel <junliang.li@alibaba-inc.com>};
license  'bsd';

requires 'Digest::MD5' => 2.35;
requires 'Encode' => 2.12;
build_requires 'Test::More';

#install_scripts 
auto_install;

WriteAll;

