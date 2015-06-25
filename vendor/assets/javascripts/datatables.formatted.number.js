jQuery.fn.dataTableExt.oSort['formatted-num-asc'] = function(x, y) {
	  x = x.replace(/[^\d\-\.\/]/g, '');
    y = y.replace(/[^\d\-\.\/]/g, '');
    if (x.indexOf('/') >= 0) x = eval(x);
    if (y.indexOf('/') >= 0) y = eval(y);
    return x / 1 - y / 1;
}

jQuery.fn.dataTableExt.oSort['formatted-num-desc'] = function(x, y) {
    x = x.replace(/[^\d\-\.\/]/g, '');
    y = y.replace(/[^\d\-\.\/]/g, '');
    if (x.indexOf('/') >= 0) x = eval(x);
    if (y.indexOf('/') >= 0) y = eval(y);
    return y / 1 - x / 1;
}

jQuery.fn.dataTableExt.oSort['html-formatted-num-asc'] = function(x, y) {
	  x = x.replace( /<[^>]*>?/g, "" );
	  y = y.replace( /<[^>]*>?/g, "" );
	  x = x.replace(/[^\d\-\.\/]/g, '');
    y = y.replace(/[^\d\-\.\/]/g, '');
    if (x.indexOf('/') >= 0) x = eval(x);
    if (y.indexOf('/') >= 0) y = eval(y);
    return x / 1 - y / 1;
}

jQuery.fn.dataTableExt.oSort['html-formatted-num-desc'] = function(x, y) {
    x = x.replace( /<[^>]*>?/g, "" );
    y = y.replace( /<[^>]*>?/g, "" );
    x = x.replace(/[^\d\-\.\/]/g, '');
    y = y.replace(/[^\d\-\.\/]/g, '');
    if (x.indexOf('/') >= 0) x = eval(x);
    if (y.indexOf('/') >= 0) y = eval(y);
    return y / 1 - x / 1;
}

jQuery.fn.dataTableExt.oSort['percent-asc']  = function(a,b) {
    var x = (a == "-") ? 0 : a.replace( /%/, "" );
    var y = (b == "-") ? 0 : b.replace( /%/, "" );
    x = parseFloat( x );
    y = parseFloat( y );
    return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

jQuery.fn.dataTableExt.oSort['percent-desc'] = function(a,b) {
    var x = (a == "-") ? 0 : a.replace( /%/, "" );
    var y = (b == "-") ? 0 : b.replace( /%/, "" );
    x = parseFloat( x );
    y = parseFloat( y );
    return ((x < y) ?  1 : ((x > y) ? -1 : 0));
};