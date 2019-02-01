<html>
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <title>Shopping List</title>
  <!-- aka "my very first mobile application" -->
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"> 
  <link rel="stylesheet" href="https://code.jquery.com/mobile/1.1.0-rc.1/jquery.mobile-1.1.0-rc.1.min.css" />
  <style>
    /* Without this rule I see a greyish-red area, then a grey area, then a
       white area at the bottom of the page on my Nokia N9. */
    body, div.ui-page {
      background: #eee;
    }
    /* Bigger font, indicate clickability on desktop */
    ul#list > li {
      font-size: 150%;
      cursor: pointer;
    }
    /* Checked items; assumes the background is light */
    ul#list > li.checked a:first-child:after {
      content: " ✓";
    }
    ul#list > li.checked a:first-child {
      color: #ccc;
    }
    /* Disabled menu items -- looks like jQM has no concept of 'menu' */
    li.ui-btn a.disabled {
      color: #ccc;
    }
    /* "Style note on non-inset lists: all standard, non-inset lists have a
        -15px margin to negate the 15px of padding on the content area to make
        lists fill to the edges of the screen. If you add other widgets above
        or below a list, the negative margin may make these elements overlap so
        you'll need to add additional spacing in your custom CSS."
          -- https://jquerymobile.com/demos/1.0/docs/lists/docs-lists.html */
    .add-item-row {
      margin-top: 15px !important;
      padding-top: 2ex;
    }
    /* Thank you https://stackoverflow.com/questions/8606298/jquery-mobile-display-an-html-form-inline/8608380#8608380
       even though this isn't exactly what I want.  HTML/CSS is hard. */
    .add-item-row .ui-input-text {
      display: inline-block;
      width: 85%;
      vertical-align: middle;
    }
    .add-item-row .ui-btn {
      display: inline-block;
      vertical-align: middle;
      margin-left: 1ex;
    }
  </style>
  <script src="https://code.jquery.com/jquery-1.7.1.min.js"></script>
  <script src="https://code.jquery.com/mobile/1.1.0-rc.1/jquery.mobile-1.1.0-rc.1.min.js"></script>
  <script type="text/javascript">
    $(function(){
        // DOM manipulations and data "model"
        var all_items = function() {
            return $("#list > li");
        }
        var add_item = function(title, checked, id) {
            var new_li = $("<li>");
            if (checked) new_li.addClass('checked')
            new_li.append($('<a class="item">').text(title));
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

        // AJAX communications
        var api_root = ${request.application_url|json,n};
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
        $("#list > li a.item").live("tap", function (e) {
            e.preventDefault();
            var li = item_of(this);
            toggle_checked(li);
            api_call(is_checked(li) ? 'POST' : 'DELETE',
                     '/api/items/{id}/checked',
                     {li: li});
            var what = (is_checked(li) ? "check " : "uncheck") + quoted_item_title(li)
            undoStack.push([what, function() { 
                toggle_checked(li);
                api_call(is_checked(li) ? 'POST' : 'DELETE',
                         '/api/items/{id}/checked',
                         {li: li});
            }]);
        });
        $("#list > li a.delete").live("tap", function (e) {
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
                history.back();
            }
        });
        $("#sort").click(function(e) {
            e.preventDefault();
            all_items().sort(function(a, b){
                return is_checked($(a)) - is_checked($(b));
            }).appendTo("#list");
            history.back();
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
            history.back();
        });
        $(document).delegate("#menu", "pagebeforeshow", function() {
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
% for item in items:
        add_item(${item.title|json,n}, ${'true' if item.checked else 'false'}, ${item.id});
% endfor
    });
  </script>
</head>
<body>
  <div data-role="page" id="main">
    <div data-role="header">
      <h1>Shopping List</h1>
      <a href="#menu" class="ui-btn-right" data-icon="grid" data-rel="dialog" data-transition="none">Menu</a>
    </div>
    <div data-role="content">
      <ul id="list" data-role="listview" data-theme="d" data-split-theme="d" data-split-icon="delete">
      </ul>
      <form class="add-item-row">
        <input id="new-item" type="text">
        <input id="add-item" type="submit" data-type="button" data-icon="plus" data-theme="b" value="Add" data-iconpos="notext" data-inline="true">
        <!-- data-iconpos="notext" is interesting, but removes too much padding -->
      </form>
    </div>
  </div>
  <div data-role="page" id="menu">
    <div data-role="header">
      <h1>Shopping List</h1>
    </div>
    <div data-role="content">
      <ul data-role="listview" data-inset="true">
        <li data-icon="false"><a href="#" id="undo">Undo</a></li>
        <li data-icon="false"><a href="#" id="sort">Sort list</a></li>
        <li data-icon="false"><a href="#" id="clear">Clear list</a></li>
      </ul>
    </div>
  </div>
</body>
</html>
