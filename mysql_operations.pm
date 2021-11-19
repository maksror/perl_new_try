use DBI;
use Data::Dumper;

# Секция конфига подключения к БД
my $DB = "task1";
my $USER = "task1";
my $PASS = "si7ughaehuoy7quaHahp";

#****ФУНКЦИИ****

# Подключение к БД
# Входные данные: нет
# Выходные данные: 
#   Успешное подключение: линка с mysql подключением
#   Внутреняя ошибка: строка с ошибкой
sub create_connect {
    my $link = DBI -> connect( "DBI:mysql:database=$DB;", $USER, $PASS, {'RaiseError' => 0} ) 
    # Если по какой либо причине подключение не удалось, то возвращаем указанную ошибку.
    or return( "Something went wrong! Please contact us with this error" );
    # Если всё хорошо, то возвращаем линку
    return( $link );
}

# Проверка имени и номера
# Входные данные: имя, номер
# Выходные данные:
#   Успешная валидация: 0
#   Проваленная валидация: строка с ошибкой
sub validate_data {
    my ($name, $number) = @_;

    # Если ввели пустые данные, то ошибка
    if ( length $name == 0 or length $number == 0) {
        return( "Empty values is not allowed" );
    }

    # Если номер создержит что-то кроме символа "+" и цифр - тригерим ошибку
    if ( $number =~ m/^[\d\+]*$/ ) {
        # Если такой номер уже существует
        for my $contact ( show_all() ) {
            if ( $number eq ${$contact}[1] ) {
                return( "This number is already used" );
            }
        }
        return( 0 );
    } 
    else {
        return( "Invalid phone number" );
    }
}

# Тривальный поиск по полному сопадению значений
# Входные данные: строка поиска, ссылка на массив с массивами.
# Выходные данные: 
#   Удачный поиск: массив масивов с парами [имя, телефон]
#   Поиск завершился ошибкой: строка с ошибкой
sub basic_search {
    my ($pattern, $all) = @_;

    my @result;

    for my $contact ( @{ $all } ) {
        if ( grep /^$pattern$/, @{$contact} ) {
            push( @result, $contact );
        }
    }

    return( @result );
}

# Расширенный(умный) поиск
# Входные данные: строка поиска, ссылка на массив с массивами.
# Выходные данные: 
#   Удачный поиск: массив масивов с парами [имя, телефон]
#   Поиск завершился ошибкой: строка с ошибкой
sub advanced_search {
    my ($search_string, $all) = @_;

    my $len = length $search_string;
    my @result;

    # Добавляем один любой символ в каждое место строки поиска
    for my $i (0 .. $len) {
        my $pattern = substr( $search_string, 0, $i ) . "\E.\Q" . substr( $search_string, $i );
        my @basic_result = basic_search( $pattern, $all );
        for my $contact ( @basic_result ) {
            if( not grep { /\Q$contact/ } @result ) {
                push( @result, $contact );
            }
        }
    }

    # Меняем до 2 символов в строке поиска
    for my $i ( 0..( $len - 1 ) ) {
        my $pattern_i = substr( $search_string, 0, $i ) . "\E.\Q" . substr( $search_string, $i+1 );
        for my $j ( 0..( $len - 1 ) ) {
            $pattern_j = substr( $pattern_i, 0, $j ) . "\E.\Q" . substr( $pattern_i, $j+1 ); 
            my @basic_result = basic_search( $pattern_j, $all );
            for my $contact ( @basic_result ) {
                if ( not grep { /\Q$contact/ } @result ) {
                    push( @result, $contact );
                }
            }
        }
    }


    # Исключаем до m БУКВ из строки поиска.
    # Проверка была убрана из-за отсутвия необходимости. Блок кода выше реализует почти тоже самое
    # Плодить ещё одну проверку тут безсмысленно.

    return (@result);
}

# Обёртка для поиска. Тригерит сначала тривиальный поиск и если там пусто, то задействует расширенный.
# Входные данные: строка поиска
# Выходные данные: 
#   Удачный поиск: массив масивов с парами [имя, телефон]
#   Поиск завершился ошибкой: строка с ошибкой
sub search {
    my $search_string = shift;

    # Если строка пустая, то тригерим ошибку
    if ( length $search_string < 1 ) {
        return( "Search string is empty" );
    }

    my @all = show_all();
    if ( grep /^Something/, $link ) {
        return( $link );
    }

    # Экранируем все спец символы в строке поиска.
    $search_string = "\Q$search_string\E";

    # Производим поиск по полному совпадению со строкой
    my @result = basic_search( $search_string, \@all );

    # Если полное совпадение не дало результатов, то производим расширенный поиск:
    if ( !@result ) {
        push( @result, advanced_search( $search_string, \@all ) );
    }
    
    if ( !@result ) {
        return( "The search did not find any suitable contacts" );
    }
    else {
        return( @result );
    }
}

# Выборка всех данных из БД
# Входные данные: нет
# Выходные данные: 
#   Успешное получение данных: массив массивов с парами [имя, телефон]
#   Внутреняя ошибка(подключения к БД или SELECT запроса): строка с ошибкой
sub show_all {
    my $link = create_connect();
    if ( grep /^Something/, $link ) {
        return ($link);
    }
    my $query = "SELECT * FROM `contacts`;";
    my $query_result = $link -> selectall_arrayref( $query ) 
    # Если запрос неудчаный, тригерим шаблон ошибки
    or return ( "Something went wrong! Please contact us with this error" ) ;
    $link -> disconnect;
    return( @$query_result );
}

# Добавление контакнта в БД
# Входные данные: имя, номер
# Выходные данные: 
#   Удачное добавление: 0
#   Неудачное добавление: строка с ошибкой
sub add_contact {
    my ($name, $number) = @_;
    # Валидация данных на добавление
    my $is_valid = validate_data( $name, $number );

    if ( $is_valid eq 0 ) { 
        my $link = create_connect();
        # Если соединение не удалось - вызываешь ошибку
        if ( grep /^Something/, $link ) {
            return( $link );
        }
        my $query = "INSERT INTO `contacts` (Name,Phone) VALUES (?,?)";
        $link -> do( $query, undef, ($name, $number) ) or return( $link->errstr );
        $link -> disconnect;
        return( 0 );
    } 
    else {
        return( $is_valid );
    }
}

# Валидация номера телефона для удаления
# Входные данные: номер телефона
# Выходные данные:
#   Успешная проверка: 0
#   Номер не прошёл проверку: строка с ошибкой
sub validate_remove_condidat {
    my $candidat = shift;
    
    if ( $candidat =~ m/^[\d\+]*$/ and length $candidat > 0 ) {
        return( 0 );
    }
    else {
        return( "Invalid Phone number" );
    }
}

# Удаление контакта
# Входные данные: номер телефона
# Выходные данные:
#   Успешное удаление: 0
#   Ошибка при удалении: строка с ошибкой
sub remove_contact {
    my $phone = shift;


    my $link = create_connect();
    if ( grep /^Something/, $link ) {
        return( $link );
    }

    my $query = "DELETE FROM `contacts` WHERE `Phone` = ?";
    my $res = $link -> do( $query, undef, $phone ) or return( $link->errstr );
    print ($res);
    $link -> disconnect;
    return( 0 );

}

sub modify {
    #pass
}
