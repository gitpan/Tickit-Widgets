#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Frame;

use strict;
use warnings;
use base qw( Tickit::SingleChildWidget );
use Tickit::Style;

use Tickit::WidgetRole::Alignable name => "title_align";

our $VERSION = '0.28';

use Carp;

use Tickit::Pen;
use Tickit::Utils qw( textwidth substrwidth );

=head1 NAME

C<Tickit::Widget::Frame> - draw a frame around another widget

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Frame;
 use Tickit::Widget::Static;

 my $hello = Tickit::Widget::Static->new(
    text   => "Hello, world",
    align  => "centre",
    valign => "middle",
 );

 my $frame = Tickit::Widget::Frame->new;

 $frame->add( $hello );

 Tickit->new( root => $frame )->run;

=head1 DESCRIPTION

This container widget draws a frame around a single child widget.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item frame => PEN

The pen used to render the frame lines

=back

The following style keys are used:

=over 4

=item linetype => STRING

Controls the type of line characters used to draw the frame. Must be one of
the following names:

 ascii single double thick solid_inside solid_outside

The C<ascii> linetype is default, and uses only the C<-|+> ASCII characters.
Other linetypes use Unicode box-drawing characters. These may not be supported
by all terminals or fonts.

=back

=cut

style_definition base =>
   linetype => "ascii";

style_redraw_keys qw( linetype );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $frame = Tickit::Widget::Frame->new( %args )

Constructs a new C<Tickit::Widget::Static> object.

Takes the following named arguments in addition to those taken by the base
L<Tickit::SingleChildWidget> constructor:

=over 8

=item title => STRING

Optional.

=item title_align => FLOAT|STRING

Optional. Defaults to C<0.0> if unspecified.

=back

For more details see the accessors below.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   # Previously 'linetype' was called 'style', but it collided with
   # Tickit::Widget's idea of style
   if( defined $args{style} and !ref $args{style} ) {
      $args{style} = { linetype => delete $args{style} };
   }

   my $self = $class->SUPER::new( %args );

   $self->set_title( $args{title} ) if defined $args{title};
   $self->set_title_align( $args{title_align} || 0 );

   return $self;
}

=head1 ACCESSORS

=cut

sub lines
{
   my $self = shift;
   my $child = $self->child;
   return ( $child ? $child->lines : 0 ) + 2;
}

sub cols
{
   my $self = shift;
   my $child = $self->child;
   return ( $child ? $child->cols : 0 ) + 2;
}

use constant {
   TOP       => 0,
   BOTTOM    => 1,
   LEFT      => 2,
   RIGHT     => 3,
   CORNER_TL => 4,
   CORNER_TR => 5,
   CORNER_BL => 6,
   CORNER_BR => 7,
};

# Character numbers from
#   http://en.wikipedia.org/wiki/Box-drawing_characters

my %LINECHARS = ( #            TOP     BOTTOM  LEFT    RIGHT   TL      TR      BL      BR
   ascii         => [          '-',    '-',    '|',    '|',    '+',    '+',    '+',    '+' ],
   single        => [ map chr, 0x2500, 0x2500, 0x2502, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518 ],
   double        => [ map chr, 0x2550, 0x2550, 0x2551, 0x2551, 0x2554, 0x2557, 0x255A, 0x255D ],
   thick         => [ map chr, 0x2501, 0x2501, 0x2503, 0x2503, 0x250F, 0x2513, 0x2517, 0x251B ],
   solid_inside  => [ map chr, 0x2584, 0x2580, 0x2590, 0x258C, 0x2597, 0x2596, 0x259D, 0x2598 ],
   solid_outside => [ map chr, 0x2580, 0x2584, 0x258C, 0x2590, 0x259B, 0x259C, 0x2599, 0x259F ],
);

=head2 $linetype = $frame->linetype

=cut

sub linetype
{
   my $self = shift;
   return scalar $self->get_style_values( "linetype" );
}

=head2 $title = $frame->title

=cut

sub title
{
   my $self = shift;
   return $self->{title};
}

=head2 $frame->set_title( $title )

Accessor for the C<title> property, a string written in the top of the
frame.

=cut

sub set_title
{
   my $self = shift;
   $self->{title} = $_[0];
   $self->redraw;
}

=head2 $title_align = $frame->title_align

=head2 $frame->set_title_align( $title_align )

Accessor for the C<title_align> property. Gives a vlaue in the range C<0.0> to
C<1.0> to align the title in the top of the frame.

See also L<Tickit::WidgetRole::Alignable>.

=cut

## This should come from Tickit::ContainerWidget
sub children_changed { shift->reshape }

sub reshape
{
   my $self = shift;

   my $window = $self->window or return;
   my $child  = $self->child  or return;

   my $lines = $window->lines;
   my $cols  = $window->cols;

   if( $lines > 2 and $cols > 2 ) {
      if( my $childwin = $child->window ) {
         $childwin->change_geometry( 1, 1, $lines - 2, $cols - 2 );
      }
      else {
         my $childwin = $window->make_sub( 1, 1, $lines - 2, $cols - 2 );
         $child->set_window( $childwin );
      }
   }
   else {
      if( $child->window ) {
         $child->set_window( undef );
      }
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $cols  = $self->window->cols;
   my $lines = $self->window->lines;

   my $linechars = $LINECHARS{$self->linetype};

   $rb->setpen( $self->get_style_pen( "frame" ) );

   foreach my $line ( $rect->linerange ) {
      $rb->goto( $line, 0 );

      if( $line == 0 ) {
         # Top line
         $rb->text( $linechars->[CORNER_TL] );

         if( defined( my $title = $self->title ) ) {
            # At most we can fit $cols-4 columns of title
            my ( $left, $titlewidth, $right ) = $self->_title_align_allocation( textwidth( $title ), $cols - 4 );

            $rb->text( $linechars->[TOP] x $left ) if $left > 0;
            $rb->text( " " );
            $rb->text( $title );
            $rb->text( " " );
            $rb->text( $linechars->[TOP] x $right ) if $right > 0;
         }
         else {
            $rb->text( $linechars->[TOP] x ($cols - 2) ) if $cols > 2;
         }

         $rb->text( $linechars->[CORNER_TR] ) if $cols > 1;
      }
      elsif( $line < $lines - 1 ) {
         # Middle line
         $rb->text( $linechars->[LEFT] );

         next if $cols == 1;

         $rb->skip_to( $cols - 1 );
         $rb->text( $linechars->[RIGHT] );
      }
      else {
         # Bottom line
         $rb->text( $linechars->[CORNER_BL] );
         $rb->text( $linechars->[BOTTOM] x ($cols - 2) ) if $cols > 2;
         $rb->text( $linechars->[CORNER_BR] ) if $cols > 1;
      }
   }
}

=head1 TODO

=over 4

=item *

Specific pen for title. Layered on top of frame pen.

=item *

Caption at the bottom of the frame as well. Identical to title.

=item *

Consider if it's useful to provide accessors to apply extra padding inside the
frame, surrounding the child window.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
