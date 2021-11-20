use Modern::Perl;
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
#   Внутреняя ошибка: хэш "Alert"=>"Оповещение"
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
#   Проваленная валидация: хэш "Alert"=>"Оповещение"
sub validate_data {
    my ($name, $number) = @_;

    # Если ввели пустые данные, то ошибка
    if (length $name == 0 or length $number == 0) {
        return( {"Alert" => "Empty values is not allowed"} );
    }

    # Если номер создержит что-то кроме символа "+" и цифр - тригерим ошибку
    if ($number =~ m/^[\d\+]*$/) {
        my $all = show_all();
        # Если такой номер уже существует
        while (my ( $phone,$name ) = ( each %{ $all } )) {
            if ($number eq $phone) {
                return( {"Alert" => "This number is already used"} );
            }
        }
        return( 0 );
    } 
    else {
        return( {"Alert" => "Invalid phone number"} );
    }
}

# Тривальный поиск по полному сопадению значений
# Входные данные: строка поиска, ссылка на массив с массивами.
# Выходные данные: 
#   Удачный поиск: ссылка на хэш с парами "Телефон" => "Имя"
#   Поиск завершился ошибкой: хэш "Alert"=>"Оповещение"
sub basic_search {
    my ($pattern, $all) = @_;

    my %result;

    while (my ( $phone,$name ) = ( each %{ $all } )) {
        if (grep /^$pattern$/, ( $phone, $name )) {
            $result{$phone} = $name;
        }
    }

    return( \%result );
}

# Расширенный(умный) поиск
# Входные данные: строка поиска, ссылка на массив с массивами.
# Выходные данные: 
#   Удачный поиск: ссылка на хэш с парами "Телефон" => "Имя"
#   Поиск завершился ошибкой: хэш "Alert"=>"Оповещение"
sub advanced_search {
    my ($search_string, $all) = @_;

    my $len = length $search_string;
    my %result;

    # Добавляем один любой символ в каждое место строки поиска
    for my $i ( 0 .. $len ) {
        my $pattern = substr( $search_string, 0, $i ). "\E.\Q". substr( $search_string, $i );
        my $basic_result = basic_search( $pattern, $all );
        while (my( $phone, $name ) = ( each %{ $basic_result } )) {
            if (not grep { /\Q$phone/ } (keys %result)) {
                $result{$phone} = $name;
            }
        }
    }

    # Меняем до 2 символов в строке поиска
    for my $i ( 0..( $len - 1 ) ) {
        my $pattern_i = substr( $search_string, 0, $i ) . "\E.\Q" . substr( $search_string, $i+1 );
        for my $j ( 0..( $len - 1 ) ) {
            my $pattern_j = substr( $pattern_i, 0, $j ) . "\E.\Q" . substr( $pattern_i, $j+1 ); 
            my $basic_result = basic_search( $pattern_j, $all );
            while (my( $phone, $name ) = ( each %{ $basic_result } )) {
                if (grep { /\Q$phone/ } ( keys %result )) {
                    $result{$phone} = $name;
                }
            }
        }
    }

    return (\%result);
}

# Обёртка для поиска. Тригерит сначала тривиальный поиск и если там пусто, то задействует расширенный.
# Входные данные: строка поиска
# Выходные данные: 
#   Удачный поиск: ссылка на хэш с парами "Телефон" => "Имя"
#   Поиск завершился ошибкой: ссылка на хэш "Alert"=>"Оповещение"
sub search {
    my $search_string = shift;

    # Если строка пустая, то тригерим ошибку
    if (length $search_string < 1) {
        return( {"Alert" => "Search string is empty"} );
    }

    my $all = show_all();

    # Экранируем все спец символы в строке поиска.
    $search_string = "\Q$search_string\E";

    # Производим поиск по полному совпадению со строкой
    my $result = basic_search( $search_string, $all );
    
    # Если полное совпадение не дало результатов, то производим расширенный поиск:
    if (!%$result) {
        $result = advanced_search( $search_string, $all );
    }
    # Если и расширенный поиск не дал результата, то добавляем оповещение
    if (!%$result) {
        return( {'Alert' => "The search did not find any suitable contacts"} );
    }
    return( $result );
}

# Выборка всех данных из БД
# Входные данные: нет
# Выходные данные: 
#   Успешное получение данных: массив массивов с парами [имя, телефон]
#   Внутреняя ошибка(подключения к БД или SELECT запроса): хэш "Alert"=>"Оповещение"
sub show_all {
    my $link = create_connect();
    if (grep /^Something/, $link) {
        return( {"Alert" => $link} );
    }
    my $query = "SELECT * FROM `contacts`";
    my $query_result = $link -> selectall_hashref( $query, 'Phone' ) 
    # Если запрос неудчаный - отдаём оповещение
    or return ( {"Alert" => "Something went wrong! Please contact us with this error"} ) ;
    $link -> disconnect;
    # Превращаем полученные данные в удобные для обработки - хэш телефон=>Имя(телефон Primary Key в БД).
    my %result;
    for my $phone ( keys %$query_result ) {
        $result{$phone} = $query_result->{$phone}->{'Name'};
    }

    return( \%result );
}

# Добавление контакнта в БД
# Входные данные: имя, номер
# Выходные данные: 
#   Удачное добавление: 0
#   Неудачное добавление: ссылка на хэш "Alert"=>"Оповещение"
sub add_contact {
    my ($name, $number) = @_;
    # Валидация данных на добавление
    my $is_valid = validate_data( $name, $number );

    if ($is_valid eq 0) { 
        my $link = create_connect();
        # Если соединение не удалось - отдаём оповещение
        if (grep /^Something/, $link) {
            return( {"Alert" => $link} );
        }
        my $query = "INSERT INTO `contacts` (Name,Phone) VALUES (?,?)";
        $link -> do( $query, undef, ($name, $number) ) or die( $link->errstr );
        $link -> disconnect;
        return( {"Alert" => "Contact was successfully added"} );
    } 
    else {
        return( $is_valid );
    }
}

# Валидация номера телефона для удаления
# Входные данные: номер телефона
# Выходные данные:
#   Успешная проверка: 0
#   Номер не прошёл проверку: Оповещение
sub validate_remove_condidat {
    my $candidat = shift;
    
    if ($candidat =~ m/^[\d\+]*$/ and length $candidat > 0) {
        return( 0 );
    }
    else {
        return( "Invalid phone number" );
    }
}

# Удаление контакта
# Входные данные: номер телефона
# Выходные данные:
#   Ссылка на хэш "Alert" => "Оповещение"
sub remove_contact {
    my $phone = shift;

    my $validate_result = validate_remove_condidat($phone);
    # Если валидация контакта прошла неудачно - отдаём полученное оповещение
    if ($validate_result ne 0) {
        return( {"Alert" => $validate_result} );
    }

    my $link = create_connect();
    if (grep /^Something/, $link) {
        return( {"Alert" => $link} );
    }

    my $query = "DELETE FROM `contacts` WHERE `Phone` = ?";
    my $res = $link -> do( $query, undef, $phone ) or die( $link->errstr );
    $link -> disconnect;
    if ($res eq "0E0"){
        return( {"Alert" => "Phone number was not found"} );;    
    }
    return( {"Alert" => "Contact was successfully removed"} );

}

sub modify {
    #pass
}

