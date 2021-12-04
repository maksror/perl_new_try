use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use mysql_operations qw( :ALL );

# Testing search function

describe "Передаём в функцию пустой паттерн '' :" => sub {
    it "должна вернуться ошибка пустой строки" => sub {
        my $pattern = '';
        my $expect  = { alert => 'Search string is empty' };

        my $actual  = mysql_operations::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию существующий паттерн :" => sub {
    it "basic_search вернёт результат и advanced_search не должна вызываться" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test' };

        mysql_operations->expects( 'show_all' )       ->returns( {} );
        mysql_operations->expects( 'basic_search' )   ->returns( $expect );
        mysql_operations->expects( 'advanced_search' )->returns( {} )->exactly( 0 );

        my $actual = mysql_operations::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию существующий паттерн :" => sub {
    it "должна вызваться advanced_search, тк basic_search не вернёт результатов" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test' };

        mysql_operations->expects( 'show_all' )       ->returns( {} );
        mysql_operations->expects( 'basic_search' )   ->returns( {} );
        mysql_operations->expects( 'advanced_search' )->returns( $expect );

        my $actual = mysql_operations::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию несуществующий паттерн :" => sub {
    it "должна вернуть ошибку поиска(basic|advanced_search не вернули результатов)" => sub {
        my $pattern = 'test';
        my $expect  = { alert => 'The search did not find any suitable contacts' };

        mysql_operations->expects( 'show_all' )       ->returns( {} );
        mysql_operations->expects( 'basic_search' )   ->returns( {} );
        mysql_operations->expects( 'advanced_search' )->returns( {} );

        my $actual = mysql_operations::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;