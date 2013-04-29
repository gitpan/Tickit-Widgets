#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Button;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;

our $VERSION = '0.06';

use Tickit::Utils qw( textwidth );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::Button> - a widget displaying a clickable button

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Button;

 my $button = Tickit::Widget::Button->new(
    label => "Click Me!",
    on_click => sub {
       my ( $self ) = @_;

       # Do something!
    },
 );

 Tickit->new( root => $button )->run;

=head1 DESCRIPTION

This class provides a widget which displays a clickable area with a label.
When the area is clicked, a callback is invoked.

=head1 STYLE

The default style pen is used as the widget pen.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $entry = Tickit::Widget::Button->new( %args )

Constructs a new C<Tickit::Widget::Button> object.

Takes the following named arguments:

=over 8

=item label => STR

Text to display in the button area

=item on_click => CODE

Optional. Callback function to invoke when the button is clicked.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   my $self = $class->SUPER::new( %params );

   $self->set_label( $params{label} ) if defined $params{label};
   $self->set_on_click( $params{on_click} ) if $params{on_click};

   $self->set_align ( $params{align}  // 0.5 );
   $self->set_valign( $params{valign} // 0.5 );

   return $self;
}

sub lines
{
   return 3;
}

sub cols
{
   my $self = shift;
   return 4 + textwidth $self->label;
}

=head1 ACCESSORS

=cut

=head2 $label = $button->label

=cut

sub label
{
   return shift->{label}
}

=head2 $button->set_label( $label )

Return or set the text to display in the button area.

=cut

sub set_label
{
   my $self = shift;
   ( $self->{label} ) = @_;
   $self->redraw;
}

=head2 $on_click = $button->on_click

=cut

sub on_click
{
   my $self = shift;
   return $self->{on_click};
}

=head2 $button->set_on_click( $on_click )

Return or set the CODE reference to be called when the button area is clicked.

 $on_click->( $button )

=cut

sub set_on_click
{
   my $self = shift;
   ( $self->{on_click} ) = @_;
}

=head2 $align = $button->align

=head2 $button->set_align( $align )

=head2 $valign = $button->valign

=head2 $button->set_valign( $valign )

Accessors for the horizontal and vertical alignment of the label text within
the button area. See also L<Tickit::WidgetRole::Alignable>.

=cut

use Tickit::WidgetRole::Alignable name => "align",  style => "h";
use Tickit::WidgetRole::Alignable name => "valign", style => "v";

use constant CLEAR_BEFORE_RENDER => 0;
sub render
{
   my $self = shift;
   my %args = @_;

   my $win = $self->window or return;
   $win->is_visible or return;
   my $rect = $args{rect};

   my $label = $self->label;
   my $width = textwidth $label;
   my $focused = $win->is_focused;

   my ( $lines_before, undef, $lines_after ) = $self->_valign_allocation( 1, $win->lines - 2 );
   my $cols2 = $win->cols - 2;
   my ( $cols_before, undef, $cols_after ) = $self->_align_allocation( $width + 2, $cols2 );

   if( $rect->top == 0 ) {
      $win->goto( 0, 0 );
      $win->print( "+" . ( "-" x $cols2 ) . "+" );
   }
   for( $rect->top + 1 .. $lines_before ) {
      $win->goto( $_, 0 );
      $win->print( "|" );
      $win->erasech( $cols2, 1 );
      $win->print( "|" );
   }

   $win->goto( $lines_before + 1, 0 );
   $win->print( "|" );
   $win->erasech( $cols_before, 1 );
   $win->print( $focused ? ">" : " " );
   $win->print( $label );
   $win->print( $focused ? "<" : " " );
   $win->erasech( $cols_after, 1 );
   $win->print( "|" );

   for( $rect->bottom - $lines_after - 1 .. $rect->bottom - 2 ) {
      $win->goto( $_, 0 );
      $win->print( "|" );
      $win->erasech( $cols2, 1 );
      $win->print( "|" );
   }
   if( $rect->bottom == $win->lines ) {
      $win->goto( $rect->bottom - 1, 0 );
      $win->print( "+" . ( "-" x $cols2 ) . "+" );
   }
}

sub on_mouse
{
   my $self = shift;
   my ( $ev, $button, $line, $col ) = @_;

   if( $ev eq "press" and $button == 1 ) {
      $self->window->focus( 1, 1 ); # TODO
      $self->redraw;
   }
   elsif( $ev eq "release" and $button == 1 ) {
      $self->{on_click}->( $self );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
