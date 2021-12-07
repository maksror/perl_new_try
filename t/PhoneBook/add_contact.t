use Test::Spec;
use Test::utf8;
use Modern::Perl;
use Test::Exception;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing add_contact function

describe "Передаём в функцию валидные данные :" => sub {
    it "проверяем корректность передачи данных в mysql" => sub {
        my $name   = 'test';
        my $phone  = '123';
        my $expect = { alert => 'Contact was successfully added' };

        PhoneBook->expects( 'validate_data' )->returns( 1 );

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'disconnect' )->returns( 0 );
        $fake_mysql_link->expects( 'do' )->returns( sub {
            my ( undef, $actual_query, undef, $actual_name, $actual_phone ) = @_;

            my $expected_query = 'INSERT INTO `contacts` (name,phone) VALUES (?,?)';

            is( $actual_query, $expected_query, "Правильный шаблон запроса"    );
            is( $actual_name , $name,           "Правильное имя в запросе"     );
            is( $actual_phone, $phone,          "Правильный телефон в запросе" );

            return 1;
        } );

        MysqlConnect->expects( 'create_connect' )->returns( $fake_mysql_link );

        my $actual = PhoneBook::add_contact( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию не валидные данные :" => sub {
    it "должна вернуться ошибка из validate_data" => sub {
        my $name   = '';
        my $phone  = '';
        my $expect = { alert => 'some_error_text' };

        PhoneBook->expects( 'validate_data' )->returns( $expect );

        my $actual = PhoneBook::add_contact( $name, $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию не валидные данные, которые должны положить запрос мускуля :" => sub {
    it "функция должна умереть" => sub {
        my $name   = 'test';
        my $phone  = '123';

        PhoneBook->expects( 'validate_data' )->returns( 1 );

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'do' )->returns( 0 );
        $fake_mysql_link->expects( 'errstr' )->returns( 0 );

        MysqlConnect->expects( 'create_connect' )->returns( $fake_mysql_link );

        dies_ok( sub {
            PhoneBook::add_contact( $name, $phone );
        } );
    };
};

runtests unless caller;