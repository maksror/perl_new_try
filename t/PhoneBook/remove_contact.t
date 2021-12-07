use Test::Spec;
use Test::utf8;
use Modern::Perl;
use Test::Exception;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing remove_contact function

describe "Передаём в функцию валидные данные :" => sub {
    it "проверяем корректность передачи данных в mysql" => sub {
        my $phone  = '123';
        my $expect = { alert => 'Contact was successfully removed' };

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'disconnect' )->returns( 0 );
        $fake_mysql_link->expects( 'do' )        ->returns( sub {
            my ( undef, $actual_query, undef, $actual_phone ) = @_;

            my $expected_query = 'DELETE FROM `contacts` WHERE `phone` = ?';

            is( $actual_query, $expected_query, "Правильный шаблон запроса"    );
            is( $actual_phone, $phone,          "Правильный телефон в запросе" );

            return 1;
        } );

        MysqlConnect->expects( 'create_connect' )->returns( $fake_mysql_link );

        my $actual = PhoneBook::remove_contact( $phone );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию не валидные данные, которые должны положить запрос мускуля :" => sub {
    it "функция должна умереть" => sub {
        my $phone  = '123';

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'do' )    ->returns( 0 );
        $fake_mysql_link->expects( 'errstr' )->returns( 0 );

        MysqlConnect->expects( 'create_connect' )->returns( $fake_mysql_link );

        dies_ok( sub {
            PhoneBook::remove_contact( $phone );
        } );
    };
};

describe "Передаём в функцию не валидный телефон, которого нет в БД:" => sub {
    it "функция должна вернуть аллерт о неверном телефоне" => sub {
        my $phone  = '123';
        my $expect = { alert => 'Phone number was not found' };

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'disconnect' )->returns( 0 );
        $fake_mysql_link->expects( 'do' )        ->returns( "0E0" );

        MysqlConnect->expects( 'create_connect' )->returns( $fake_mysql_link );

        my $actual = PhoneBook::remove_contact( $phone );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;