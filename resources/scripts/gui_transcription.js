const CSS_IDS = {
   TRANSKRIPTION: 'transkription',
   INSERTBY: 'insertedBy-',
   MESSAGE: 'message'
}
const CSS_CLASSES =  {
   ABOVE: 'above',
   BELOW: 'below',
   CENTERLEFT: 'centerLeft',
   FLUSHRIGHT: 'flushRight',
   HIGHLIGHT: 'highlight',
   INSERTION: 'insertion-',
   LINE: 'line', 
   MARKABOVE: 'insert-mark-above',
   MARKBELOW: 'insert-mark-below',
   MARK: 'insert-mark'
}
function toggleHighlight(targetId, highlight) {
   let targetElement = document.getElementById(targetId);
   if (targetElement) {
      targetElement.classList.toggle(CSS_CLASSES.HIGHLIGHT);
   }
}
function updatePositions() {
      var transkription = document.getElementById(CSS_IDS.TRANSKRIPTION);
      fixCenterLeftClassMembers(transkription);
      processLines();
}
function fixCenterLeftClassMembers(transkription) {
   var centerLefts = Array.from(document.getElementsByClassName(CSS_CLASSES.CENTERLEFT));
   centerLefts.forEach(centerLeft =>{
      if (centerLeft.getBoundingClientRect().left < transkription.offsetLeft) {
         centerLeft.classList.remove(CSS_CLASSES.CENTERLEFT);
      }
   });
}
function processLines() {
   var lines = Array.from(document.getElementsByClassName(CSS_CLASSES.LINE));
   var prevLine = null;
   for (var i = 0; i < lines.length; i++){
      if (prevLine) {
         var lowestPrevLine = getOuterValueFromChildren(prevLine, false, prevLine.getBoundingClientRect().bottom);
         var highest = getOuterValueFromChildren(lines[i], true, lines[i].getBoundingClientRect().top);
         if (lowestPrevLine > highest) {
            incrementPadding(prevLine, lowestPrevLine-highest, false); 
         }
      }
      prevLine = lines[i];
   }
}
function fixPositions(line, positionName) {
   let innerLineChildren = getInnerLineChildren(line, positionName);  
   if (innerLineChildren.length > 2) {
      for (var i = 1; i < innerLineChildren.length; i++){
         let element = innerLineChildren[i];
         let bounding = element.getBoundingClientRect();
         element.newOverlaps = innerLineChildren.filter(elem => elem != element).filter(
            elem => (!elem.newOverlaps || !elem.newOverlaps.includes(element))
         &&((elem.getBoundingClientRect().top >= bounding.top && elem.getBoundingClientRect().top <= bounding.bottom)
            || (elem.getBoundingClientRect().bottom >= bounding.top && elem.getBoundingClientRect().bottom <= bounding.bottom))
         && ((elem.getBoundingClientRect().left >= bounding.left && elem.getBoundingClientRect().left <= bounding.right)
            || (elem.getBoundingClientRect().right >= bounding.left && elem.getBoundingClientRect().right <= bounding.right))
         );
      }
      let sortedElements = innerLineChildren.filter(elem =>elem.newOverlaps && elem.newOverlaps.length > 0).sort((a, b) =>a.newOverlaps.length < b.newOverlaps.length)
      sortedElements.forEach(element =>{
         if (element.newOverlaps.length > 1){
            fixPosition(element, positionName == CSS_CLASSES.ABOVE);
         } else {
            fixPosition(element.newOverlaps[0], positionName == CSS_CLASSES.ABOVE);
         }
      });
      console.log(line, sortedElements)
   }
}
function fixPosition(element, isTop) {
    var newTop = (isTop) ? element.getBoundingClientRect().top - element.getBoundingClientRect().height 
      : element.getBoundingClientRect().top + element.getBoundingClientRect().height;
    element.style.top = newTop + 'px';
}

function getInnerLineChildren(element, positionName) {
   let innerLineChildren = []; 
   Array.from(element.children).forEach(child =>{
      if (child.className.includes(CSS_CLASSES.INSERTION + positionName) && child.children.length > 0){
         innerLineChildren.push(child.children[0]);
      } else {
         innerLineChildren = innerLineChildren.concat(getInnerLineChildren(child, positionName));
      }
   });
   return innerLineChildren;
}
function getOuterValueFromChildren(element, isUp, value) {
   if (element.children.length == 0) {
      return getValue(element, isUp, value); 
   }
   var outest = value;
   for (var i = 0; i < element.children.length; i++){
      var childValue = getOuterValueFromChildren(element.children[i], isUp, outest);
      if ((isUp && childValue > 0 && childValue < outest) || (!isUp && childValue > outest)) {
         outest = childValue;
      } 
   }
   return outest;
}
function getValue(element, isUp, value) {
   if (isUp) {
      return (element.getBoundingClientRect().top < value) ? element.getBoundingClientRect().top : value;
   }
   return (element.getBoundingClientRect().bottom > value) ? element.getBoundingClientRect().bottom : value;
}
function updatePosition(className, transkription) {
   var targetElements = Array.from(document.getElementsByClassName(className));
   console.log(targetElements);
}
function updateLine(element, offsetHeight, isTop) {
   if (element.parentElement && element.parentElement.className.includes('line')){
      console.log(element.parentElement.firstChild.firstChild, element);
   }
   if (element.parentElement) {
         if ( !element.parentElement.className.includes('line')){
            updateLine(element.parentElement, offsetHeight, isTop);
         } else {
             incrementPadding(element.parentElement, offsetHeight, isTop);
         }

      }
}
function incrementPadding(element, offsetHeight, isTop) {
   var padding = (isTop) ? 'padding-top' : 'padding-bottom';
   if (!element.style[padding]) {
      element.style[padding] = offsetHeight + 'px';
   } 
   /*else {
      var newPadding = Number(element.style[padding].replace('px', '')) + offsetHeight;
      element.style[padding] = newPadding + 'px';
   }*/
}
function doPreviousElementsOverlap(elements, currentIndex) {
   if (currentIndex == 0) {
      return false;
   } 
   var resultArray = ((Array.from(elements)).slice(0, currentIndex)).filter( element =>
      element.getBoundingClientRect().top == elements[currentIndex].getBoundingClientRect().top
      && element.getBoundingClientRect().right > elements[currentIndex].getBoundingClientRect().left
   );
   return resultArray.length > 0;
}
