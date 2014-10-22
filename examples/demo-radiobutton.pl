#!/usr/bin/perl

use strict;
use warnings;

use Tickit::Widgets qw( VBox RadioButton );

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

my $group = Tickit::Widget::RadioButton::Group->new;
foreach ( 1 .. 5 ) {
   $vbox->add( Tickit::Widget::RadioButton->new(
         class => "radio$_",
         style => { fg => $_ },

         label => "Radio $_",
         group => $group,
   ) );
}

Tickit::Style->load_style_file( "./tickit.style" ) if -e "./tickit.style";

Tickit->new( root => $vbox )->run;
