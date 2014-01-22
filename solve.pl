#!/usr/bin/env perl

use strict;
use warnings;
use File::Slurp;

=pod
	 0  1  2   3  4  5   6  7  8
    9 10 11  12 13 14  15 16 17
   18 19 20  21 22 23  24 25 26

   27 28 29  30 31 32  33 34 35
   36 37 38  39 40 41  42 43 44
   45 46 47  48 49 50  51 52 53

   54 55 56  57 58 59  60 61 62
   63 64 65  66 67 68  69 70 71
   72 73 74  75 76 77  78 79 80
=cut

our( 
	@grid, 
	@grids, 
	$n_grid_cells, 
	$grid_length, 
	$cell_length);

&solve($_) for @ARGV;
exit(0);

sub solve {
	my $file = shift;
	my $puz = File::Slurp::read_file($file);
	init_grid($puz);
	solve_loop();
	print is_solved() ? "$file\t\tsolved :)  \n" : "$file\t\tnot solved :( \n"; 
	File::Slurp::write_file("$file.solved",grid_to_string()) if is_solved(); }

sub is_solved {
	! grep {has(0,$_)} @{ get_squares()} }

sub grid_to_string {
	my $i = -1;
	my @str;
	for(@grid) {
		++$i;
		push @str,"\n" if($i % $grid_length) == 0;
		push @str,"\n" if $i % ($grid_length * $cell_length) == 0;
		push @str,$_->{n}," ";
		push @str,"  " if (($i+1) % $cell_length == 0) && ($i % $grid_length); }
	push @str,"\n";
	join '',@str }

sub print_grid {
	print grid_to_string(); }

sub init_grid {
	my $idx = -1;
	@grid = map { { n => $_, idx => ++$idx } } split /\s+/s,(shift);
	@grids = ();	
	$n_grid_cells = @grid;
	$grid_length = sqrt $n_grid_cells;
	$cell_length = sqrt $grid_length;
	die "init_grid, error creating grid, grid doesnt seem to be square\n" 
		unless $n_grid_cells == (($cell_length ** 2) * ($cell_length ** 2)); }

sub start_test {
	push @grids, [map{ { %$_ } } @grid] }

sub reset_test {
	@grid = @{ pop @grids } }

## only method that sets a cell's number ( cell->{n} )
## does error checking to make sure same number doesn't 
## appear in any other horizontal, vertical or same square

sub set {
	my($n,$idx) = @_;
	$idx = get_idx($idx);	
	return 0 for grep {has($n,$_->($idx))} \&get_square, \&get_vertical, \&get_horizontal;
	$grid[$idx]->{n} = $n }

sub get_idx {
	ref $_[0] ? $_[0]->{idx} : $_[0] }

sub get_square {
	my $idx = get_idx(shift);
	my $local_origin = $idx - ((get_row_n($idx) % $cell_length) * $grid_length) - ($idx % $cell_length); 
	[map { $grid[$_] }  
	 map { my $x = $_; map {$x+$_}0..($cell_length-1) } 
	 map { $local_origin + $_ }
	 map { $grid_length  * $_ } 0..($cell_length-1)] }

sub get_vertical {
	my $col = get_idx(shift) % $grid_length;
	[ map{ $grid[$_] } map{ $col + ($grid_length*$_) } 0..($grid_length-1) ] }

sub get_horizontal {
	my $idx = get_idx(shift);
	my $row_start = $idx - (($grid_length+$idx) % $grid_length);
	[ map{ $grid[$_] } $row_start..($row_start+$grid_length-1)] }

sub get_row_n {
	my $idx = get_idx(shift);
	return $_ - 1 for grep {$idx <= (($grid_length * $_) - 1) } 1..$grid_length; }

sub get_needs {
	my %needs = map{$_=>1}1..$grid_length;
	delete @needs{ map{$_->{n}}@{ (shift) }};
	[keys %needs] }

sub get_zeros {
	[grep {$_->{n} == 0} @{ (shift) }] }
	
sub get_nonzeros {
	[grep {$_->{n} != 0} @{ (shift) } ] }

sub get_squares {
	[ 	map {get_square($_)} 
		map { my  $local_origin = $_; 
				map{$local_origin+($_*$cell_length)} 0..($cell_length-1) } 
		map { $cell_length * $grid_length * $_ } 0..($cell_length-1) ] }

sub has {
	my $n = shift;
	grep { $n == $_->{n} }@{ (shift) } }

sub solve_1_missing {
	grep{solve_by_h_v_sq($_)} @{get_zeros(\@grid)} }

sub solve_by_h_v_sq {
	my $z = shift;
	my $needs = get_needs( get_nonzeros( [ @{get_horizontal($z)},@{get_vertical($z)},@{get_square($z)}] ));
	return unless @$needs == 1;
	set($needs->[0],$z) }

sub reset_possibles {
	for my $z (@{ get_zeros(\@grid) }){
		my $nonzs =  get_nonzeros(get_square($z));
		my %p = map {$_ => 1} @{ get_needs($nonzs) };
		delete @p{ map{ $_->{n} } @{get_horizontal($z)}, @{get_vertical($z)}, @$nonzs };
		$z->{possibles} = \%p;}}

sub solve_w_possibles  {
	reset_possibles();
	for my $sq (@{ get_squares() }){
		my $zs = get_zeros($sq);
		my $needs = get_needs(get_nonzeros($sq));
		for my $need (@$needs) {
			my @z_needs = grep {exists $_->{possibles}->{$need}} @$zs;
			next if @z_needs == 1 && set($need,$z_needs[0]);

			ZEROS:for my $z (grep{!has($need,get_horizontal($_))}@$zs) {
				my $other_vs = get_vertical($z);
				next if has($need,$other_vs);
				my $other_v_zs = get_zeros($other_vs);
				(next ZEROS) for grep{ $_ != $z && exists $_->{possibles}->{$need}} @$other_v_zs;
				return 1 if set($need,$z);}}}}

sub solve_w_testing {
	for( @{ get_squares() }) {
		my($first_z) = @{get_zeros($_)};
		next unless $first_z;
		for( @{ get_needs(get_nonzeros($_)) } ) {
			start_test();
			solve_loop() if set($_,$first_z);
			my $is_solved = is_solved();
			reset_test() unless $is_solved;
			return 1 if $is_solved; } } }

sub solve_loop {
	until( is_solved() ) {
		next if solve_1_missing();
		next if solve_w_possibles();
		solve_w_testing();
		last; }}
