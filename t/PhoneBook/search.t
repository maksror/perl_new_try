use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing search function

describe "Передаём в функцию пустой паттерн '' :" => sub {
    it "должна вернуться ошибка пустой строки" => sub {
        my $pattern = '';
        my $expect  = { alert => 'Search string is empty' };

        my $actual  = PhoneBook::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию существующий паттерн :" => sub {
    it "basic_search вернёт результат и advanced_search не должна вызываться" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test' };

        PhoneBook->expects( 'show_all' )->returns( {} );
        PhoneBook->expects( 'basic_search' )->returns( $expect );
        PhoneBook->expects( 'advanced_search' )->returns( {} )->exactly( 0 );

        my $actual = PhoneBook::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию существующий паттерн :" => sub {
    it "должна вызваться advanced_search, тк basic_search не вернёт результатов" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test' };

        PhoneBook->expects( 'show_all' )->returns( {} );
        PhoneBook->expects( 'basic_search' )->returns( {} );
        PhoneBook->expects( 'advanced_search' )->returns( $expect );

        my $actual = PhoneBook::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию несуществующий паттерн :" => sub {
    it "должна вернуть ошибку поиска(basic|advanced_search не вернули результатов)" => sub {
        my $pattern = 'test';
        my $expect  = { alert => 'The search did not find any suitable contacts' };

        PhoneBook->expects( 'show_all' )->returns( {} );
        PhoneBook->expects( 'basic_search' )->returns( {} );
        PhoneBook->expects( 'advanced_search' )->returns( {} );

        my $actual = PhoneBook::search( $pattern );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;