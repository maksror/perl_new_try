use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing search_by_full_match function

# функция возвращает один аллерт, поэтому выносим их сюда
my $fail_allert = { alert => 'A search on your pattern yielded no unique result.'
                             .' Please provide an identifier that is unique to the contact.'
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должно вернуться одно значение(полное совпадение номер = паттерн)" => sub {
        my $pattern = '123';
        my $expect  = { 123 => 'test' };

        PhoneBook->expects( 'show_all' )->returns( { 123 => 'test', 333 => 'test' } );

        my $actual = PhoneBook::search_by_full_match( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должно вернуться одно значение(полное совпадение имя = паттерн)" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test' };

        PhoneBook->expects( 'show_all' )->returns( { 123 => 'test', 333 => 'test123' } );

        my $actual = PhoneBook::search_by_full_match( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должно вернуться ошибка(частичное совпадение имя ~ паттерн)" => sub {
        my $pattern = 'test';
        my $expect  = $fail_allert;

        PhoneBook->expects( 'show_all' )->returns( { 123 => 'test123' } );

        my $actual = PhoneBook::search_by_full_match( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должна вернуться ошибка(совпадение двух контактов имена = паттерн)" => sub {
        my $pattern = 'test';
        my $expect  = $fail_allert;

        PhoneBook->expects( 'show_all' )->returns( { 123 => 'test', 333 => 'test' } );

        my $actual = PhoneBook::search_by_full_match( $pattern );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;