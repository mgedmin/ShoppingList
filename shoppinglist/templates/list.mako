<!DOCTYPE html>
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <title>Shopping List</title>
  <!-- aka "my very first mobile application" -->
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"> 
  <link rel="stylesheet" href="${request.static_url('shoppinglist:static/jquery.mobile.min.css')}" />
  <style>
    /* Bigger font, indicate clickability on desktop */
    ul#list > li .ui-btn {
      font-size: 24px;
    }
    ul#list > li {
      cursor: pointer;
    }
    ul#list > li .e {
      font-family: emoji, sans-serif;
    }
    /* Checked items; assumes the background is light */
    ul#list > li.checked a:first-child:after {
      content: " ✓";
    }
    ul#list > li.checked a:first-child {
      color: #ccc;
      filter: grayscale(100%);
    }
    /* Disabled menu items -- looks like jQM has no concept of 'menu' */
    #menu > ul {
      min-width: 200px;
    }
    li > a.ui-btn.disabled,
    li > a.ui-btn.disabled:active,
    li > a.ui-btn.disabled:hover {
      color: #ccc;
    }
    /* "Style note on non-inset lists: all standard, non-inset lists have a
        -15px margin to negate the 15px of padding on the content area to make
        lists fill to the edges of the screen. If you add other widgets above
        or below a list, the negative margin may make these elements overlap so
        you'll need to add additional spacing in your custom CSS."
          -- https://jquerymobile.com/demos/1.0/docs/lists/docs-lists.html */
    #main {
      padding-top: 0;
    }
    #list {
      margin-top: 0;
    }
    .add-item-row {
      margin: 0 -1em;
      position: relative;
    }
    .add-item-row .ui-input-text {
      margin-top: 16px;
      margin-right: 60px;
      font-size: 24px;
      border: 0;
      border-radius: 0;
    }
    .add-item-row .ui-input-text input {
      padding: .7em 1em;
      line-height: 1.3;
      border-top: 1px solid #ddd;
      border-bottom: 1px solid #ddd;
      background: white;
    }
    .add-item-row .side-btn {
      position: absolute;
      width: 2.5em;
      height: 100%;
      top: 0px;
      right: 0px;
      padding: 0;
      margin: 0;
      font-size: 24px;
      box-sizing: border-box;
      border-right: 0;
    }
    .add-item-row .side-btn .ui-btn {
      position: absolute;
      top: 50%;
      margin-top: -15px;
      width: 28px;
      left: 50%;
      margin-left: -15px;
      height: 28px;
      background-color: #2ad;
      border-color: #2ad;
      color: #fff;
      text-shadow: 0 1px 0 #08b;
    }
    .ui-listview>li.ui-last-child, .ui-listview>li.ui-last-child>a.ui-btn {
      border-bottom: 0;
    }
  </style>

  <script src="${request.static_url('shoppinglist:static/jquery.min.js')}"></script>
  <script src="${request.static_url('shoppinglist:static/jquery.mobile.min.js')}"></script>
  <script src="${request.static_url('shoppinglist:static/emoji.js')}"></script>
  <script type="text/javascript">
    $(function(){
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
            var new_li = $("<li>").data('id', id);
            if (checked) new_li.addClass('checked')
            new_li.append(emojify($('<a class="item">').text(title)));
            new_li.append($('<a class="delete">'));
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
            li.data('id', id);
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
            return li.data('id');
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
            // this is used purely for presentation so it doesn't matter if
            // item_title() returns a string containing "
            return '"' + item_title(li) + '"';
        };
        var close_menu = function() {
            $("#menu").popup("close");
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
            if (all_items().length > 0) {
                $("#clear").removeClass("disabled");
            } else {
                $("#clear").addClass("disabled");
            }
        });
        $("#list").empty();
% for item in items:
        add_item(${item.title|json,n}, ${'true' if item.checked else 'false'}, ${item.id});
% endfor
    });
  </script>

</head>
<body>
  <div data-role="page">
    <div data-role="header" data-theme="b" id="header">
      <h1>Shopping List</h1>
      <script>
        document.write(
          '<a href="#menu" class="ui-btn-right" data-icon="grid" data-rel="popup" data-position-to="origin">Menu</a>'
        );
      </script>
    </div>
    <div data-role="popup" id="menu" data-theme="a" data-tolerance="44,4,30,15" data-history="false">
      <ul data-role="listview" data-inset="true" data-theme="a">
        <script>
          document.write('<li data-icon="false"><a href="#" id="undo">Undo</a></li>');
          document.write('<li data-icon="false"><a href="#" id="sort">Sort list</a></li>');
          document.write('<li data-icon="false"><a href="#" id="clear">Clear list</a></li>');
        </script>
      </ul>
    </div>
    <div class="ui-content" role="main" id="main">
      <form method="post" action="">
        <ul id="list" data-role="listview" data-theme="d" data-split-theme="d" data-split-icon="delete">
% for item in items:
          <noscript>
            <li>
              <form method="post" action="">
% if item.checked:
                <button type="submit" name="uncheck" value="${item.id}">
                  [X]
                </button>
% else:
                <button type="submit" name="check" value="${item.id}">
                  [ ]
                </button>
% endif
                <a class="item">${item.title}</a>
                <button type="submit" name="remove" value="${item.id}">
                  (remove)
                </button>
              </form>
            </li>
          </noscript>
% endfor
        </ul>
      </form>
      <form class="add-item-row" method="post" action="">
        <input id="new-item" name="add" type="text" autocomplete="off">
        <div id="add-item" class="side-btn ui-btn">
          <input type="submit" data-type="button" data-icon="plus" data-theme="b" value="Add" data-iconpos="notext">
        </div>
      </form>
    </div>
  </div>

</body>
</html>
