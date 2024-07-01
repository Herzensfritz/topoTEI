function toggleShow(button, targetId){
    const target = document.getElementById(targetId);
    target.classList.toggle('off')
    button.innerText = (target.classList.contains('off')) ? '-' : '+';
    
}

function deleteFile(selectName){
    let select = document.getElementById(selectName);
    if (select){
       let currentFile = select.options[select.selectedIndex].text;
       let dialogText = 'Datei "' + currentFile + '" und alle Versionen davon wirklich löschen?'   
       if (confirm(dialogText) == true){
         location.href = '/exist/restxq/delete?file=' + currentFile; 
       }
    }
}
function enableVersionButton(file, versionButtonId){
    let versionButton = document.getElementById(versionButtonId);
    let fileInput = document.getElementById(file);
    if (versionButton && fileInput){
        if (fileInput.value == 'true'){
            versionButton.removeAttribute('disabled');    
        } else {
            versionButton.setAttribute('disabled', 'true');    
        }    
    }
}
function exportFile(selectName){
    let select = document.getElementById(selectName);
    let link = document.getElementById(DOWNLOAD_LINK);
    if (select && link){
       let currentFile = select.options[select.selectedIndex].text;
       link.setAttribute('download', currentFile);
       let newHref = link.href.substring(0, link.href.indexOf('?')) + "?file=" + currentFile;
       link.setAttribute('href', newHref)
       console.log(link);
        link.click();    
    }
}
function sendToTP(selectName){
    let select = document.getElementById(selectName);
    let link = document.getElementById(DOWNLOAD_LINK);
    if (select){
       let currentFile = select.options[select.selectedIndex].text;
        location.href = '/exist/restxq/export2TP?file=' + currentFile; 
    }
}
function exportFileTP(selectName, button){
    let select = document.getElementById(selectName);
    if (select){
        let currentFile = select.options[select.selectedIndex].text;
        let newLocation = '/exist/restxq/export4TP?file=' + currentFile
        button.setAttribute('disabled', true)
        let promiseA = new Promise((resolve, reject) => {
            resolve(location.href = newLocation);
        });
        promiseA.then(() => button.removeAttribute('disabled'));
    }
}
function exportManuscript(button){
    button.setAttribute('disabled', true)
    let promiseA = new Promise((resolve, reject) => {
        resolve(location.href = '/exist/restxq/manuscript');
    });
    promiseA.then(() => button.removeAttribute('disabled'));
}
function updateOrderBy(checkbox){
    location.href = (location.search) ? location.href.substring(0, location.href.indexOf('?')) + '?newest=' + String(checkbox.checked) : location.href + '?newest=' + String(checkbox.checked);
}

window.onload = function() {
    if(window.location.hash == '#reload') {
        console.log('reloading .........')
        history.replaceState(null, null, ' ');
        window.location.reload(true);
    }
    let newest = document.getElementById(NEWEST);
    if (newest){
        let checkNewest = (location.search && location.search.includes('newest=')) ? location.search.includes('newest=true') : false;  
        //newest.style.setProperty('checked', String(checkNewest));
        if (checkNewest) {
            newest.setAttribute('checked', 'true');
        } else {
            newest.removeAttribute('checked');    
        }
        console.log('checked', String(checkNewest));
      }
} 