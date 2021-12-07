package PhoneBook;

use lib "./";
use Modern::Perl;
use MysqlConnect;
use Data::Dumper;

# Выборка всех данных из БД
# Входные данные: нет
# Выходные данные:
#   ссылка на хэш Телефон=>Имя
sub show_all {
    my $db_link = MysqlConnect::create_connect;

    my $query        = 'SELECT * FROM `contacts`';
    my $query_result = $db_link->selectall_hashref( $query, 'phone' )
        or die $db_link->errstr;

    $db_link->disconnect;

    # Превращаем полученные данные в удобные для обработки - хэш телефон=>Имя(телефон Primary Key в БД).
    my %result;

    for my $phone ( keys %{ $query_result } ) {
        $result{ $phone } = $query_result->{ $phone }->{name};
    }

    return \%result;
}

# Проверка имени и номера
# Входные данные:
#   имя
#   номер
# Выходные данные:
#   Успешная валидация: 1
#   Проваленная валидация: хэш alert=>"Оповещение"
sub validate_data {
    my ( $candidate_name, $candidate_phone ) = @_;

    # Если ввели пустые данные, то ошибка
    if ( length $candidate_name == 0 or length $candidate_phone == 0 ) {
        return { alert => 'Empty values is not allowed' };
    }

    # Если номер создержит что-то кроме символа "+" и цифр - тригерим ошибку
    if ( $candidate_phone =~ m/^\+?\d+$/ ) {
        my $all = show_all;

        # Проверка на существование такого телефона
        if ( exists $all->{ $candidate_phone } ) {
            return { alert => 'This number is already in use' };
        }

        return 1;
    }
    else {
        return { alert => 'Invalid phone number' };
    }
}

# Тривальный поиск по полному сопадению значений
# Проверка строки на возможность её использования в регулярке /$pattern/ лежит на вызывающей стороне
# Входные данные:
#   строка поиска
#   сылка на хэш с результатами show_all.
# Выходные данные:
#   Ссылка на хэш с парами "Телефон" => "Имя"
sub basic_search {
    my ( $pattern, $all ) = @_;

    my %result;

    for my $phone ( keys %{ $all } ) {
        # группируем телефон и имя(в нижнем регистре) в массив
        my @contact = ( $phone, lc( $all->{ $phone } ) );

        if ( grep /$pattern/, @contact ) {
            $result{ $phone } = $all->{ $phone };
        }
    }

    return \%result;
}


# Поиск с добавлением одного символа в каждую позицию паттерна
# Входные данные:
#   строка поиска
#   ссылка на хэш куда нужно поместить результат
#   ссылка на хэш с результатами show_all
# Выходные данные:
#   нет
sub search_with_character_addition {
    my ( $search_string, $result, $all ) = @_;

    my $len = length $search_string;

    for my $i ( 0 .. $len ) {
        my $pattern = substr( $search_string, 0, $i ) . "." . substr( $search_string, $i );

        my $basic_search_result = basic_search( $pattern, $all );

        for my $phone ( keys %{ $basic_search_result } ) {
            if ( not exists $result->{ $phone } ) {
                $result->{ $phone } = $basic_search_result->{ $phone };
            }
        }
    }
}

# Поиск с заменой двух символов в паттерне
# Входные данные:
#   строка поиска
#   ссылка на хэш куда нужно поместить результат
#   ссылка на хэш с результатами show_all
# Выходные данные:
#   нет
sub search_with_two_character_replacement {
    my ( $search_string, $result, $all ) = @_;

    my $len = length $search_string;

    # Меняем до 2 символов в строке поиска на любой
    for my $i ( 0 .. ( $len - 1 ) ) {
        # Заменяем один символ в строке поиска
        my $pattern_with_one_change = substr( $search_string, 0, $i ) . "." . substr( $search_string, $i + 1 );
        # Обходим все символы СПРАВА(что бы не повторять паттерны) от позиции $i для замены
        for my $j ( $i .. ( $len - 1 ) ) {
            # Меняем второй символ в строке поиска
            my $pattern_with_two_changes = substr( $pattern_with_one_change, 0, $j ) . "." . substr( $pattern_with_one_change, $j + 1 );

            my $basic_search_result = basic_search( $pattern_with_two_changes, $all );

            for my $phone ( keys %{ $basic_search_result } ) {
                if ( not exists $result->{ $phone } ) {
                    $result->{ $phone } = $basic_search_result->{ $phone };
                }
            }
        }
    }
}

# Расширенный(умный) поиск
# Входные данные:
#   строка поиска
#   ссылка на хэш с результатами show_all.
# Выходные данные:
#   Ссылка на хэш с парами "Телефон" => "Имя"
sub advanced_search {
    my ( $search_string, $all ) = @_;

    my %result;

    search_with_character_addition(
        $search_string,
        \%result,
        $all,
    );
    search_with_two_character_replacement(
        $search_string,
        \%result,
        $all,
    );

    return \%result;
}

# Обёртка для поиска. Тригерит сначала обычный поиск и если там пусто, то задействует расширенный.
# Входные данные:
#   строка поиска
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

    # Производим обычный поиск
    my $result = basic_search( $search_string, $all );

    # Если обычный поиск не дал результатов, то производим расширенный поиск:
    if ( !%{ $result } ) {
        $result = advanced_search( $search_string, $all );
    }

    # Если и расширенный поиск не дал результата, то добавляем оповещение
    if ( !%{ $result } ) {
        return { alert => 'The search did not find any suitable contacts' };
    }

    return $result;
}

# Добавление контакнта в БД
# Входные данные:
#   имя
#   номер
# Выходные данные:
#  Сcылка на хэш alert=>"Результат"
sub add_contact {
    my ( $name, $number ) = @_;

    # Валидация данных на добавление
    my $is_valid = validate_data( $name, $number );

    if ( $is_valid eq 1 ) {
        my $db_link = MysqlConnect::create_connect;

        my $query = 'INSERT INTO `contacts` (name,phone) VALUES (?,?)';

        $db_link->do(
            $query,
            undef,
            $name,
            $number,
        ) or die $db_link->errstr;

        $db_link->disconnect;

        return { alert => 'Contact was successfully added' };
    }
    else {
        return $is_valid;
    }
}

# Поиск уникального значения в БД по паттерну.
# По факту обёртка на searh, которая исключает варианты с возвратом нескольких значений
# Входные данные:
#   паттерн
# Выходные данные:
#   Успешный поиск: хэш номер телефона => имя
#   Поиск не дал результатов: ссылка на хэш alert => "Оповещение"
sub search_by_full_match {
    my ( $pattern ) = @_;

    my $all = show_all;

    # Если телефон есть в БД, то возвращаем его
    if ( exists $all->{ $pattern } ) {
        return { $pattern => $all->{ $pattern } };
    }

    # Поиск по полному совпадению паттерна с именем
    my %result;
    for my $phone ( keys %{$all} ) {
        if ( $all->{ $phone } eq $pattern ){
            $result{ $phone } = $all->{ $phone }
        }
    }

    # Если найдено только одно полное совпадение с именем, то возвращаем его
    if ( keys %result == 1 ) {
        return \%result;
    }

    # Если поиск вообще не дал результатов или дал более одного результата - возвращаем алерт
    return { alert => 'A search on your pattern yielded no unique result.'
                     .' Please provide an identifier that is unique to the contact.'
    };
}

# Удаление контакта
# Проверка передаваемых данные лежит на вызывающей стороне.
# Входные данные:
#   номер телефона
# Выходные данные:
#   Ссылка на хэш alert => "Результат"
sub remove_contact {
    my ( $removable_phone ) = @_;

    my $db_link = MysqlConnect::create_connect;

    my $query = 'DELETE FROM `contacts` WHERE `phone` = ?';
    my $res   = $db_link->do(
        $query,
        undef,
        $removable_phone,
    ) or die $db_link->errstr;

    $db_link->disconnect;

    # Проверка на случай, если вызов функции будет выполнен с неверным параметром
    if ( $res eq "0E0" ) {
        return { alert => 'Phone number was not found' };
    }

    return { alert => 'Contact was successfully removed' };
}

# Изменение контакта
# Входные данные: %
#   old_name*  => string
#   new_name*  => string
#   old_phone* => string
#   new_phone* => string
# Выходные данные:
# Ссылка на хэш alert => "Результат"
sub modify_contact {
    my %param = @_;

    my $old_name  = $param{old_name};
    my $new_name  = $param{new_name};
    my $old_phone = $param{old_phone};
    my $new_phone = $param{new_phone};

    # Валидация новых данных
    my $validate_result = validate_data( $new_name, $new_phone );

    # Если валидация успешная или старый телефон равен новому(и валидация тригерит ошибку по этому), то всё меняем данные
    if (
        $validate_result eq 1
        || (
            $validate_result->{alert} eq 'This number is already used'
            && $old_phone eq $new_phone
        )
    ) {
        my $db_link = MysqlConnect::create_connect;

        my $query = q/
            UPDATE `contacts`
               SET `phone` = ?, `name` = ?
             WHERE `phone` = ?
        /;

        $db_link->do(
            $query,
            undef,
            $new_phone,
            $new_name,
            $old_phone,
        ) or die $db_link->errstr;

        $db_link->disconnect;

        return { alert => 'The contact has been successfully modified' };
    }
    else {
        return $validate_result;
    }
}

1;

