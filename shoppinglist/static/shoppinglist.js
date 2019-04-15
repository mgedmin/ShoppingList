// DOM manipulations and data "model"
var all_items = function() {
    return $("#list > li");
}
var emojify = function(node) {
    return node.html(
        node.html().replace(emoji_re, '<span class="e">$&<' + '/span>')
    );
}
var add_item = function(title, checked, id) {
    var new_li = $("<li>");
    if (checked) new_li.addClass('checked')
    new_li.append(emojify($('<a class="item">').text(title)));
    new_li.append($('<a class="delete">'));
    new_li.append($('<input type="hidden">').val(id));
    $("#list").append(new_li).listview('refresh');
    return new_li;
};
var item_of = function(dom_node) {
    return $(dom_node).closest("li");
};
var item_id_callbacks = function(li) {
    var dom_node = li[0];
    return dom_node._item_id_callbacks || [];
}
var add_item_id_callback = function(li, callback) {
    var dom_node = li[0];
    var callbacks = dom_node._item_id_callbacks || [];
    callbacks.push(callback);
    dom_node._item_id_callbacks = callbacks;
}
var set_item_id = function(li, id) {
    li.find('input').val(id);
    if (id) {
        var dom_node = li[0];
        var callbacks = dom_node._item_id_callbacks || [];
        dom_node._item_id_callbacks = [];
        $.each(callbacks, function(idx, callback) {
            callback.apply();
        });
    }
};
var get_item_id = function(li) {
    return li.find('input').val();
};
var is_checked = function(li) {
    return li.hasClass("checked");
};
var toggle_checked = function(li) {
    li.toggleClass("checked");
};
var item_title = function(li) {
    return li.find("a.item").text();
};
var quoted_item_title = function(li) {
    return '"' + item_title(li) + '"';
};
var close_menu = function() {
    $("#menu").popup("close");
};

// AJAX communications
var api_root = null;

var init_api = function(root_url) {
    api_root = root_url;
}

var api_call = function(method, path, settings) {
    if (path.search(/{id}/) != -1) {
        var item_id = get_item_id(settings.li);
        if (!item_id) {
            // item_id may not be set if we've just added an item
            // and hadn't heard from the AJAX callback yet
            add_item_id_callback(settings.li, function() {
                api_call(method, path, settings);
            });
            return;
        }
        path = path.replace('{id}', item_id);
    }
    // XXX PUT and DELETE not supported by all browsers, say the docs
    ajax_settings = {type: method};
    if ((settings || {}).data) ajax_settings.data = settings.data;
    if ((settings || {}).success) ajax_settings.success = settings.success;
    // XXX: handle failures!
    $.ajax(api_root + path, ajax_settings);
}

// User interface
var undoStack = [];
$("#list").on("tap", "a.item", function (e) {
    e.preventDefault();
    var li = item_of(this);
    toggle_checked(li);
    api_call(is_checked(li) ? 'POST' : 'DELETE',
             '/api/items/{id}/checked',
             {li: li});
    var what = (is_checked(li) ? "check " : "uncheck ") + quoted_item_title(li)
    undoStack.push([what, function() { 
        toggle_checked(li);
        api_call(is_checked(li) ? 'POST' : 'DELETE',
                 '/api/items/{id}/checked',
                 {li: li});
    }]);
});
$("#list").on("tap", "a.delete", function (e) {
    e.preventDefault();
    var li = item_of(this);
    var previous = li.prev();
    li.detach();
    api_call('DELETE', '/api/items/{id}', {li: li});
    var what = "delete " + quoted_item_title(li);
    undoStack.push([what, function() { 
        set_item_id(li, null);
        if (previous.length > 0) {
            li.insertAfter(previous);
        } else {
            li.prependTo("#list");
        }
        api_call('POST', '/api/items', {
            data: {title: item_title(li), checked: is_checked(li)},
            success: function(data) {
                set_item_id(li, data.id);
            }
        });
    }]);
});
$("#add-item").click(function (e) {
    e.preventDefault();
    var new_item = $.trim($("#new-item").val());
    $("#new-item").val("");
    if (!new_item) return;
    var new_li = add_item(new_item);
    /* scrollIntoView() tries to make new_li the top-most item,
       and succeeds too well sometimes, when there are very few items
       :( */
    new_li.get(0).scrollIntoView();
    api_call('POST', '/api/items', {
        data: {title: new_item},
        success: function(data) {
            set_item_id(new_li, data.id);
        }
    });
    var what = "add " + quoted_item_title(new_li);
    undoStack.push([what, function() {
        new_li.remove();
        api_call('DELETE', '/api/items/{id}', {li: new_li});
    }]);
});
$("#undo").click(function (e) {
    e.preventDefault();
    if (undoStack.length > 0) {
        var fn = undoStack.pop()[1];
        fn.apply();
        close_menu();
    }
});
$("#sort").click(function(e) {
    e.preventDefault();
    all_items().sort(function(a, b){
        return is_checked($(a)) - is_checked($(b));
    }).appendTo("#list");
    close_menu();
});
$("#clear").click(function (e) {
    e.preventDefault();
    var items = all_items();
    if (items.length == 0) return;
    $("#list").empty();
    var what = "clear list";
    api_call('DELETE', '/api/items');
    undoStack.push([what, function() {
        items.each(function(idx, node) {
            var li = $(node)
            set_item_id(li, null);
            api_call('POST', '/api/items', {
                data: {title: item_title(li), checked: is_checked(li)},
                success: function(data) {
                    set_item_id(li, data.id);
                }
            });
        });
        $("#list").append(items);
    }]);
    close_menu();
});
$("#menu").on("popupbeforeposition", function() {
    if (undoStack.length > 0) {
        var what = undoStack[undoStack.length - 1][0];
        $("#undo").text("Undo " + what).removeClass("disabled");
    } else {
        $("#undo").text("Undo").addClass("disabled");
    }
    if ($("#list > li").length > 0) {
        $("#clear").removeClass("disabled");
    } else {
        $("#clear").addClass("disabled");
    }
});
