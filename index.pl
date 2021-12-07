#!/usr/bin/perl

use Modern::Perl;
use Mojolicious::Lite -signatures;

use lib "./";
use PhoneBook;

# Отрисовка главной страницы
get '/' => sub ($c) {
    my $contacts = PhoneBook::show_all;

    if ( exists $contacts->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $contacts->{alert},
        );
    }
    else {
        $c->render(
            template => 'index',
            rows     => $contacts,
        );
    }
};

# Добавление контакта
post '/add' => sub ($c) {
    my $phone = $c->param( 'phone' );
    my $name  = $c->param( 'name'  );

    my $result = PhoneBook::add_contact( $name, $phone );

    # Возвращается всегда аллетр, поэтому задействуем только этот шаблон
    $c->render(
        template => 'alert',
        alert    => $result->{alert},
    );
};

# Поиск контакта
post '/search' => sub ($c) {
    my $pattern = $c->param( 'data' );

    my $contacts = PhoneBook::search( $pattern );

    if ( exists $contacts->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $contacts->{alert},
        );
    }
    else {
        $c->render(
            template => 'index',
            rows     => $contacts,
        );
    }
};

# Удаление контакта
post '/delete' => sub ($c) {
    my $candidate = $c->param( 'data' );

    # Производим уникальный поиск по паттерну
    my $contact = PhoneBook::search_by_full_match( $candidate );

    # Если поиск нашёл более одного значения или завершился ошибкой - выводим алерт
    if ( exists $contact->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $contact->{alert},
        );
    }
    # Если поиск вернул лишь одно значение - удаляем контакт
    else {
        my $phone         = %{ $contact };
        my $remove_result = PhoneBook::remove_contact( $phone );

        $c->render(
            template => 'alert',
            alert    => $remove_result->{alert},
        );
    }
};

# Поиск контакта для модификации
get '/modify' => sub($c) {
    my $candidate = $c->param( 'data' );

    # Производим уникальный поиск по паттерну
    my $contact = PhoneBook::search_by_full_match( $candidate );
    # Если поиск нашёл более одного значения или завершился ошибкой - выводим алерт
    if ( exists $contact->{alert} ) {
        $c->render(
            template => 'alert',
            alert    => $contact->{alert},
        );
    }
    # Поиск вернул одно значение - отрисовываем шаблон для редактирования
    else {
        $c->render(
            template => 'modify',
            rows     => $contact,
        );
    }
};

# Модификация контакта
post '/modify' => sub($c) {
    my $result = PhoneBook::modify_contact(
        old_name  => $c->param( 'old_name'  ),
        new_name  => $c->param( 'new_name'  ),
        old_phone => $c->param( 'old_phone' ),
        new_phone => $c->param( 'new_phone' ),
    );
    # Возвращается всегда алерт(как при удачном редактировании так и при ошибке).
    $c->render(
        template => 'alert',
        alert    => $result->{alert},
    );
};

app->start;
