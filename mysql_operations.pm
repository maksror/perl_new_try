use DBI;
use Data::Dumper;

# Секция конфига подключения к БД
my $DB = "task1";
my $USER = "task1";
my $PASS = "si7ughaehuoy7quaHahp";

# Подключение к БД
# Входные данные: нет
# Выходные данные: линка на соединение к БД
sub create_connect {
    return DBI -> connect ( "DBI:mysql:database=$DB;", $USER, $PASS, {'RaiseError' => 1} );
}

# Проверка имени и номера
# Входные данные: имя, номер
# Выходные данные: 0 если проверка пройдена или текст ошибки
sub validate_data {
    my ($name, $number) = @_;
    if ( $number =~ m/^[\d\+]*$/ ){
        for my $contact ( show_all() ){
            if ( $name eq ${$contact}[0] ){
                return ("This name is already used");
            }
        }
        return (0);
    } 
    else {
        return ("Invalid phone number");
    }
}

sub search {
        #pass
}

# Выборка всех данных из БД
# Входные данные: нет
# Выходные данные: массив массивов с парами [имя, телефон]
sub show_all {
    my $link = create_connect();
    my $query = "SELECT * FROM `contacts`;";
    my $result = $link -> selectall_arrayref ($query);
    $link -> disconnect;
    return (@$result);
}

# Добавление контакнта в БД
# Входные данные: имя, номер
# Выходные данные: 0 если контакт добавлен или текст ошибки
sub add_contact {
    # Проверка 
    my $is_valid = validate_data (@_);
    if ( $is_valid eq 0 ) { 
        my ($name, $number) = @_;
        my $link = create_connect ();
        my $query = "INSERT INTO `contacts` (Name,Phone) VALUES (\"$name\",\"$number\");";
        $link -> do ($query) or die $link->errstr ;
        $link -> disconnect;
        return (0);
    } 
    else {
        return ($is_valid);
    }
}

sub remove_contact {
    #pass
}

sub modify {
    #pass
}
