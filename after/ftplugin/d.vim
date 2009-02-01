
" {{{ Header

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

let s:ImportPattern = '^\(static\s\+\)\?import'
" }}}

" {{{ s:AddImport
function! s:AddImport(import)
	call cursor(line('$'), 1)
	let ImportLine = search(s:ImportPattern, "b")
	if ImportLine == 0
		let ImportLine = search('module', "b")
	endif
	if ImportLine == 0
		let ImportLine = 1
	endif

	call append(ImportLine, "import " . a:import . ";")
endfunction
" }}}

" {{{ Autoimport
function! s:Autoimport(symbol)
	" Collect data
	let Cursor = [line('.'), col('.')]
	let TagList = taglist(".*")
	let Tags = filter(copy(TagList), 'v:val["name"] == a:symbol')
	let AllModules = filter(TagList, 'v:val["kind"] == "M"')
	let Modules = []
	for ModuleItem in AllModules
		for TagItem in Tags
			if ModuleItem["filename"] == TagItem["filename"]
				call add(Modules, ModuleItem)
			endif
		endfor
	endfor

	" Do nothing if there is no modules with the symbol in tags
	if len(Modules) == 0
		return
	endif

	" If there is more than one ask user which one is correct
	let Lines = ["Select module:"]
	let AddedModules = []
	let i = 1
	for ModuleItem in Modules
		if index(AddedModules, ModuleItem["name"]) != -1
			continue
		endif
		call add(Lines, i . ". " . ModuleItem["name"])
		call add(AddedModules, ModuleItem["name"])
		let i += 1
	endfor
	if len(Lines) == 2
		let Module = 0
	else 
		let Module = inputlist(Lines) - 1
	endif

	" Add import and restore cursor position
	call s:AddImport(Modules[Module]["name"])
	call cursor(Cursor[0] + 1, Cursor[1])
endfunction s:Autoimport
" }}}

" {{{ OrganizeImports
function! s:OrganizeImports()
	" Collect data
	let Cursor = [line('.'), col('.')]
	call cursor (1, 1)
	let ImportLine = search(s:ImportPattern)
	let FirstImport = ImportLine
	let Imports = []
	while ImportLine != 0
		let Line = getline(ImportLine)
		if stridx(Line, "=") == -1
			call add(Imports, {"line": ImportLine, "fullLine": Line, "name": matchlist(Line, '\s*\([a-zA-Z._]*\)\s*[;:]')[1]})
		else
			call add(Imports, {"line": ImportLine, "fullLine": Line, "name": matchlist(Line, '\s*\h*\s*=\s*\([a-zA-Z._]*\)\s*[;:]')[1]})
		endif
		call cursor(ImportLine, 1)
		let ImportLine = search(s:ImportPattern, "W")
	endwhile

	" Return immediately if there are no imports to process
	if len(Imports) == 0
		return
	endif

	" Delete all imports from file
	let i = 0
	for ImportItem in Imports
		call cursor(ImportItem["line"] - i, 1)
		delete
		let i += 1
	endfor

	" Delete extra blank lines
	call cursor(FirstImport, 1)
	while getline(line('.')) =~ '^\s*$'
		delete
	endwhile
	call append(FirstImport - 1, "")
	call append(FirstImport - 1, "")

	" Sort imports alphabetically
	function! Compare(i1, i2) " {{{
		let a = a:i1["name"]
		let b = a:i2["name"]
		if a == b
			return 0
		elseif a < b
			return 1
		else
			return -1
		endif
	endfunction Compare " }}}
	call sort(Imports, "Compare")

	function! GetPackage(module) " {{{
		return matchlist(a:module, '\(\h\+\)\(\.\|$\)')[1]
	endfunction GetPackage " }}}

	" Put imports back eliminating duplicates and delimiting root packages
	let OldImport = ""
	let OldPackage = GetPackage(Imports[0]["name"])
	call cursor(FirstImport, 1)
	for Import in Imports
		" Skip duplicates
		if Import["name"] == OldImport
			continue
		endif
		" Skip a line if root package has changed
		let Package = matchlist(Import["name"], '\(\h\+\)\(\.\|$\)')[1]
		if Package != OldPackage
			call append(line('.'), "")
		endif
		" Put import back
		call append(line('.'), Import["fullLine"])
		" Update state
		let OldImport = Import["name"]
		let OldPackage = Package
	endfor
	delete
	call cursor(Cursor)
endfunction OrganizeImports
" }}}

" {{{ Commands
if !exists(":Autoimport")
	command -nargs=1  Autoimport  :call s:Autoimport(<q-args>)
endif

if !exists(":OrganizeImports")
	command OrganizeImports  :call s:OrganizeImports()
endif
" }}}

" {{{ Default keybindings
if !hasmapto('<Plug>Autoimport')
	map <buffer> <unique> <LocalLeader>i <Plug>Autoimport
endif
noremap <buffer> <unique> <Plug>Autoimport :Autoimport <c-r>=expand("<cword>")<cr><cr>

if !hasmapto('<Plug>OrganizeImports')
	map <buffer> <unique> <LocalLeader>o <Plug>OrganizeImports
endif
noremap <buffer> <unique> <Plug>OrganizeImports :OrganizeImports<cr>
" }}}
