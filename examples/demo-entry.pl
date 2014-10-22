#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;
use Tickit::Widget::Entry;

use Tickit::Widget::Box;
use Tickit::Widget::VBox;

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

$vbox->add( Tickit::Widget::Static->new( text => "Enter some text here:" ) );

$vbox->add( Tickit::Widget::Box->new(
   h_border => 2,
   v_border => 1,
   bg => 'blue',
   child =>
      ( my $entry = Tickit::Widget::Entry->new ),
) );

$vbox->add( my $label = Tickit::Widget::Static->new( text => "" ) );

$entry->set_on_enter( sub {
   $label->set_text( "You entered: $_[1]" );
   $_[0]->set_text( "" );
} );

my $tickit = Tickit->new();

$tickit->set_root_widget( $vbox );

$tickit->run;
