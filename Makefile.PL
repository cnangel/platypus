use inc::Module::Install;

name     'Crawler-BDZD';
all_from 'lib/Crawler/BDZD.pm';
author   q{Cnangel <junliang.li@alibaba-inc.com>};
license  'bsd';

build_requires 'Test::More';

auto_install;

WriteAll;

