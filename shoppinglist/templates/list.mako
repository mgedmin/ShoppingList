<html>
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <title>Shopping List</title>
  <!-- aka "my very first mobile application" -->
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"> 
  <link rel="stylesheet" href="http://code.jquery.com/mobile/1.1.0-rc.1/jquery.mobile-1.1.0-rc.1.min.css" />
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
          -- http://jquerymobile.com/demos/1.0/docs/lists/docs-lists.html */
    .add-item-row {
      margin-top: 15px !important;
      padding-top: 2ex;
    }
    /* Thank you http://stackoverflow.com/questions/8606298/jquery-mobile-display-an-html-form-inline/8608380#8608380
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
  <script src="http://code.jquery.com/jquery-1.7.1.min.js"></script>
  <script src="http://code.jquery.com/mobile/1.1.0-rc.1/jquery.mobile-1.1.0-rc.1.min.js"></script>
  <script type="text/javascript">
    $(function(){
        var undoStack = [];
        $("#list > li a.item").live("tap", function (e) {
            e.preventDefault();
            var li = $(this).closest("li");
            li.toggleClass("checked");
            if (li.hasClass("checked")) {
                var what = "check " + '"' + $(this).text() + '"';
            } else {
                var what = "uncheck " + '"' + $(this).text() + '"';
            }
            undoStack.push([what, function() { li.toggleClass("checked"); }]);
        });
        $("#list > li a.delete").live("tap", function (e) {
            e.preventDefault();
            var what = "delete " + '"' + $(this).prev().text() + '"';
            var li = $(this).closest("li");
            var previous = li.prev();
            li.detach();
            if (previous.length > 0) {
                undoStack.push([what, function() { li.insertAfter(previous); }]);
            } else {
                undoStack.push([what, function() { li.prependTo("#list"); }]);
            }
        });
        var add_item = function(item, checked) {
            var new_li = $("<li>");
            if (checked) new_li.addClass('checked')
            new_li.append($('<a class="item">').text(item));
            new_li.append($('<a class="delete">'));
            $("#list").append(new_li).listview('refresh');
            /* scrollIntoView() tries to make new_li the top-most item,
               and succeeds too well sometimes, when there are very few items
               :( */
            new_li.get(0).scrollIntoView();
            return new_li;
        };
        $("#add-item").click(function (e) {
            e.preventDefault();
            var new_item = $.trim($("#new-item").val());
            $("#new-item").val("");
            if (!new_item) return;
            var new_li = add_item(new_item);
            var what = "add " + '"' + new_item + '"';
            undoStack.push([what, function() { new_li.remove(); }]);
        });
        $("#undo").click(function (e) {
            e.preventDefault();
            if (undoStack.length > 0) {
                var fn = undoStack.pop()[1];
                fn.apply();
                history.back();
            }
        });
        $("#clear").click(function (e) {
            e.preventDefault();
            var items = $("#list > li");
            if (items.length == 0) return;
            $("#list").empty();
            var what = "clear list";
            undoStack.push([what, function() { $("#list").append(items); }]);
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
<%! import json %>
% for item in items:
        add_item(${item.title|json.dumps,n}, ${'true' if item.checked else 'false'});
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
        <li data-icon="false"><a href="#" id="clear">Clear list</a></li>
      </ul>
    </div>
  </div>
</body>
</html>
