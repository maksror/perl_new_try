use DBI;
use Data::Dumper;

# Секция конфига подключения к БД
my $DB = "task1";
my $USER = "task1";
my $PASS = "si7ughaehuoy7quaHahp";

#****ФУНКЦИИ****

# Подключение к БД
# Входные данные: нет
# Выходные данные: линка на соединение к БД
sub create_connect {
    return DBI -> connect( "DBI:mysql:database=$DB;", $USER, $PASS, {'RaiseError' => 1} );
}

# Проверка имени и номера
# Входные данные: имя, номер
# Выходные данные: 0 если проверка пройдена или текст ошибки
sub validate_data {
    my ($name, $number) = shift;
    if ( length $name == 0 or length $number == 0) {
        return( "Empty values is not allowed" );
    }
    if ( $number =~ m/^[\d\+]*$/ ) {
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
# Выходные данные: массив масивов с парами [имя, телефон]
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
# Выходные данные: массив масивов с парами [имя, телефон]
sub advanced_search {
    my ($search_string, $all) = @_;
    my @result;
    my $len = length $search_string;

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
    # Проверка реализована для случайно добавленной БУКВЫ в номере(хотя проверка будет смотреть паттерн и в имени).

    return (@result);
}

# Обёртка для поиска. Тригерит сначала тривиальный поиск и если там пусто, то задействует расширенный.
# Входные данные: строка поиска
# Выходные данные: массив масивов с парами [имя, телефон]
sub search {
    my $search_string = shift;
    my @all = show_all();
    # Экранируем все спец символы в строке поиска.
    $search_string = "\Q$search_string\E";

    my @result = basic_search( $search_string, \@all );
    # Если в паттерне поиска допустили ошибку:
    if( !@result ) {
        push( @result, advanced_search( $search_string, \@all ) );
    }

    return( @result );
}

# Выборка всех данных из БД
# Входные данные: нет
# Выходные данные: массив массивов с парами [имя, телефон]
sub show_all {
    my $link = create_connect();
    my $query = "SELECT * FROM `contacts`;";
    my $query_result = $link -> selectall_arrayref( $query );
    $link -> disconnect;
    return( @$query_result );
}

# Добавление контакнта в БД
# Входные данные: имя, номер
# Выходные данные: 0 если контакт добавлен или текст ошибки
sub add_contact {
    # Проверка 
    my ($name, $number) = @_;
    my $is_valid = validate_data( $name, $number );
    if ( $is_valid eq 0 ) { 
        my $link = create_connect();
        my $query = "INSERT INTO `contacts` (Name,Phone) VALUES (\"$name\",\"$number\");";
        $link -> do( $query ) or die $link->errstr ;
        $link -> disconnect;
        return( 0 );
    } 
    else {
        return( $is_valid );
    }
}

sub remove_contact {
    #pass
}

sub modify {
    #pass
}
