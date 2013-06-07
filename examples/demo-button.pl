#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Border Button VBox );

Tickit::Style->load_style( <<'EOF' );
Button {
  fg: "black";
  bg: "white";
}
EOF

my $border = Tickit::Widget::Border->new(
   h_border => 10,
   v_border => 2,
   child => my $vbox = Tickit::Widget::VBox->new( spacing => 2, bg => "black" ),
);

foreach my $colour (qw( red blue green yellow )) {
   $vbox->add(
      Tickit::Widget::Button->new(
         label => $colour,
         on_click => sub { $border->pen->chattr( bg => $colour ) },
      )
   );
}

my $tickit = Tickit->new( root => $border );

$vbox->add(
   Tickit::Widget::Button->new(
      label => "Quit",
      on_click => sub { $tickit->stop },
   )
);

$tickit->run;
