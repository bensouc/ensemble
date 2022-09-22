getUrlHash = function() {
  if (window.location.hash) {
  return window.location.hash.replace('#', '');
}
return false;
}
