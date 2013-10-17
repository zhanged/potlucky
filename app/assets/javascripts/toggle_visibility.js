function toggle_visibility(id) {
    var list = document.getElementsByClassName("alist");
    for (var i = 0; i < list.length; i++) {
        list[i].style.display = 'none';
    }
    var e = document.getElementById(id);
    if(e.style.display == 'none') {
        e.style.display = 'block';
    }
}
