if v:version < 700
	echohl WarningMsg
	echomsg "omni#d#complete.vim: Please install vim 7.0 or higher for omni-completion"
	echohl None
	finish
endif

if exists ('+omnifunc') && &omnifunc == ""
	setlocal omnifunc=omni#d#complete#Complete
endif

if version < 700
	finish
endif

function omni#d#complete#Complete (findstart, base)
	if a:findstart == 1
		let line = getline ('.')
		let start = col ('.') - 1
		while start > 0 && line[start - 1] =~ '\i'
			let start -= 1
		endwhile
		return start
	else
		let l:Pattern    = '^' . a:base . '.*$'
		let l:Tag_List = taglist (l:Pattern)
		for Tag_Item in l:Tag_List
			if l:Tag_Item['kind'] == 
				let l:Tag_Item['kind'] = 's'
			endif
			let l:Match_Item = {
						\ 'word':  l:Tag_Item['name'],
						\ 'menu':  l:Tag_Item['filename'],
						\ 'info':  "Symbol from file " . l:Tag_Item['filename'] . " line " . l:Tag_Item['cmd'],
						\ 'kind':  l:Tag_Item['kind'],
						\ 'icase': 1}
			if complete_add (l:Match_Item) == 0
				return []
			endif
			if complete_check ()
				return []
			endif
		endfor
		return []
	endif
endfunction omni#d#complete#Complete
finish
