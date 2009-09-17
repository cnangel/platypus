#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Crawler::BDZD' );
    use_ok( 'Crawler::Common' );
}

diag( "Testing Crawler::BDZD $Crawler::BDZD::VERSION, Perl $], $^X" );

#my $cc = Crawler::Common;

