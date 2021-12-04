use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use PhoneBook qw( :ALL );

# Testing show_all function

describe "Выборка данных из БД" => sub {
    it "работает" => sub {
        # Имитируем хэш возвращаемые selectall_hashref
        my %fake_select_result = (
            +711111 => { name => 'test1' , phone => '+711111' },
            +711112 => { name => 'test2' , phone => '+711112' },
            123456  => { name => 'TEST'  , phone => '123456'  },
        );

        my $fake_mysql_link = mock();
        $fake_mysql_link->expects( 'selectall_hashref' )->returns( \%fake_select_result );
        $fake_mysql_link->expects( 'disconnect' )       ->returns( 0 );

        PhoneBook->expects( 'create_connect' )->returns( $fake_mysql_link );

        my %expect = (
            +711111 => 'test1',
            +711112 => 'test2',
            123456  => 'TEST',
        );

        my $actual = PhoneBook::show_all;

        is_deeply( $actual , \%expect );
    };
};

runtests unless caller;