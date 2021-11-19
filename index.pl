#!/usr/bin/perl

use Modern::Perl;
use Mojolicious::Lite -signatures;

use lib "./";
use mysql_operations qw (show_all search add_contact remove_contact modify_contact);

#use strict;
#use warnings;

get '/' => sub ($c) {
    my @rows = show_all ();
    if ( $rows[0] eq "Something") {
        $c->stash( error => @rows );
        $c->render( template => 'alert' );
    }
    else {
        $c->stash( 'len'=>$#rows );
        $c->render( template => 'index', 
                    rows => \@rows, );
    }
};

post '/' => sub ($c) {
    my $result = add_contact( $c->param ('name'), 
                              $c->param ('phone'),
                            );
    if ( $result eq 0 ) {
        $c->redirect_to( '/' );
    } 
    else {
        $c->stash( error => $result );
        $c->render( template => 'alert' );
    }
};

post '/search' => sub ($c) {
    my $pattern = $c->param( 'data' );
    my @rows = search( $pattern );
    
    # Если поиск завершился успешно
    if ( grep /^ARRAY/, $rows[0]) {
        $c->stash( 'len'=>$#rows );
        $c->render( template => 'index',
                    rows => \@rows, );
    }
    # Поиск завершился ошибкой
    else {
        $c->stash( error => @rows);
        $c->render( template => 'alert' );
    }
};

post '/delete' => sub ($c) {
    my $candidat = $c->param( 'data' );

    my $candidat_validation = validate_remove_condidat($candidat);

    if ( $candidat_validation eq 0 ){
        remove_contact($candidat); 
        $c->redirect_to( '/' );
    } 
    else {
        $c->stash( error => $candidat_validation);
        $c->render( template => 'alert' );
    }
};

app->start;
