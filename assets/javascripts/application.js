//= require_directory ./libraries/
//= require_directory ./plugins/
//= require_self


$(document).ready(function() {
  // Configuration for fancy sortable tables for source file groups
  $('.file_list').dataTable({
    "aaSorting": [[ 1, "asc" ]],
    "bPaginate": false,
    "bJQueryUI": true,
    "aoColumns": [
      null,
      { "sType": "percent" },
      null,
      null,
      null,
      null,
      null
    ]
  });
 }
);
