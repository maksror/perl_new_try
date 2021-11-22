#!/usr/bin/perl

use Modern::Perl;
use Mojolicious::Lite -signatures;

use lib "./";
use mysql_operations;

# Отрисовка главной страницы
get '/' => sub ($c) {
    my $contacts = show_all ();

    if (exists $contacts->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $contacts->{'Alert'}, );
    }
    else {
        $c->render( template => 'index', 
                    rows => $contacts, );
    }
};

# Добавление контакта
post '/add' => sub ($c) {
    my $result = add_contact( $c->param ('name'), 
                              $c->param ('phone'),
                            );

    # Возвращается всегда аллетр, поэтому задействуем только этот шаблон
    $c->render( template => 'alert',
                alert => $result->{'Alert'}, );
};

# Поиск контакта
post '/search' => sub ($c) {
    my $pattern = $c->param( 'data' );

    my $contacts = search( $pattern );
    
    if (exists $contacts->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $contacts->{'Alert'}, );
    }
    else {
        $c->render( template => 'index',
                    rows => $contacts, );

    }
};

# Удаление контакта
post '/delete' => sub ($c) {
    my $candidat = $c->param( 'data' );

    # Производим уникальный поиск по паттерну
    my $search_result = search_uniq_contact($candidat);
    
    # Если поиск нашёл более одного значения или завершился ошибкой - выводим алерт
    if (exists $search_result->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $search_result->{'Alert'}, );
    }
    # Если поиск вернул лишь одно значение - удаляем контакт
    else {
        my ($phone, undef) = each %$search_result;
        my $remove_result = remove_contact($phone);
        $c->render( template => 'alert',
                    alert => $remove_result->{'Alert'}, );

    }
};

# Поиск контакта для модификации 
get '/modify' => sub($c) {
    my $candidat = $c->param( 'data' );
    
    # Производим уникальный поиск по паттерну
    my $search_result = search_uniq_contact( $candidat );
    # Если поиск нашёл более одного значения или завершился ошибкой - выводим алерт
    if (exists $search_result->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $search_result->{'Alert'}, );
    }
    # Поиск вернул одно значение - отрисовываем шаблон для редактирования
    else {
        $c->render( template => 'modify',
                    rows => $search_result, );
    }
};

# Модификация контакта
post '/modify' => sub($c) {
    my $old_name = $c->param( 'old_name' );
    my $new_name = $c->param( 'new_name' );
    my $old_phone = $c->param( 'old_phone' );
    my $new_phone = $c->param( 'new_phone' );

    # Тригерим само изменение
    my $result = modify( $old_name, $new_name, $old_phone, $new_phone );

    # Возвращается всегда алерт(как при удачном редактировании так и при ошибке).
    $c->render( template => 'alert',
                alert => $result->{'Alert'}, );
};

app->start;
