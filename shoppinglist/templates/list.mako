<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Shopping List</title>
  <!-- aka "my very first mobile application" -->
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <link rel="stylesheet" href="${request.static_url('shoppinglist:static/jquery.mobile.min.css')}">
  <link rel="stylesheet" href="${request.static_url('shoppinglist:static/shoppinglist.css')}">
</head>
<body>

  <div data-role="page" id="main">
    <div data-role="header" data-theme="b">
      <h1>Shopping List</h1>
      <a href="#menu" class="ui-btn-right" data-icon="grid" data-rel="popup" data-position-to="origin">Menu</a>
    </div>
    <div data-role="popup" id="menu" data-theme="a" data-tolerance="44,4,30,15" data-history="false">
      <ul data-role="listview" data-inset="true" data-theme="a">
        <li data-icon="false"><a href="#" id="undo">Undo</a></li>
        <li data-icon="false"><a href="#" id="sort">Sort list</a></li>
        <li data-icon="false"><a href="#" id="clear">Clear list</a></li>
      </ul>
    </div>
    <div class="ui-content" role="main" id="main">
      <ul id="list" data-role="listview" data-theme="d" data-split-theme="d" data-split-icon="delete">
      </ul>
      <form class="add-item-row">
        <input id="new-item" type="text" autocomplete="off">
        <div id="add-item" class="side-btn ui-btn">
          <input type="submit" data-type="button" data-icon="plus" data-theme="b" value="Add" data-iconpos="notext">
        </div>
      </form>
    </div>
  </div>

  <script src="${request.static_url('shoppinglist:static/jquery.min.js')}"></script>
  <script src="${request.static_url('shoppinglist:static/jquery.mobile.min.js')}"></script>
  <script src="${request.static_url('shoppinglist:static/emoji.js')}"></script>
  <script src="${request.static_url('shoppinglist:static/shoppinglist.js')}"></script>
  <script type="text/javascript">
    $(function(){
        init_api(${request.application_url|json,n});
% for item in items:
        add_item(${item.title|json,n}, ${'true' if item.checked else 'false'}, ${item.id});
% endfor
    });
  </script>

</body>
</html>
