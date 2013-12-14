function whosInvited(txt, field, form) {
	var myTxt = txt
	var id = field;
    var nop = document.getElementById(id);
    var p = document.createElement('p'),
    myTxt = document.createTextNode(txt);

    p.id = 'whos-invited';
    p.appendChild(myTxt);
    nop.parentNode.replaceChild(p, nop);
}