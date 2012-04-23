
var lastSyncedContent;
var lastSyncedCursor;
var cursors = {};

jQuery.fn.contentsNoCursors = function()
{
	var cont = $(this).contents();
	//console.log(cont);
	var ret = $();
	for( var i = 0; i < cont.length; i++ ){
		var n = cont.eq(i);
		if( n.get().className != 'cursor' )
			ret = ret.add(cont.eq(i));
	}
	
	//console.log(ret);

	return ret;
	//return $(this).contents();
}

function getPath(start_node, decendant)
{
	var pathstr = [];
	while( decendant.parent().length > 0 ){
		if( decendant.get(0) === start_node.get(0) ) break;
		var par = decendant.parent();
		pathstr.push(par.contentsNoCursors().index(decendant));
		decendant = par;
	}
	//console.log(pathstr);
	return pathstr.reverse();
}

function resolvePath(start_node, path)
{
	for( var i = 0; i < path.length; i++ ){
		if( start_node.get(0) instanceof Text )
			break;
		var cont = start_node.contentsNoCursors();
		start_node = cont.eq(path[i]);
	}
	return start_node.get(0);
}

function updateRemoteCursors()
{
	$('#cursors').empty();
	for( c in cursors ){
		$('#cursors').append("<div class=\"cursor\" id=\"cursor-"+c+"\"></div>");
		$('#cursor-'+c).css('left', cursors[c].left);
		$('#cursor-'+c).css('top', cursors[c].top);
	}
}

function onServerMessageReceived(json)
{
	var log;
	var commands;
	try {
	 	commands = JSON.parse(json);
	} catch(e) {

		console.log("invalid json", json);
		return;
	}
	var edit = $('#edit');
	var cur = getCursorPos();

	if( commands.applyPatch ){
		if( cur ) {
			var curstartpath = getPath(edit, $(cur.startContainer));
			var curendpath = getPath(edit, $(cur.endContainer));
		}
		var dmp = new diff_match_patch();
		var newcont = edit.html();
		//console.log(newcont);
		newcont = dmp.patch_apply(dmp.patch_fromText(commands.applyPatch), newcont);
		newcont = newcont[0];
		edit.html(newcont);
		if( cur ) {
			cur.endContainer = resolvePath(edit, curendpath);
			cur.startContainer = resolvePath(edit, curendpath);
			console.log("cur", cur);
			setCursorPos(cur);

		}
	}

	if( commands.updateCursor && cur ){
		var curid = commands.updateCursor.id;
		var curpath = commands.updateCursor.path;
		var curstartpath = getPath(edit, $(cur.startContainer));
		var curendpath = getPath(edit, $(cur.endContainer));
		
		//
		// Mirror the current cursor
		//
		var dst = edit;
		var oldContents = edit.html();
		
		var log = "";
		log += "START "+dst.get(0).tagName+"\n";
		for( var i = 0; i < curpath.length; i++ ){
			if( dst.get(0) instanceof Text )
				break;
			log += "GO TO "+dst.get(0).tagName+"["+curpath[i]+"]\n";
			var cont = dst.contentsNoCursors();
			dst = cont.eq(curpath[i]);
			log += " -> "+dst.get(0)+"\n";
		}
		var idx = curpath[curpath.length-1];
		
		var cursorText = "<div id=\"cursor-dummy\" class=\"cursor\"></div>";
		
		var handled = false;
		if( dst.get(0).tagName == "BR" ){
			var siblings = dst.parent().contentsNoCursors();
			var pred = siblings.eq(siblings.index(dst)-1);
			if( pred.get(0) instanceof Text ){
				dst = dst.before();
			} else {
				log += "PRED: "+pred.get(0) + "\n";
				dst.before(cursorText);
				handled = true;
			}
		}
		if( !handled ){
			if( dst.get(0) instanceof Text ){
				var oldText = dst.text().trim();
				var newText = oldText.substr(0, idx) + cursorText + oldText.substr(idx);
				dst.replaceWith(newText);
			} else {
				dst.before(cursorText);
			}
		}
		
		cursors[curid] = $('#cursor-dummy').offset();

		edit.html(oldContents);
		cur.startContainer = resolvePath(edit, curstartpath);
		cur.endContainer = resolvePath(edit, curendpath);
		setCursorPos(cur);
	}

	updateRemoteCursors();
}

function checkForChanges()
{
	var cursorChanged = false;

	//
	// Compute current cursor position
	//
	var sel = getCursorPos();
	var pathstr;
	if( sel ) {
		var path = $(sel.startContainer);
	
		pathstr = [sel.startOffset];
		while( path.parent().length > 0 ){
			var par = path.parent();
			if( par.find("#edit").length ) break;
			pathstr.push(par.contentsNoCursors().index(path));
			path = par;
		}
		pathstr = pathstr.reverse();
	
		if( ""+pathstr != ""+lastSyncedCursor ){
			cursorChanged = true;
			lastSyncedCursor = pathstr;
		}
			
		var log = "";
		log += "SEL: " + sel.startContainer + " " + sel.startOffset + "\n";
		log += pathstr + "\n";
	}
	
	//
	// Diff the new contents with the old contents and create a patch
	//
	var newContent = $('#edit').html();
	var dmp = new diff_match_patch();
	var diff = dmp.diff_main(lastSyncedContent, newContent);
	var patch = dmp.patch_toText(dmp.patch_make(diff));
	lastSyncedContent = newContent;
	log += "DIFF: " + patch + "\n";
	


	var obj = {};
	if( cursorChanged ) obj.updateCursor = {id: "c1", path: pathstr};
	if( diff.length > 1 ) obj.applyPatch = patch;
	
	//
	// Send changes to server
	//
	if( diff.length > 1 || cursorChanged ){
		var json = JSON.stringify(obj);
		socket.send(json);
	}
			
	
	//$('#log').text(log);
}


function setupEditor()
{
	lastSyncedContent = $('#edit').html();
	$('#test').html($('#edit').html());

	var edit = $('#edit');
	edit.keyup(checkForChanges);
	edit.click(checkForChanges);
	edit.dblclick(checkForChanges);
	edit.scroll(updateRemoteCursors);
}

function getCursorPos()
{
	var range;
	if( window.getSelection ){
		var selObj = window.getSelection();
		if( selObj.rangeCount == 0 ) return null;
		range = selObj.getRangeAt(0);
	} else if( document.selection ){
		range = document.selection.createRange();
	}
	return {
		startContainer: range.startContainer,
		startOffset: range.startOffset,
		endContainer: range.endContainer,
		endOffset: range.endOffset
		};
}

function setCursorPos(cur)
{
	if (window.getSelection) {
		var sel = document.getSelection();
		sel.removeAllRanges();

		var range = document.createRange();
		range.setStart(cur.startContainer, cur.startOffset);
		range.setEnd(cur.endContainer, cur.endOffset);
		//range.collapse(true);
		sel.addRange(range);
	}
	else if (document.selection) {
		var range = document.createRange();
		range.setStart(cur.startContainer, cur.startOffset);
		range.setEnd(cur.endContainer, cur.endOffset);
		document.selection.removeAllRanges();
		document.selection.addRange(range);
	}
}

var socket;

function connect() {
	var href = window.location.href;
	var url = "ws" + href.substring(4) + "/ws";
	socket = new WebSocket(url);
	socket.onopen = function() {
		console.log("socket opened");
	}
	socket.onmessage = function(message) {	
		onServerMessageReceived(message.data);
	}
	socket.onclose = function() {
		console.log("socket closed");
		connect();
	}
	socket.onerror = function() {
		console.log("error");
	}
}
connect();
