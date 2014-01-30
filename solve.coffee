#!/usr/bin/env coffee

#fs = require 'fs'

grid = null
grids = []
n_grid_cells = 0
grid_length = 0
cell_length = 0

#run = ->
	#for file in process.argv[2..]
		#solve( file,fs.readFileSync(file) )
	#process.exit(0)

solve = (content) ->
	init_grid(content)
	solve_loop()
	grid_to_string()
	#console.log( if is_solved() then "#{file}\t\tsolved :)  \n" else "#{file}\t\tnot solved :( \n")
	#File::Slurp::write_file("$file.solved",grid_to_string()) if is_solved() }

exports = window ? root
window.solve = solve

is_solved = -> (0 for sq in get_squares() when has(0,sq)).length == 0

grid_to_string = (g) ->
	g = grid if not g?
	i = -1
	str = []
	for cell in g
		++i
		str.push('\n') if (i % grid_length) is 0
		str.push('\n') if (i % (grid_length * cell_length)) is 0
		str.push(cell.n + ' ')
		str.push('  ') if (((i + 1) % cell_length) is 0) and (i % grid_length) isnt 0

	str.push('\n')
	str.join ''

print_grid = -> console.log(grid_to_string() )

init_grid = (lines) ->
	idx = -1
	grid = ({'n':parseInt(n),'idx':++idx} for n in (""+lines).split(/\s+/) when /\d/.test(n))
	grids = []
	n_grid_cells = grid.length
	grid_length = Math.sqrt n_grid_cells
	cell_length = Math.sqrt grid_length
	unless n_grid_cells is Math.pow(Math.pow(cell_length,2),2)
		console.log( "init_grid, error creating grid, grid doesnt seem to be square. got n_grid_cells #{n_grid_cells}, cell_length #{cell_length}\n" ) 
		print_grid()

start_test = -> grids.push( (n:cell.n,idx:cell.idx for cell in grid ))

reset_test = -> grid = grids.pop()

## only method that sets a cell's number ( cell->{n} )
## does error checking to make sure same number doesn't 
## appear in any other horizontal, vertical or same square

set = (n,idx,m) ->
	idx = get_idx(idx)
	for fn in [[get_square,'s'], [get_vertical,'v'], [get_horizontal,'h']]# when has(n,fn(idx))
		vs = fn[0](idx)
		if has(n,vs)
			return 0
	grid[idx].n = n

get_idx = (c) -> if typeof c is 'object' then c['idx'] else c

get_square = (c) ->
	idx = get_idx(c)
	local_origin = idx - ((get_row_n(idx) % cell_length) * grid_length) - (idx % cell_length)
	retval = []
	for x in (local_origin + (grid_length * i) for i in [0..(cell_length - 1)])
		for j in [0..(cell_length - 1)]
			retval.push(grid[x + j])
	retval

get_squares = ->
	retval = []
	for l in ( (local_origin + (j * cell_length) for j in [0..(cell_length - 1)]) for local_origin in (cell_length * grid_length * i for i in [0..(cell_length - 1)] ))
		for m in l
			retval.push( get_square(m))
	retval

get_vertical = (c) ->
	col = get_idx(c) % grid_length
	(grid[ col + (grid_length * i)] for i in [0..(grid_length - 1)])
	
get_horizontal = (c) ->
	idx = get_idx(c)
	row_start = idx - ((grid_length + idx) % grid_length)
	(grid[i] for i in [row_start..(row_start + grid_length - 1)])

get_row_n = (c) ->
	idx = get_idx(c)
	(i - 1 for i in [1..grid_length] when idx <= ((grid_length * i) - 1))[0]

get_needs = (non_zeros) -> (i for i in [1..grid_length] when not has(i,non_zeros))

get_zeros =   (list) -> (cell for cell in list when cell.n == 0)

get_nonzeros = (list) -> (cell for cell in list when cell.n != 0)

has = (n,list) ->
	(1 for cell in list when ( (n == cell) || ((typeof cell is "object") and (n is cell.n))))[0]

solve_1_missing = -> (1 for z in get_zeros(grid) when solve_by_h_v_sq(z))[0]

solve_by_h_v_sq = (z) ->
	needs = get_needs( get_nonzeros( get_horizontal(z).concat(get_vertical(z)).concat(get_square(z)) ))
	needs.length == 1 && set(needs[0],z,'hvsq')

reset_possibles = ->
	for z in get_zeros(grid)
		nonzs = get_nonzeros(get_square(z))
		alreadyHas = nonzs.concat(get_nonzeros(get_horizontal(z))).concat(get_nonzeros(get_vertical(z)))
		z.possibles = (n for n in get_needs(nonzs) when not has(n,alreadyHas))
		return 1 if z.possibles.length is 0

solve_w_possibles = ->
	for sq in get_squares()
		zs = get_zeros(sq)
		needs = get_needs(get_nonzeros(sq))
		for need in needs
			z_needs = (z for z in zs when has(need,z.possibles))
			continue if z_needs.length is 1 and set(need,z_needs[0],'swp1')
			for z in zs when not has(need,get_horizontal(z))
				other_vs = get_vertical(z)
				continue if has(need,other_vs)
				other_v_zs = get_zeros(other_vs)
				has_other = other_v_zs.length > 0
				next_z = 0
				for vz in other_v_zs when ((next_z == 0) and (vz.idx isnt z.idx) and has(need,vz.possibles))
					next_z = 1
				return 1 if (not (next_z == 1 || ! has_other)) and set(need,z,'swp2')

solve_w_testing = ->
	for sq in get_squares()
		zs = get_zeros(sq)
		continue unless zs? and zs[0]?
		for n in get_needs(get_nonzeros(sq))
			start_test()
			solve_loop() if set(n,zs[0],'swt')
			solved_it = is_solved()
			reset_test() unless solved_it
			return 1 if solved_it

solve_loop = ->
	while not is_solved()
		continue if solve_1_missing()
		return if reset_possibles()
		continue if solve_w_possibles()
		solve_w_testing()
		return

