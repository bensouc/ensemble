// Export getUrlHash as a global function for backward compatibility
window.getUrlHash = function() {
  if (window.location.hash) {
    return window.location.hash.replace('#', '');
  }
  return false;
}

export default window.getUrlHash;
