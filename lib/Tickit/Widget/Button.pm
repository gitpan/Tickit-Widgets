#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Button;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;
use Tickit::RenderContext qw( LINE_SINGLE );

our $VERSION = '0.08';

use Tickit::Utils qw( textwidth );

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

use constant WIDGET_PEN_FROM_STYLE => 1;

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

   my $lines = $win->lines;
   my $cols  = $win->cols;
   my $rc = Tickit::RenderContext->new( lines => $lines, cols => $cols );
   $rc->clip( $rect );
   $rc->setpen( $self->pen );

   my $label = $self->label;
   my $width = textwidth $label;
   my $focused = $win->is_focused;

   my ( $lines_before, undef, $lines_after ) = $self->_valign_allocation( 1, $lines - 2 );
   my ( $cols_before, undef, $cols_after ) = $self->_align_allocation( $width + 2, $cols - 2 );

   $rc->hline_at( 0,        0, $cols-1, LINE_SINGLE );
   $rc->hline_at( $lines-1, 0, $cols-1, LINE_SINGLE );
   $rc->vline_at( 0, $lines-1, 0,       LINE_SINGLE );
   $rc->vline_at( 0, $lines-1, $cols-1, LINE_SINGLE );

   foreach my $line ( 1 .. $lines-2 ) {
      $rc->erase_at( $line, 1, $cols-2 );
   }

   my $label_line = $lines_before + 1;
   $rc->text_at( $label_line, $cols_before + 2, $label );

   if( $focused ) {
      $rc->char_at( $label_line, $cols_before, 0x25B6 ); # Black right-pointing triangle
      $rc->char_at( $label_line, $cols-1 - $cols_after, 0x25C0 ); # Black left-pointing triangle
   }

   $rc->flush_to_window( $win );
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
