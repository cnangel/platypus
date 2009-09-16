#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crawler::BDZD' );
}

diag( "Testing Crawler::BDZD $Crawler::BDZD::VERSION, Perl $], $^X" );

