use Test::Spec;
use Test::utf8;
use Modern::Perl;

use lib "../../";
use mysql_operations qw( :ALL );

# Testing basic_search function

describe "Передаём в фукнцию существующий паттерн :" => sub {
    it "должна найти совпадение(полное совпадение c именем)" => sub {
        my %fake_show_all_result = (
            123 => 'test',
        );

        my $pattern = 'test';
        my $expect  = \%fake_show_all_result;

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию существующий паттерн :" => sub {
    it "должна найти совпадение(полное совпадение c телефоном)" => sub {
        my %fake_show_all_result = (
            123 => 'test',
        );

        my $pattern = '123';
        my $expect  = \%fake_show_all_result;

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию существующий паттерн :" => sub {
    it "должна найти совпадение(частичное совпадение с именем)" => sub {
        my %fake_show_all_result = (
            123 => 'test123',
        );

        my $pattern = 'test';
        my $expect  = \%fake_show_all_result;

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию существующий паттерн :" => sub {
    it "должна найти совпадение(частичное совпадение с телефоном)" => sub {
        my %fake_show_all_result = (
            +1239 => 'test',
        );

        my $pattern = 'test';
        my $expect  = \%fake_show_all_result;

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию существующий паттерн :" => sub {
    it "должна найти совпадение(полное совпадение по телефону и имени разных контактов)" => sub {
        my %fake_show_all_result = (
            123 => 'test',
            333 => 123,
        );

        my $pattern = '123';
        my $expect  = \%fake_show_all_result;

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию существующий паттерн :" => sub {
    it "должна найти совпадение(перевод имени из БД в нижний регистр)" => sub {
        my %fake_show_all_result = (
            +1239 => 'TEST',
        );

        my $pattern = 'test';
        my $expect  = \%fake_show_all_result;

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

describe "Передаём в фукнцию несуществующий паттерн :" => sub {
    it "не должна найти совпадений" => sub {
        my %fake_show_all_result = (
            +1239 => 'qwe',
        );

        my $pattern = 'test';
        my $expect  = {};

        my $actual  = mysql_operations::basic_search( $pattern, \%fake_show_all_result );

        is_deeply( $actual, $expect );
    };
};

runtests unless caller;