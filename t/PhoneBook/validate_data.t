use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing validate_data function

# Тесты на успешную валидацию
describe "Передаём в фукнцию данные name = 'test', phone = '123':" => sub {
    it "должна вренуть 1" => sub {
        my $name   = 'test';
        my $phone  = '123';
        my $expect = 1;

        # Эмитация возврата хэша из show_all
        my %empty_hash;
        PhoneBook->expects( 'show_all' )->returns( \%empty_hash );

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию данные name = 'test', phone = '+123':" => sub {
    it "должна вренуть 1" => sub {
        my $name   = 'test';
        my $phone  = '+123';
        my $expect = 1;

        # Эмитация возврата хэша из show_all
        my %empty_hash;
        PhoneBook->expects( 'show_all' )->returns( \%empty_hash );

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

# Проверка на фейлы
describe "Передаём в фукнцию данные name = '', phone = '+123':" => sub {
    it "должна вернуть аллерт(пустое имя)" => sub {
        my $name   = '';
        my $phone  = '+123';
        my $expect = { alert => 'Empty values is not allowed' };

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию данные name = 'test', phone = '':" => sub {
    it "должна вернуть аллерт(пустой номер телефона)" => sub {
        my $name   = 'test';
        my $phone  = '';
        my $expect = { alert => 'Empty values is not allowed' };

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию данные name = 'test', phone = 'test':" => sub {
    it "должна вернуть аллерт(недопустимый номер телефона)" => sub {
        my $name   = 'test';
        my $phone  = 'test';
        my $expect = { alert => 'Invalid phone number' };

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию данные name = 'test', phone = '123+123':" => sub {
    it "должна вернуть аллерт(недопустимый номер телефона)" => sub {
        my $name   = 'test';
        my $phone  = '123+123';
        my $expect = { alert => 'Invalid phone number' };

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию данные name = 'test', phone = '-123':" => sub {
    it "должна вернуть аллерт(недопустимый номер телефона)" => sub {
        my $name   = 'test';
        my $phone  = '-123';
        my $expect = { alert => 'Invalid phone number' };

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию данные name = 'test', phone = '+123':" => sub {
    it "должна вернуть аллерт(телефон уже есть в БД)" => sub {
        my $name   = 'test';
        my $phone  = '+123';
        my $expect = { alert => 'This number is already used' };

        # Эмитация возврата хэша из show_all
        my %fake_select_result = ( '+123' => 'test' );
        PhoneBook->expects( 'show_all' )->returns( \%fake_select_result );

        my $actual = PhoneBook::validate_data( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;