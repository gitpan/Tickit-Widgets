#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::RadioButton;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;

our $VERSION = '0.10';

use Carp;

use Tickit::Utils qw( textwidth );
use List::MoreUtils qw( any );

use constant CAN_FOCUS => 1;

=head1 NAME

C<Tickit::Widget::RadioButton> - a widget allowing a selection from multiple
options

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::RadioButton;
 use Tickit::Widget::VBox;

 my $group = Tickit::Widget::RadioButton::Group->new;

 my $vbox = Tickit::Widget::VBox->new;
 $vbox->add( Tickit::Widget::RadioButton->new(
       caption => "Radio button $_",
       group   => $group,
 ) ) for 1 .. 5;

 Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This class provides a widget which allows a selection of one value from a
group of related options. It provides a clickable area and a visual indication
of which button in the group is the one currently active. Selecting a new
button within a group will unselect the previously-selected one.

This widget is part of an experiment in evolving the design of the
L<Tickit::Style> widget integration code, and such is subject to change of
details.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item tick => PEN

The pen used to render the tick marker

=back

The following style keys are used:

=over 4

=item tick => STRING

The text used to indicate the active button

=item spacing => INT

Number of columns of spacing between the tick mark and the caption text

=back

The following style tags are used:

=over 4

=item :active

Set when this button is the active one of the group.

=back

=cut

style_definition base =>
   tick_fg => "hi-white",
   tick_b  => 1,
   tick    => "( )",
   spacing => 2,
   '<Space>' => "activate";

style_definition ':active' =>
   b        => 1,
   tick     => "(*)";

style_reshape_keys qw( spacing );

style_reshape_textwidth_keys qw( tick );

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $radiobutton = Tickit::Widget::RadioButton->new( %args )

Constructs a new C<Tickit::Widget::RadioButton> object.

Takes the following named argmuents

=over 8

=item label => STRING

The label text to display alongside this button.

=item group => Tickit::Widget::RadioButton::Group

Optional. If supplied, the group that the button should belong to. If not
supplied, a new group will be constructed that can be accessed using the
C<group> accessor.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{label} = $args{label};
   $self->{group} = $args{group} || Tickit::Widget::RadioButton::Group->new;

   return $self;
}

sub lines
{
   my $self = shift;
   return 1;
}

sub cols
{
   my $self = shift;
   return textwidth( $self->get_style_values( "tick" ) ) +
          $self->get_style_values( "spacing" ) +
          textwidth( $self->{label} );
}

=head1 ACCESSORS

=cut

=head2 $group = $radiobutton->group

Returns the C<Tickit::Widget::RadioButton::Group> this button belongs to.

=cut

sub group
{
   my $self = shift;
   return $self->{group};
}

=head2 $label = $radiobutton->label

=head2 $radiobutton->set_label( $label )

Returns or sets the label text of the button.

=cut

sub label
{
   my $self = shift;
   return $self->{label};
}

sub set_label
{
   my $self = shift;
   ( $self->{label} ) = @_;
   $self->reshape;
   $self->redraw;
}

=head1 METHODS

=cut

=head2 $radiobutton->activate

Sets this button as the active member of the group, deactivating the previous
one.

=cut

*key_activate = \&activate;
sub activate
{
   my $self = shift;
   my $group = $self->{group};

   if( my $old = $group->active ) {
      $old->set_style_tag( active => 0 );
   }

   $group->set_active( $self );

   $self->set_style_tag( active => 1 );
   return 1;
}

=head2 $active = $radiobutton->is_active

Returns true if this button is the active button of the group.

=cut

sub is_active
{
   my $self = shift;
   return $self->group->active == $self;
}

sub reshape
{
   my $self = shift;

   my $win = $self->window or return;

   my $tick = $self->get_style_values( "tick" );

   $win->cursor_at( 0, ( textwidth( $tick )-1 ) / 2 );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->clear;

   return if $rect->top > 0;

   $rb->goto( 0, 0 );

   $rb->text( my $tick = $self->get_style_values( "tick" ), $self->get_style_pen( "tick" ) );
   $rb->erase( $self->get_style_values( "spacing" ) );
   $rb->text( $self->{label} );
   $rb->erase_to( $rect->right );
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   return unless $args->type eq "press" and $args->button == 1;
   return 1 unless $args->line == 0;

   $self->activate;
}

package # hide from indexer
   Tickit::Widget::RadioButton::Group;
use Scalar::Util qw( weaken refaddr );

=head1 GROUPS

Every C<Tickit::Widget::RadioButton> belongs to a group. Only one button can
be active in a group at any one time. The C<group> accessor returns the group
the button is a member of. The following methods are available on it.

A group can be explicitly created to pass to a button's constructor, or one
will be implicitly created for a button if none is passed.

=cut

=head2 $group = Tickit::Widget::RadioButton::Group->new

Returns a new group.

=cut

sub new
{
   my $class = shift;
   return bless \(my $self), $class;
}

=head2 $radiobutton = $group->active

Returns the button which is currently active in the group

=cut

sub active
{
   my $self = shift;
   return $$self;
}

sub set_active
{
   my $self = shift;
   ( $$self ) = @_;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
