use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use mysql_operations qw( :ALL );

# Testing advanced_search function

describe "Передаём в фукнцию паттерн 'ab':" => sub {
    it "проверяем исключение дублирующих результатов" => sub {
        my $pattern = 'ab';
        my $expect  = { 123 => '123' };

        my %fake_show_all_result = (
            123 => '1ab',
            456 => 'a1b',
            333 => 'ab1',
        );

        my @expected_patterns = (
            '.ab',
            'a.b',
            'ab.',
            'a.',
            '.b',
            '..',
        );

        mysql_operations->expects( 'basic_search' )->returns( sub {
                my ( $pattern, undef ) = @_;

                ok(
                    grep( /^$pattern$/, @expected_patterns ),
                    "Проверка передачи паттерна в basic_search: был перепедан '$pattern'",
                );

                return { 123 => '123' };
        } )->exactly( 6 );

        my $actual = mysql_operations::advanced_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;