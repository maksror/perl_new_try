use DBI;
use Data::Dumper;
use Config::General;
use File::Basename;
use Modern::Perl;

my $dir_name = dirname(__FILE__);
# Загружаем конфиг с атрибутами подключения к БД
my %config = Config::General->new(
    -ConfigFile      => "$dir_name/config.cfg",
    -InterPolateVars => 1,
)->getall;

#****ФУНКЦИИ****

# Подключение к БД
# Входные данные: нет
# Выходные данные:
#   Успешное подключение: линка с mysql подключением
sub create_connect {
    my $link = DBI->connect(
        "DBI:mysql:database=$config{DB};",
        $config{USER},
        $config{PASS},
        {
            'RaiseError'        => 0,
            'mysql_enable_utf8' => 1,
        },
    ) or die $DBI::errstr;

    # Если всё хорошо, то возвращаем линку
    return $link;
}

# Выборка всех данных из БД
# Входные данные: нет
# Выходные данные:
#   Успешное получение данных: ссылка на хэш Телефон=>Имя
sub show_all {
    my $link = create_connect;

    my $query        = 'SELECT * FROM `contacts`';
    my $query_result = $link->selectall_hashref( $query, 'Phone' )
        or die $link->errstr;

    $link->disconnect;

    # Превращаем полученные данные в удобные для обработки - хэш телефон=>Имя(телефон Primary Key в БД).
    my %result;

    for my $phone ( keys %{ $query_result } ) {
        $result{ $phone } = $query_result->{ $phone }->{Name};
    }

    return \%result;
}

# Проверка имени и номера
# Входные данные: имя, номер
# Выходные данные:
#   Успешная валидация:
#   П0роваленная валидация: хэш alert=>"Оповещение"
sub validate_data {
    my ( $candidat_name, $candidat_phone ) = @_;

    # Если ввели пустые данные, то ошибка
    if ( length $candidat_name == 0 or length $candidat_phone == 0 ) {
        return { alert => 'Empty values is not allowed' };
    }

    # Если номер создержит что-то кроме символа "+" и цифр - тригерим ошибку
    if ( $candidat_phone =~ m/^[\d\+]*$/ ) {
        my $all = show_all;

        # Проверка на существование такого телефона
        for my $existing_phone ( keys %{ $all } ) {
            if ( $candidat_phone eq $existing_phone ) {
                return { alert => 'This number is already used' };
            }
        }

        return 0;
    }
    else {
        return { alert => 'Invalid phone number' };
    }
}

# Тривальный поиск по полному сопадению значений
# Входные данные: строка поиска, ссылка на хэш с результатами show_all.
# Проверка строки на возможность её использования в регулярке /^$pattern$/ лежит на вызывающей стороне
# Выходные данные:
#   Удачный поиск: ссылка на хэш с парами "Телефон" => "Имя"
#   Поиск завершился ошибкой: хэш alert=>"Оповещение"
sub basic_search {
    my ( $pattern, $all ) = @_;

    my %result;

    for my $phone ( keys %{ $all } ) {
        # получаем пару значений в нижнем регистре
        my @pairs = map { lc $_ } ( $phone, $all->{ $phone } );

        if ( grep /$pattern/, @pairs ) {
            $result{ $phone } = $all->{ $phone };
        }
    }

    return \%result;
}

# Расширенный(умный) поиск
# Входные данные: строка поиска, ссылка на хэш с результатами show_all.
# Выходные данные:
#   Удачный поиск: ссылка на хэш с парами "Телефон" => "Имя"
#   Поиск завершился ошибкой: хэш alert=>"Оповещение"
sub advanced_search {
    my ( $search_string, $all ) = @_;

    my $len = length $search_string;
    my %result;

    # Добавляем один любой символ в каждое место строки поиска
    for my $i ( 0 .. $len ) {
        my $pattern = substr( $search_string, 0, $i ) . "\E.\Q" . substr( $search_string, $i );
        # Ищем по получившемуся паттерну
        my $basic_result = basic_search( $pattern, $all );

        # Добавляем только ранее не найденные контакты
        for my $phone ( keys %{ $basic_result } ) {
            if ( not exists $result{ $phone } ) {
                $result{ $phone } = $basic_result->{ $phone };
            }
        }
    }

    # Меняем до 2 символов в строке поиска на любой
    for my $i ( 0 .. ( $len - 1 ) ) {
        # Заменяем один символ в строке поиска
        my $pattern_with_one_change = substr( $search_string, 0, $i ) . "\E.\Q" . substr( $search_string, $i + 1 );
        # Обходим все символы СПРАВА(что бы не повторять паттерны) от позиции $i для замены
        for my $j ( $i + 1 .. ( $len - 1 ) ) {
            # Меняем второй символ в строке поиска
            my $pattern_with_two_changes = substr( $pattern_with_one_change, 0, $j ) . "\E.\Q" . substr( $pattern_with_one_change, $j + 1 );
            # Ищем по получившемуся паттерну
            my $basic_result = basic_search( $pattern_with_two_changes, $all );

            # Добавляем только ранее не найденные контакты
            for my $phone ( keys %{ $basic_result } ) {
                if ( not exists $result{ $phone } ) {
                    $result{ $phone } = $basic_result->{ $phone };
                }
            }
        }
    }
    return \%result;
}

# Обёртка для поиска. Тригерит сначала тривиальный поиск и если там пусто, то задействует расширенный.
# Входные данные: строка поиска
# Выходные данные:
#   Удачный поиск: ссылка на хэш с парами "Телефон" => "Имя"
#   Поиск завершился ошибкой: ссылка на хэш alert=>"Оповещение"
sub search {
    my ( $search_string ) = @_;

    # Если строка пустая, то тригерим ошибку
    if ( length $search_string == 0 ) {
        return { alert => 'Search string is empty' };
    }

    my $all = show_all;

    # Экранируем все спец символы в строке поиска и переводим её в нижний регистр.
    $search_string = lc( "\Q$search_string\E" );

    # Производим поиск по полному совпадению со строкой
    my $result = basic_search( $search_string, $all );

    # Если полное совпадение не дало результатов, то производим расширенный поиск:
    if ( !%$result ) {
        $result = advanced_search( $search_string, $all );
    }

    # Если и расширенный поиск не дал результата, то добавляем оповещение
    if ( !%$result ) {
        return { alert => 'The search did not find any suitable contacts' };
    }

    return $result;
}

# Добавление контакнта в БД
# Входные данные: имя, номер
# Выходные данные:
#  Сcылка на хэш alert=>"Результат"
sub add_contact {
    my ( $name, $number ) = @_;

    # Валидация данных на добавление
    my $is_valid = validate_data( $name, $number );

    if ( $is_valid eq 0 ) {
        my $link = create_connect;

        my $query = 'INSERT INTO `contacts` (Name,Phone) VALUES (?,?)';

        $link->do(
            $query,
            undef,
            ( $name, $number ),
        ) or die $link->errstr;

        $link->disconnect;

        return { alert => 'Contact was successfully added' };
    }
    else {
        return $is_valid;
    }
}

# Поиск уникального значения в БД по паттерну.
# По факту обёртка на searh, которая исключает варианты с возвратом нескольких значений
# Входные данные: паттерн
# Выходные данные:
#   Успешный поиск(единственного совпадения с паттерном): ссылка на хэш с контактом
#   Поиск завершился ошибкой или выдал более 1 результата: ссылка на хэш с оповещением
sub search_uniq_contact {
    my ( $candidat ) = @_;

    my $search_result = search( $candidat );

    # Если кандидат это номер телефона и присутвует в выборке
    if ( exists $search_result->{ $candidat } ) {
        return { $candidat => $search_result->{ $candidat } };
    }
    # Если выборка вернула более одного результата
    elsif ( keys %{ $search_result } > 1 ) {
        return { alert => 'A search of your pattern returned more than one value.'
                          .' Please provide an identifier that is unique to the contact.'
        };
    }

    # В остальных случаях просто возвращаем результат(alert или единственный найденный контакт).
    # Контакт возвращается когда пользователь искал по имени и оно оказалось уникальным
    # Остальные кейсы обрабатываются if-ом выше
    return $search_result;
}

# Удаление контакта
# Проверка передаваемых данные лежит на вызывающей стороне.
# Перед удалением вызвать search_uniq_contact и использовать телефон из результата.
# Входные данные: номер телефона
# Выходные данные:
#   Ссылка на хэш alert => "Результат"
sub remove_contact {
    my ( $removable_phone ) = @_;

    my $link = create_connect;

    my $query = 'DELETE FROM `contacts` WHERE `Phone` = ?';
    my $res = $link->do(
        $query,
        undef,
        $removable_phone,
    ) or die $link->errstr;

    $link->disconnect;

    # Проверка на случай, если вызов функции будет выполнен с неверным параметром
    if ( $res eq "0E0" ) {
        return { alert => 'Phone number was not found' };
    }

    return { alert => 'Contact was successfully removed' };
}

# Изменение контакта
# Входные данные: старое/новое имя, старый/новый телефон
# Выходные данные:
# Ссылка на хэш alert => "Результат"
sub modify_contact {
    my ( $old_name, $new_name, $old_phone, $new_phone ) = @_;

    # Валидация новых данных
    my $validate_result = validate_data( $new_name, $new_phone );

    # Если валидация успешная или старый телефон равен новому(и валидация тригерит ошибку по этому), то всё меняем данные
    if (
        $validate_result eq 0
        || (
            $validate_result->{ alert } eq 'This number is already used'
            && $old_phone eq $new_phone
        )
    ) {
        my $query = q/
            UPDATE `contacts`
               SET `Phone` = ?, `Name` = ?
             WHERE `Phone` = ?
        /;

        my $link = create_connect;

        $link->do(
                 $query,
                 undef,
                 ( $new_phone, $new_name, $old_phone ),
        ) or die $link->errstr;

        $link->disconnect;

        return { alert => 'The contact has been successfully modified' };
    }
    else {
        return $validate_result;
    }
}

1;

