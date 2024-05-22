
const CSS_CLASSES =  {
   HIGHLIGHT: 'highlight'
}
function toggleHighlight(targetId, highlight) {
   let targetElement = document.getElementById(targetId);
   if (targetElement) {
      targetElement.classList.toggle(CSS_CLASSES.HIGHLIGHT);
   }
}