#!/usr/bin/perl

use Modern::Perl;
use Mojolicious::Lite -signatures;

use lib "./";
use mysql_operations;

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

post '/' => sub ($c) {
    my $result = add_contact( $c->param ('name'), 
                              $c->param ('phone'),
                            );

    if (exists $result->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $result->{'Alert'}, );
    }
    else {
        $c->redirect_to( '/' );
    }
};

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

post '/delete' => sub ($c) {
    my $candidat = $c->param( 'data' );

    my $search_result = search_uniq_contact($candidat);
    
    if (exists $search_result->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $search_result->{'Alert'}, );
    }
    else {
        my ($phone, undef) = each %$search_result;
        remove_contact($phone);
        $c->redirect_to( '/' );
    }
};

get '/modify' => sub($c) {
    my $candidat = $c->param( 'data' );
    
    my $search_result = search_uniq_contact( $candidat );
    # Поиск завершился ошибкой
    if (exists $search_result->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $search_result->{'Alert'}, );
    }
    # Поиск вернул одно значение - можно редактировать.
    else {
        $c->render( template => 'modify',
                    rows => $search_result, );
    }
};

post '/modify' => sub($c) {
    my $old_name = $c->param( 'old_name' );
    my $new_name = $c->param( 'new_name' );
    my $old_phone = $c->param( 'old_phone' );
    my $new_phone = $c->param( 'new_phone' );

    my $result = modify( $old_name, $new_name, $old_phone, $new_phone );

    # Возвращается всегда алерт(как при удачном редактировании так и при ошибке).
    $c->render( template => 'alert',
                alert => $result->{'Alert'}, );
};

app->start;
