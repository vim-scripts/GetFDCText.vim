" GetFDCText.vim: Returns a String, to be displayed for a closed fold.
" Author: Lars Wilke <lw@root-home-bla-stuff.de>
" Last Change: 2004-12-05 19:02:19 +0100 (CET)
" Requires: at least Vim 6.0, +folding support
" Version: 0.1.0
" Script Id:
" Licence: The same vim uses.
" Acknowledgements:
" 
" Download From:
" 
" Description:
"  Tries to find a meaningful text that should be displayed in the
"  folded column. If something is meaningful is decided by a regular
"  expression provided by the user.
"  It does *not* decide when and how a fold is made, nor what is 
"  to be folded away.
"
" Usage:
"  Drop this script in your plugin directory and set the
"  following variables in your .vimrc or _vimrc as appropriate.
"  The values shown here are the default values.
"
" Lines which contain no usefull text to display in the folded column.
" The search starts at the beginning of the line.
" Default is to skip lines which are empty or contain only 
" //,/*,*,*/,(),{},[] and white spaces and tabs. 
" 
" let g:GFDCT_ign_pat = '^[ \t]*$\|\(\/\/\|/[*]+\|[*]+\|[*]+/\)[ \t]*$\|^[ \t]*[\[\](){}][ \t]*$'
"  
" The next two variables are used to set the start and end line
" number for our search. They also modify the begin and end of the 
" region we search depending on the direction we use.
"
"           |  down                      |  up
" -----------------------------------------------------------------  
" start_off |  lnr - start_off           |  lnr is untouched
"           |  v:foldstart - start_off   |  v:foldstart - start_off
" -----------------------------------------------------------------
" end_off   |  lnr is untouched          |  lnr + end_off
"           |  v:foldend + end_off       |  v:foldend + end_off
"  
" (lnr := line number:)
" 
" Please note that you have to provide the point in the region from
" where to start the search. So if you want an upward search _and_
" want to search the whole fold region it makes much sense to use
" v:foldend as the 2nd argument to GetFDCText(). For downward search
" use v:foldstart instead.
" 
" let g:GFDCT_start_off = 0
" let g:GFDCT_end_off = 0
" 
" The text that should be removed from the line to display.
" Means /*,*,*/,//,{{{<0 or 1 digit>,}}}.
" let g:GFDCT_rm_pat = '/\*\|\*\|\*/\|//\|{{{\d\=\|}}}'
" 
" Flags to use for substitute see :s_flags.                 
" let g:GFDCT_rm_flags = 'g'                                       
"
"  Then define 'foldtext' in your vimrc or filetype specific script
"  for example:
"     
"     setlocal foldtext=v:folddashes.GetFDCText(0, v:foldstart)
"     
"  The function takes two arguments the first is the direction,
"  0 for downward, 1 for upward and the second is the line number
"  on which to start the search.
"  
"  Note:
"  * If you call the function with the wrong arguments or with
"    numbers that are impossible i.e. start_off is bigger than the
"    whole buffer or no text could be found the value returned by 
"    foldtext() is used.
"  * The g:GFDCT_* variables are also on a per buffer basis available.
"    For example use let b:GFDCT_ign_pat=<what ever> in you filetype plugin.
"
"  That's all.
"
" Bugs:
"        maybe, do not know
"
" TODO:
" * write help doc
" * maybe make function a command and remove it from the global name
"   space
" * maybe i should parse the commentstring and foldmarker option, 
"   hm this might be usefull to become a separate function, does
"   such a thing exist?
" * searching upward could be decideble by another pattern and or
"   through a caller function for example evaluate v:foldstart

if exists("g:loaded_GetFDCText") && g:loaded_GetFDCText
   finish
elseif &cp  
   finish
elseif v:version < 600
   echomsg 'GetFDCText: You need at least vim 6.0! Aborting.'
   finish
elseif !has("folding")   
   echomsg 'GetFDCText: You have no folding support!? Aborting.'
   finish
endif
let g:loaded_GetFDCText = 1

" Lines which contain no usefull text to display in the folded column.
" The search starts at the beginning of the line.
" Default is to skip lines which are empty or contain only 
" //,/*,*,*/,(),{},[] and white spaces and tabs. 
let s:ign_pat = '^[ \t]*$\|\(\/\/\|\/\*\|\*\|\*\/\)[ \t]*$\|^[ \t]*[\[\](){}][ \t]*$'

" The next two variables are used to set the start and end line
" number for our search. They also modify the begin and end of the 
" region we search depending on the direction we use.
"
"            |  down                      |  up
"  -----------------------------------------------------------------  
"  start_off |  lnr - start_off           |  lnr is untouched
"            |  v:foldstart - start_off   |  v:foldstart - start_off
"  -----------------------------------------------------------------
"  end_off   |  lnr is untouched          |  lnr + end_off
"            |  v:foldend + end_off       |  v:foldend + end_off
"   
"  (lnr := line number:)
"  
"  Please note that you have to provide the point in the region from
"  where to start the search. So if you want an upward search _and_
"  want to search the whole fold region it makes much sense to use
"  v:foldend as the 2nd argument to GetFDCText(). For downward search
"  use v:foldstart instead.
"
let s:start_off = 0
let s:end_off = 0

" The text that should be removed from the line to display
let s:rm_pat = '/\*\|\*\|\*/\|//\|{{{\d\=\|}}}'
" Flags to use for substitute see :s_flags
let s:rm_flags = 'g'

" Get global definitions
let s:ign_pat = exists("g:GFDCT_ign_pat") ? g:GFDCT_ign_pat : s:ign_pat 
let s:start_off = exists("g:GFDCT_start_off") ? g:GFDCT_start_off : s:start_off
let s:end_off = exists("g:GFDCT_end_off") ? g:GFDCT_end_off : s:end_off
let s:rm_pat = exists("g:GFDCT_rm_pat") ? g:GFDCT_rm_pat : s:rm_pat
let s:rm_flags = exists("g:GFDCT_rm_flags") ? g:GFDCT_rm_flags : s:rm_flags

" Searches each line in the fold region (modifiable by the caller) for
" a line that does not match the ign_pat. This line is then filtered 
" through the rm_pat and then returned.
"
" @param lnr -- line number where the search for a text string should start.
" @param direction -- 0 for downward, 1 for upward.
" @return line -- a string usefull for foldtext.
"
function! GetFDCText(direction, lnr)
   " Check input
   if (a:direction == 1)
      let l:direction = 1
   elseif (a:direction == 0)
      let l:direction = 0
   else
      echom 'GetFDCText: Wrong argument: direction has to be 1 or 0'
      return foldtext()
   endif

   " Are we at the end or the beginning of the file
   if (line("$") < a:lnr || line("^") > a:lnr)
      echom 'GetFDCText: Wrong argument: ' . a:lnr . ' - Line number is too high or low.'
      return foldtext()
   endif

   " Get buffer local settings.
   let l:ign_pat = exists("b:GFDCT_ign_pat") ? b:GFDCT_ign_pat : s:ign_pat
   let l:start_off = exists("b:GFDCT_start_off") ? b:GFDCT_start_off : s:start_off
   let l:end_off = exists("b:GFDCT_end_off") ? b:GFDCT_end_off : s:end_off
   let l:rm_pat = exists("b:GFDCT_rm_pat") ? b:GFDCT_rm_pat : s:rm_pat
   let l:rm_flags = exists("b:GFDCT_rm_flags") ? b:GFDCT_rm_flags : s:rm_flags
   
   " Depending of the direction we go, rearrange the start.
   if (l:direction == 0)
      let l:linenr = a:lnr - l:start_off
   else
      let l:linenr = a:lnr + l:end_off
   endif
   
   " Are we over the end or the beginning of the folded region + offset
   if ((v:foldend + l:end_off) < l:linenr)
      return foldtext()
   elseif ((v:foldstart - l:start_off) > l:linenr)
      return foldtext()
   endif
   
   " Text in the current line number
   let l:line = getline(l:linenr)
   
   " The magic part..here we search for a line that does not match
   " the ignore pattern. If we find one we are done.
   let l:ignore_line = match(l:line, l:ign_pat, 0)
   if (l:ignore_line < 0)
      " free line of unwanted symbols
      let l:line = substitute(l:line, l:rm_pat, '', l:rm_flags)
      return l:line
   else
      if (l:direction == 0)
         return GetFDCText(l:direction, l:linenr + 1)
      else
         return GetFDCText(l:direction, l:linenr - 1)
      endif
   endif
endfunction

" EOF
