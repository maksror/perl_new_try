use Test::Spec;
use Modern::Perl;

use lib "../";
use mysql_operations;

describe "mysql_operations" => sub {
    before "all" => sub {
        # Подменяем функцию подключения к БД, что бы не дёргать её в тестах.
        sub create_connect {
            my $link = mock();
            my %fake_selectall_hashref = (
                                         "+711111" => {"Name" => "test1", "Phone" => "+711111"},
                                         "+711112" => {"Name" => "test2", "Phone" => "+711112"},
                                         "123456" => {"Name" => "TEST", "Phone" => "123456"},
                                         "+777" => {"Name" => "+711111", "Phone" => "+777"},
            );


    
            $link->expects( 'selectall_hashref' )->returns( \%fake_selectall_hashref );
            $link->expects( 'disconnect' )->returns( 0 );
            return( $link );
        }

        # Функция для подмены результата show_all
        # Воходные данные: нет
        # Выходные данные: линка на хэш
        sub fake_show_all {
            my %fake_result = (
                           "1" => "123",
                           "123"=>"test",
                           "333" => "444",
                           "+777" => "qwe",
                           );
            return (\%fake_result);

        }

        # Функция сверки содержимого двух линков на хэши
        # Входные данные: две линки на хэш
        # Выходные данные:
        #   Хэши одинаковы: 0
        #   Хэши разные: 1
        sub hash_ref_eq {
            my ($first_hash, $second_hash) = @_;
            # Сравниваем длину хэшей.
            if (not %$first_hash eq %$second_hash) {
                return( 1 );
            }
            # Сравниваем значения каждого ключа
            for my $key (keys %$first_hash) {
                if (not $first_hash->{"$key"} eq $second_hash->{"$key"}) {
                    return( 1 );
                }
            }
            return( 0 );
        }
    };

    # Проверяем функцию show_all
    describe "show_all" => sub {
        it "should work" => sub {
            my %exemplary_hash = (
                                  "+711111" => "test1",
                                  "+711112" => "test2",
                                  "123456" => "TEST",
                                  "+777"=> "+711111",
            );

            my $show_all_result = show_all();

            is (hash_ref_eq( $show_all_result, \%exemplary_hash ), 0);    
        };
    };

    # Проверяем функцию validate_data
    describe "validate_data" => sub {
        # При успешной обработке функция должна возвращать 0, поэтому тест вынесен отдельно
        it "should work" => sub {
            is (validate_data( "test123", "+123123" ), 0);
        };

        # Тестовые данные для ПРОВАЛЬНЫХ тестов
        my %failed_test_data = (
                                "shoud return error (empty name)" => {
                                    "Name" => "",
                                    "Phone" => "+123123",
                                    "Alert" => "Empty values is not allowed",
                                },
                                "shoud return error (empty phone number)" => {
                                    "Name" => "test123",
                                    "Phone" => "",
                                    "Alert" => "Empty values is not allowed",
                                },
                                "shoud return error (duplicate phone number)" => {
                                    "Name" => "test123",
                                    "Phone" => "+711111",
                                    "Alert" => "This number is already used",
                                },
                                "shoud return error (phone number with letter)" => {
                                    "Name" => "test123",
                                    "Phone" => "+123123a",
                                    "Alert" => "Invalid phone number",
                                },
                                "shoud return error (phone number with space)" => {
                                    "Name" => "test123",
                                    "Phone" => "+123 123",
                                    "Alert" => "Invalid phone number",
                                },
                                "shoud return error (phone number with spectial character)" => {
                                    "Name" => "test123",
                                    "Phone" => "+123*123",
                                    "Alert" => "Invalid phone number",
                                },
        );

        # Создаём тесты на основе тестовых данных
        for my $test_name (keys %failed_test_data) {
            it $test_name => sub {
                is (validate_data( $failed_test_data{$test_name}->{"Name"},
                                   $failed_test_data{$test_name}->{"Phone"}
                )->{"Alert"}, $failed_test_data{$test_name}->{"Alert"});
            };
        }
    };

    describe "basic_search" => sub {
        # Тестовые данные
        my %test_data = (
                        "shoud work(search by uniq phone number)" => {
                            "Pattern" => "333",
                            "Excepted_hash" => {"333" => "444"},
                        },
                        "shoud work(search by non-uniq pattern)" => {
                            "Pattern" => "123",
                            "Excepted_hash" => {"1" => "123", "123" => "test"},
                        },
                        "shoud work(search by pattern with special character)" => {
                            "Pattern" => "+777",
                            "Excepted_hash" => {"+777" => "qwe"},
                        },
                        "shoud return empty hash(search by non-existing pattern)" => {
                            "Pattern" => "THIS IS WRONG TEST PATTERN",
                            "Excepted_hash" => {},
                        },
        );

        # Создаём тесты на основе тестовых данных
        for my $test_name (keys %test_data) {
            it $test_name => sub {
                is (hash_ref_eq (
                                 basic_search (
                                              "\Q$test_data{$test_name}->{'Pattern'}\E",
                                              fake_show_all()
                                 ),
                                 $test_data{$test_name}->{"Excepted_hash"}
                    ), 0
                  );
            };
        };
    };
    
    # Тестируем advanced_search
    describe "advanced_search" => sub {
        # Тестовые данные
        my %test_data = (
                        "shoud work(add character)" => {
                            "Pattern" => "tst",
                            "Excepted_hash" => {"123" => "test"},
                        },
                        "shoud work(test replacing characters)" => {
                            "Pattern" => "tast",
                            "Excepted_hash" => {"123" => "test"},
                        },
                        "shoud work(search by pattern with special charapter)" => {
                            "Pattern" => "+777",
                            "Excepted_hash" => {"+777" => "qwe"},
                        },
                        "shoud work(search by non-uniq pattern)" => {
                            "Pattern" => "123",
                            "Excepted_hash" => {"1" => "123", "123" => "test", "333" => "444"},
                        },
                        "shoud return empty hash(search by non-existing pattern)" => {
                            "Pattern" => "THIS IS WRONG TEST PATTERN",
                            "Excepted_hash" => {},
                        },
        );

        # Создаём тесты на основе тестовых данных
        for my $test_name (keys %test_data) {
            it $test_name => sub {
                is (hash_ref_eq (
                                 advanced_search (
                                                 "\Q$test_data{$test_name}->{'Pattern'}\E",
                                                 fake_show_all()
                                 ),
                                 $test_data{$test_name}->{"Excepted_hash"}
                    ), 0
                   );
           };
        };
    };

    # Тестируем функцию search
    # -! search использует данные из переопределённой create_connect !-
    describe "search" => sub {
        my %test_data = (
                        "shoud work(shoud use only basic search)" => {
                            "Pattern" => "+711111",
                            "Excepted_hash" => {"+711111" => "test1","+777"=>"+711111"},
                        },
                        "shoud work(shoud use advanced_search)" => {
                            "Pattern" => "tast1",
                            "Excepted_hash" => {"+711111" => "test1", "+711112" => "test2"},
                        },
                        "shoud return alert(search by non-existing pattern)" => {
                            "Pattern" => "THIS IS WRONG TEST PATTERN",
                            "Excepted_hash" => {"Alert" => "The search did not find any suitable contacts"},
                        },
        );
        # Создаём тесты на основе тестовых данных
        for my $test_name (keys %test_data) {
            it $test_name => sub {
                is (hash_ref_eq (
                                 search ($test_data{$test_name}->{"Pattern"}),
                                 $test_data{$test_name}->{"Excepted_hash"}
                    ), 0
                   );
           };
        };

    };

    # Тестируем функцию search_uniq_contact
    describe "search_uniq_contact" => sub {
        # Тестовые данные
        my %test_data = (
                        "shoud work(shoud return single value search by phone number)" => {
                            "Pattern" => "+711111",
                            "Excepted_hash" => { "+711111" => "test1"},
                        },
                        "shoud work(shoud return single value search by iniq name)" => {
                            "Pattern" => "test1",
                            "Excepted_hash" => { "+711111" => "test1"},
                        },
                        "shoud return alert(search by non-existing pattern)" => {
                            "Pattern" => "THIS IS WRONG TEST PATTERN",
                            "Excepted_hash" => { "Alert" => "The search did not find any suitable contacts"},
                        },
                        "shoud return alert(search by non-uniq pattern)" => {
                            "Pattern" => "test",
                            "Excepted_hash" => { "Alert" =>  "A search of your pattern returned more than one value."
                                                            ." Please provide an identifier that is unique to the contact."},
                        },
        );

        # Создаём тесты на основе тестовых данных
        for my $test_name (keys %test_data) {
            it $test_name => sub {
                is (hash_ref_eq ( 
                                 search_uniq_contact ($test_data{$test_name}->{"Pattern"}),
                                 $test_data{$test_name}->{"Excepted_hash"}
                    ), 0
                );
            };
        };
    };

    # Не придумал как протестить удаление/создание/изменение, тк нужно в мок добавлять обработку ->do с проверкой параметров. А вот как это сделать, увы хз. 
    # А из-за, объективно, не самой лучшей архитектуры приложения по другому как-то простить я не знаю как.
};
runtests unless caller;

