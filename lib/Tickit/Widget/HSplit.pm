#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::HSplit;

use strict;
use warnings;
use base qw( Tickit::Widget::LinearSplit );
use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE CAP_BOTH );

our $VERSION = '0.11';

use Carp;

use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::HSplit> - an adjustable horizontal split between two widgets

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::HSplit;
 use Tickit::Widget::Static;

 my $hsplit = Tickit::Widget::HSplit->new(
    top_child    => Tickit::Widget::Static->new( text => "Text above" ),
    bottom_child => Tickit::Widget::Static->new( text => "Text below" ),
 );

 Tickit->new( root => $hsplit )->run;

=head1 DESCRIPTION

This container widget holds two child widgets, displayed one above the other.
The two widgets are displayed with a horizontal split bar between them, which
reacts to mouse click-drag events, allowing the user to adjust the proportion
of space given to the two widgets.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item split => PEN

The pen used to render the horizontal split area

=back

The following style keys are used:

=over 4

=item spacing => INT

The number of lines of spacing between the top and bottom child widgets

=back

The following style tags are used:

=over 4

=item :active

Set when a mouse drag resize operation is occurring

=back

=cut

style_definition base =>
   split_fg => "white",
   split_bg => "blue",
   spacing => 1;

style_definition ':active' =>
   split_fg => "hi-white",
   split_b => 1;

style_reshape_keys qw( spacing );

use constant WIDGET_PEN_FROM_STYLE => 1;

use constant VALUE_METHOD => "lines";

=head1 CONSTRUCTOR

=head2 $hsplit = Tickit::Widget::HSplit->new( %args )

Constructs a new C<Tickit::Widget::HSplit> object.

Takes the following named arguments

=over 8

=item top_child => WIDGET

=item bottom_child => WIDGET

Child widgets to use

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   $args{A_child} = delete $args{top_child};
   $args{B_child} = delete $args{bottom_child};

   return $class->SUPER::new( %args );
}

sub lines
{
   my $self = shift;
   my $spacing = $self->get_style_values( "spacing" );
   return sum(
      $self->{A_child} ? $self->{A_child}->lines : 1,
      $spacing,
      $self->{B_child} ? $self->{B_child}->lines : 1,
   );
}

sub cols
{
   my $self = shift;
   return max(
      $self->{A_child} ? $self->{A_child}->cols : 1,
      $self->{B_child} ? $self->{B_child}->cols : 1,
   );
}

=head1 ACCESSORS

=cut

=head2 $child = $hsplit->top_child

Returns the child widget used in the top half of the display.

=cut

sub top_child
{
   my $self = shift;
   return $self->{A_child};
}

=head2 $child = $hsplit->bottom_child

Returns the child widget used in the bottom half of the display.

=cut

sub bottom_child
{
   my $self = shift;
   return $self->{B_child};
}

sub _make_child_geom
{
   my $self = shift;
   my ( $start, $len ) = @_;
   return ( $start, 0, $len, $self->window->cols );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $split_len = $self->{split_len};

   my $cols = $self->window->cols;

   $rb->setpen( $self->get_style_pen( "split" ) );

   $rb->hline_at( $self->{split_at}, 0, $cols-1, LINE_SINGLE, undef, CAP_BOTH );

   foreach my $line ( $rect->linerange( 1, $split_len-2 ) ) {
      $rb->erase_at( $self->{split_at} + $line, 0, $cols );
   }

   if( $split_len > 1 ) {
      $rb->hline_at( $self->{split_at} + $split_len - 1, 0, $cols-1, LINE_SINGLE, undef, CAP_BOTH );
   }
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   return unless $args->button == 1;
   return $self->_on_mouse( $args->type, $args->line );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
