use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing search_uniq_contact function

# функция возвращает один аллерт, поэтому выносим их сюда
my $fail_allert = { alert => 'A search of your pattern returned more than one value.'
                             .' Please provide an identifier that is unique to the contact.'
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должно вернуться одно значение(search вернёт контакт с номер = паттерн)" => sub {
        my $pattern = '123';
        my $expect  = { 123 => 'test' };

        PhoneBook->expects( 'search' )->returns( { 123 => 'test', 333 => 'test' } );

        my $actual = PhoneBook::search_uniq_contact( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должно вернуться одно значение(search вернёт контакт с имя = паттерн)" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test' };

        PhoneBook->expects( 'search' )->returns( { 123 => 'test', 333 => 'test123' } );

        my $actual = PhoneBook::search_uniq_contact( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должно вернуться одно значение(search вернёт один контакт с частичным совпадением имя - паттерн)" => sub {
        my $pattern = 'test';
        my $expect  = { 123 => 'test123' };

        PhoneBook->expects( 'search' )->returns( { 123 => 'test123' } );

        my $actual = PhoneBook::search_uniq_contact( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должна вернуться ошибка(search вернёт два контакта с имена = паттерн)" => sub {
        my $pattern = 'test';
        my $expect  = $fail_allert;

        PhoneBook->expects( 'search' )->returns( { 123 => 'test', 333 => 'test' } );

        my $actual = PhoneBook::search_uniq_contact( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должна вернуться ошибка(search вернёт два контакта с неполным совпадением паттерна)" => sub {
        my $pattern = 'test';
        my $expect  = $fail_allert;

        PhoneBook->expects( 'search' )->returns( { 123 => 'test1', 333 => 'test1' } );

        my $actual = PhoneBook::search_uniq_contact( $pattern );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию сущствующий паттерн :" => sub {
    it "должна вернуться ошибка(search вернёт ошибку)" => sub {
        my $pattern = 'test';
        my $expect  = { alert => 'some_error_text' };

        PhoneBook->expects( 'search' )->returns( $expect );

        my $actual = PhoneBook::search_uniq_contact( $pattern );

        is_deeply( $actual, $expect );
    };
};


runtests unless caller;