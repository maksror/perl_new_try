package RequestHandlers;

use Modern::Perl;
use Mojolicious::Lite -signatures;

use lib "./";
use PhoneBook;

# Отрисовка главной страницы
get '/' => sub ($c) {
    my $contacts = PhoneBook::show_all;

    $c->render(
        template => 'index',
        rows     => $contacts,
    );
};

# Добавление контакта
post '/add' => sub ($c) {
    my $phone = $c->param( 'phone' );
    my $name  = $c->param( 'name'  );

    my $additive_result = PhoneBook::add_contact( $name, $phone );

    # Возвращается всегда аллерт, поэтому задействуем только этот шаблон
    $c->render(
        template => 'alert',
        alert    => $additive_result->{alert},
    );
};

# Поиск контакта
post '/search' => sub ($c) {
    my $pattern = $c->param( 'data' );

    my $search_result = PhoneBook::search( $pattern );

    if ( exists $search_result->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $search_result->{alert},
        );
    }
    else {
        $c->render(
            template => 'index',
            rows     => $search_result,
        );
    }
};

# Удаление контакта
post '/delete' => sub ($c) {
    my $deletion_candidate = $c->param( 'data' );

    # Производим поиск уникального значения
    my $full_match_search_result = PhoneBook::search_by_full_match( $deletion_candidate );

    # Если поиск нашёл более одного значения или завершился ошибкой - выводим алерт
    if ( exists $full_match_search_result->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $full_match_search_result->{alert},
        );
    }
    # Если поиск вернул лишь одно значение - удаляем контакт
    else {
        my @phone          = keys %{ $full_match_search_result };
        my $removal_result = PhoneBook::remove_contact( @phone );

        $c->render(
            template => 'alert',
            alert    => $removal_result->{alert},
        );
    }
};

# Поиск контакта для модификации
get '/modify' => sub($c) {
    my $modification_candidate = $c->param( 'data' );

    # Производим уникальный поиск по паттерну
    my $full_match_search_result = PhoneBook::search_by_full_match( $modification_candidate );
    # Если поиск нашёл более одного значения или завершился ошибкой - выводим алерт
    if ( exists $full_match_search_result->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $full_match_search_result->{alert},
        );
    }
    # Поиск вернул одно значение - отрисовываем шаблон для редактирования
    else {
        $c->render(
            template => 'modify',
            rows     => $full_match_search_result,
        );
    }
};

# Модификация контакта
post '/modify' => sub($c) {
    my $modification_result = PhoneBook::modify_contact(
        old_name  => $c->param( 'old_name'  ),
        new_name  => $c->param( 'new_name'  ),
        old_phone => $c->param( 'old_phone' ),
        new_phone => $c->param( 'new_phone' ),
    );
    # Возвращается всегда алерт(как при удачном редактировании так и при ошибке).
    $c->render(
        template => 'alert',
        alert    => $modification_result->{alert},
    );
};

1;

