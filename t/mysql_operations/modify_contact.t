use Test::Spec;
use Test::utf8;
use Modern::Perl;
use Test::Exception;

use lib "../../";
use mysql_operations qw( :ALL );

# Testing modify_contact function

describe "Передаём в функцию валидные данные :" => sub {
    it "проверяем корректность передачи данных в mysql" => sub {
        my $old_name  = 'test';
        my $new_name  = 'test';
        my $old_phone = '123';
        my $new_phone = '333';
        my $expect    = { alert => 'The contact has been successfully modified' };

        mysql_operations->expects( 'validate_data' )->returns( 0 );

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'disconnect' )->returns( 0 );
        $fake_mysql_link->expects( 'do' )        ->returns( sub {
        	my ( undef,
                $actual_query,
                undef,
                $actual_new_phone,
                $actual_new_name,
                $actual_old_phone,
            ) = @_;

        	my $expected_query = q/
                UPDATE `contacts`
                   SET `phone` = ?, `name` = ?
                 WHERE `phone` = ?
            /;

            # Убираем лишние пробелы/табы из запроса
            $actual_query   =~ s/\h+/ /g;
            $expected_query =~ s/\h+/ /g;

        	is( $actual_query,     $expected_query, "Правильный шаблон запроса"           );
        	is( $actual_new_phone, $new_phone,      "Правильный новый телефон в запросе"  );
            is( $actual_new_name,  $new_name,       "Правильное новое имя в запросе"      );
            is( $actual_old_phone, $old_phone,      "Правильный старый телефон в запросе" );

            return 1;
        } );

        mysql_operations->expects( 'create_connect' )->returns( $fake_mysql_link );

        my $actual = mysql_operations::modify_contact(
            $old_name,
            $new_name,
            $old_phone,
            $new_phone,
        );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию валидные данные :" => sub {
    it "Проверка на условие 'старый номер' = 'новый номер' и ошибки 'This number is already used'" => sub {
        my $old_name  = 'test';
        my $new_name  = 'test';
        my $old_phone = '123';
        my $new_phone = '123';
        my $expect    = { alert => 'The contact has been successfully modified' };

        mysql_operations->expects( 'validate_data' )->returns( { alert => 'This number is already used' } );

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'disconnect' )->returns( 0 );
        $fake_mysql_link->expects( 'do' )        ->returns( 1 );

        mysql_operations->expects( 'create_connect' )->returns( $fake_mysql_link );

        my $actual = mysql_operations::modify_contact(
            $old_name,
            $new_name,
            $old_phone,
            $new_phone,
        );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в функцию не валидные данные :" => sub {
    it "должна вернуться ошибка валидации" => sub {
        my $old_name  = 'test';
        my $new_name  = '';
        my $old_phone = '123';
        my $new_phone = '333';
        my $expect    = { alert => 'some_error_text' };

        mysql_operations->expects( 'validate_data' )->returns( $expect );

        my $actual = mysql_operations::modify_contact(
            $old_name,
            $new_name,
            $old_phone,
            $new_phone,
        );

        is_deeply( $actual, $expect );
    };
};


describe "Передаём в функцию не валидые данные, которые положат запрос в мускуль:" => sub {
    it "функция должна умереть" => sub {
        my $old_name  = '';
        my $new_name  = '';
        my $old_phone = '';
        my $new_phone = '';


        mysql_operations->expects( 'validate_data' )->returns( 0 );

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'do' )        ->returns( 0 );

        mysql_operations->expects( 'create_connect' )->returns( $fake_mysql_link );

        dies_ok( sub {
            mysql_operations::modify_contact(
            $old_name,
            $new_name,
            $old_phone,
            $new_phone,
            );
        } );
    };
};

runtests unless caller;