#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::GridBox;

use strict;
use warnings;
use base qw( Tickit::ContainerWidget );

our $VERSION = '0.04';

use Carp;

use Tickit::Utils 0.29 qw( distribute );

use List::Util qw( sum max );

use constant CLEAR_BEFORE_RENDER => 0;

=head1 NAME

C<Tickit::Widget::GridBox> - lay out a set of child widgets in a grid

=head1 SYNOPSIS

 use Tickit:
 use Tickit::Widget::GridBox;
 use Tickit::Widget::Static;

 my $tickit = Tickit->new;

 my $gridbox = Tickit::Widget::GridBox->new(
    col_spacing => 2,
    row_spacing => 1,
 );

 $gridbox->add( 0, 0, Tickit::Widget::Static->new( text => "top left" ) );
 $gridbox->add( 0, 1, Tickit::Widget::Static->new( text => "top right" ) );
 $gridbox->add( 1, 0, Tickit::Widget::Static->new( text => "bottom left" ) );
 $gridbox->add( 1, 1, Tickit::Widget::Static->new( text => "bottom right" ) );

 $tickit->set_row_spacing( $gridbox );

 $tickit->run;

=head1 DESCRIPTION

This container widget holds a set of child widgets distributed in a regular
grid shape across rows and columns.

=cut

=head1 CONSTRUCTOR

=head2 $gridbox = Tickit::Widget::GridBox->new( %args )

Constructs a new C<Tickit::Widget::GridBox> object.

Takes the following named arguments:

=over 8

=item col_spacing => INT

=item row_spacing => INT

Optional. Initial values for the C<col_spacing> and C<row_spacing> attributes.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{grid} = [];
   $self->{max_col} = 0;

   $self->set_row_spacing( $args{row_spacing} || 0 );
   $self->set_col_spacing( $args{col_spacing} || 0 );

   return $self;
}

=head1 ACCESSORS

=cut

=head2 $spacing = $gridbox->row_spacing

=head2 $gridbox->set_row_spacing( $spacing )

Return or set the number of lines of inter-row spacing.

=head2 $spacing = $gridbox->col_spacing

=head2 $gridbox->set_col_spacing( $spacing )

Return or set the number of lines of inter-column spacing.

=cut

foreach my $d (qw( row col )) {
   my $spacing = "${d}_spacing";

   no strict 'refs';
   *$spacing = sub {
      my $self = shift;
      return $self->{$spacing};
   };

   *${\"set_$spacing"} = sub {
      my $self = shift;
      ( $self->{$spacing} ) = @_;
      $self->resized;
   };
}

sub lines
{
   my $self = shift;
   my $max_row = $#{$self->{grid}};
   my $max_col = $self->{max_col};
   return ( sum( map {
         my $r = $_;
         max map {
            my $c = $_;
            my $child = $self->{grid}[$r][$c];
            $child ? $child->lines : 0;
         } 0 .. $max_col
      } 0 .. $max_row ) ) +
      $self->row_spacing * ( $max_row - 1 );
}

sub cols
{
   my $self = shift;
   my $max_row = $#{$self->{grid}};
   my $max_col = $self->{max_col};
   return ( sum( map {
         my $c = $_;
         max map {
            my $r = $_;
            my $child = $self->{grid}[$r][$c];
            $child ? $child->cols : 0;
         } 0 .. $max_row
      } 0 .. $max_col ) ) +
      $self->col_spacing * ( $max_col - 1 );
}

sub children
{
   my $self = shift;
   my $grid = $self->{grid};
   map {
      my $r = $_;
      map {
         $grid->[$r][$_] ? ( $grid->[$r][$_] ) : ()
      } 0 .. $self->{max_col}
   } 0.. $#$grid;
}

=head1 METHODS

=cut

=head2 $gridbox->add( $row, $col, $child, %opts )

Sets the child widget to display in the given grid cell. Cells do not need to
be explicitly constructed; the grid will automatically expand to the size
required. This method can also be used to replace an existing child at the
given cell location. To remove a cell entirely, use the C<remove> method.

The following options are recognised:

=over 8

=item col_expand => INT

=item row_expand => INT

Values for the C<expand> setting for this column or row of the table. The
largest C<expand> setting for any cell in a given column or row sets the value
used to distribute space to that column or row.

=back

=cut

sub add
{
   my $self = shift;
   my ( $row, $col, $child, %opts ) = @_;

   if( my $old_child = $self->{grid}[$row][$col] ) {
      $self->SUPER::remove( $old_child );
   }

   $self->{max_col} = $col if $col > $self->{max_col};

   $self->{grid}[$row][$col] = $child;
   $self->SUPER::add( $child,
      col_expand => $opts{col_expand} || 0,
      row_expand => $opts{row_expand} || 0,
   );
}

=head2 $gridbox->remove( $row, $col )

Removes the child widget on display in the given cell. May shrink the grid if
this was the last child widget in the given row or column.

=cut

sub remove
{
   my $self = shift;
   my ( $row, $col ) = @_;

   my $grid = $self->{grid};

   my $child = $grid->[$row][$col];
   undef $grid->[$row][$col];

   # Tidy up the row
   my $max_col = 0;
   foreach my $col ( reverse 0 .. $#{ $grid->[$row] } ) {
      next if !defined $grid->[$row][$col];

      $max_col = $col+1;
      last;
   }

   splice @{ $grid->[$row] }, $max_col;

   # Tidy up the grid
   my $max_row = 0;
   foreach my $row ( reverse 0 .. $#$grid ) {
      next if !defined $grid->[$row] or !@{ $grid->[$row] };

      $max_row = $row+1;
      last;
   }

   splice @$grid, $max_row;

   $self->{max_col} = max map { $_ ? $#$_ : 0 } @$grid;

   $self->SUPER::remove( $child );
}

sub reshape
{
   my $self = shift;
   $self->redistribute_child_windows;
}

sub children_changed
{
   my $self = shift;

   $self->redistribute_child_windows if $self->window;
   $self->resized; # Tell my parent

   $self->redraw;
}

sub redistribute_child_windows
{
   my $self = shift;
   my $win = $self->window or return;

   my @row_buckets;
   my @col_buckets;

   my $max_row = $#{$self->{grid}};
   my $max_col = $self->{max_col};

   foreach my $row ( 0 .. $max_row ) {
      push @row_buckets, { fixed => $self->row_spacing } if @row_buckets;

      my $base = 0;
      my $expand = 0;

      foreach my $col ( 0 .. $max_col ) {
         my $child = $self->{grid}[$row][$col] or next;

         $base   = max $base, $child->lines;
         $expand = max $expand, $self->child_opts( $child )->{row_expand};
      }

      push @row_buckets, {
         row    => $row,
         base   => $base,
         expand => $expand,
      };
   }

   foreach my $col ( 0 .. $max_col ) {
      push @col_buckets, { fixed => $self->col_spacing } if @col_buckets;

      my $base = 0;
      my $expand = 0;

      foreach my $row ( 0 .. $max_row ) {
         my $child = $self->{grid}[$row][$col] or next;

         $base   = max $base, $child->cols;
         $expand = max $expand, $self->child_opts( $child )->{col_expand};
      }

      push @col_buckets, {
         col    => $col,
         base   => $base,
         expand => $expand,
      };
   }

   distribute( $win->lines, @row_buckets );
   distribute( $win->cols,  @col_buckets );

   my @rows;
   foreach ( @row_buckets ) {
      $rows[$_->{row}] = [ $_->{start}, $_->{value} ] if defined $_->{row};
   }

   my @cols;
   foreach ( @col_buckets ) {
      $cols[$_->{col}] = [ $_->{start}, $_->{value} ] if defined $_->{col};
   }

   foreach my $row ( 0 .. $max_row ) {
      foreach my $col ( 0 .. $max_col ) {
         my $child = $self->{grid}[$row][$col] or next;

         my @geom = ( $rows[$row][0], $cols[$col][0], $rows[$row][1], $cols[$col][1] );

         if( my $childwin = $child->window ) {
            $childwin->change_geometry( @geom );
         }
         else {
            $childwin = $win->make_sub( @geom );
            $child->set_window( $childwin );
         }
      }
   }
}

sub render
{
   my $self = shift;
   my $win = $self->window or return;

   $win->clear;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
