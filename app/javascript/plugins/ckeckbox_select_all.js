$('[data-behaviour="select-all"][value=0]').on('change', function () {
  var checked = this.checked;
  $('[data-behaviour="select-all"]').each(function () {
    $(this).prop('checked', checked);
  });
})
