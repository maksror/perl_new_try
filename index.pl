#!/usr/bin/perl

use Modern::Perl;
use Mojolicious::Lite -signatures;

use lib "./";
use mysql_operations;

get '/' => sub ($c) {
    my $contacts = show_all ();

    if (exists $contacts->{'Alert'}){
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

    if (exists $result->{'Alert'}){
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
    
    # Поиск завершился ошибкой
    if (exists $contacts->{'Alert'}) {
        $c->render( template => 'alert',
                    alert => $contacts->{'Alert'}, );
    }
    # Поиск завершился успешно
    else {
        $c->render( template => 'index',
                    rows => $contacts, );

    }
};

post '/delete' => sub ($c) {
    my $candidat = $c->param( 'data' );

    my $result = remove_contact($candidat);

    if (exists $result->{'Alert'}){
        $c->render( template => 'alert',
                    alert => $result->{'Alert'}, );
    }
    else {
        $c->redirect_to( '/' );
    }

    

};

app->start;
