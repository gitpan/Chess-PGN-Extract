package Chess::PGN::Extract::Stream;
use 5.008001;
use strict;
use warnings;

use base 'Exporter::Tiny';
our @EXPORT = qw| pgn_file read_game read_games |;

use Carp       qw| croak |;
use File::Temp qw| tempdir tempfile |;
use Chess::PGN::Extract 'read_games' => { -prefix => '_' };

sub new {
  my ( $class, $pgn_file ) = @_;

  croak ("'new' requires a PGN file name")
    unless defined $pgn_file;

  my $self = {};
  $self->{pgn_file} = $pgn_file;
  open my $pgn_handle, '<', $pgn_file
    or croak ("Cannot open PGN file: \"$pgn_file\"");
  $self->{pgn_handle} = $pgn_handle;

  bless $self => $class;
}

sub pgn_file { $_[0]->{pgn_file} }

sub read_game {
  ( $_[0]->read_games (1) )[0];
}

sub read_games {
  my $self = shift;
  my ($limit) = @_;

  my $handle = $self->{pgn_handle};
  return if eof $handle;

  if ( ( not defined $limit ) || $limit < 0 ) {
    # Slurp the PGN file if $limit is not set or negative
    my $all = do { local $/; <$handle> };
    return ( _read_pgn_string ($all) );
  }
  elsif ( $limit == 0 ) {return}
  else {
    my @games;
    my @lines = ( scalar readline $handle );
    while ( my $line = readline $handle ) {
      unless ( $line =~ /^\[Event / ) {
        # We merely check the end of a game by the above regex.
        # It should be implemented by a more strict manner.
        push @lines, $line;
      }
      else {
        push @games, join ( '', @lines );
        unless ( --$limit > 0 ) {
          return ( _read_pgn_string ( join ( '', @games ) ) );
        }
        @lines = ($line);
      }
    }
    push @games, join ( '', @lines );
    return ( _read_pgn_string ( join ( '', @games ) ) );
  }
}

# _read_pgn_string ($pgn_string) => @games
sub _read_pgn_string {
  my ($pgn_string) = @_;

  my $tmp_dir = tempdir (
    $ENV{TMPDIR} . "/chess_pgn_extract_stream_XXXXXXXX",
    CLEANUP => 1 );
  my ( $tmp_handle, $tmp_file ) = tempfile ( DIR => $tmp_dir );
  print $tmp_handle $pgn_string;
  close $tmp_handle;

  return ( _read_games ($tmp_file) );
}

1;
__END__

=encoding utf-8

=head1 NAME

Chess::PGN::Extract::Stream - File stream for reading PGN files

=head1 SYNOPSIS

    my $stream = Chess::PGN::Extract->new ("filename.pgn");
    while ( my $game = $stream->read_game ) {
      # You can read games one by one
    }

    # ... or a chunk of games you want
    my @game = $stream->read_games (10);

=head1 DESCRIPTION

B<Chess::PGN::Extract::Stream> provides a simple class of file stream by which
you can extract chess records one by one or chunk by chunk from Portable Game
Notation (PGN) files.

=head1 ATTRIBUTES AND METHODS

=over

=item B<$class-E<gt>new ($pgn_file)>

Create a stream instance from the C<$pgn_file>.

=item B<$self-E<gt>pgn_file> (read only)

PGN file name from which the stream reads games.

=item B<$self-E<gt>read_game ()>

Read a game from the stream.

=item B<$self-E<gt>read_games ($limit)>

Read a number of games at once and return an C<ARRAY> of them. If C<$limit> is a
positive number, it reads games until the number of them reaches the C<$limit>.
If C<$limit> is C<undef> or negative, it slurps the PGN file and returns all the
games contained.

=back

=head1 SEE ALSO

L<Chess::PGN::Extract>

=head1 BUGS

Please report any bugs to
L<https://bitbucket.org/mnacamura/chess-pgn-extract/issues>.

=head1 AUTHOR

Mitsuhiro Nakamura E<lt>m.nacamura@gmail.comE<gt>

Many thanks to David J. Barnes for his original development of
L<pgn-extract|http://www.cs.kent.ac.uk/people/staff/djb/pgn-extract/> and
basicer at Bitbucket for
L<his work on JSON enhancement|https://bitbucket.org/basicer/pgn-extract/>.

=head1 LICENSE

Copyright (C) 2014 Mitsuhiro Nakamura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
