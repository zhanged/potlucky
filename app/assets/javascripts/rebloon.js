function reBloon(txt, field, form) {
	var myTxt = txt + ", ";
	var id = field;
	document.getElementById(id).value = myTxt;

    var list = document.getElementsByClassName("alist");
    for (var i = 0; i < list.length; i++) {
        list[i].style.display = 'none';
    }
    var e = document.getElementById(form);
    if(e.style.display == 'none') {
        e.style.display = 'block';
    }

}