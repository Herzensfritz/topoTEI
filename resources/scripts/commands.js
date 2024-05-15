
var COLLECTION = 'collection';
var DOWNLOAD_LINK = 'downloadLink';
var FILENAME = 'filename';
var VERSIONS = 'versions';

function updateOrderBy(checkbox){
    location.href = (location.search) ? location.href.substring(0, location.href.indexOf('?')) + '?newest=' + String(checkbox.checked) : location.href + '?newest=' + String(checkbox.checked);
}

function revertVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/revertVersion?file=' + currentFile;
    }
}
function showVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/transform?file=' + currentFile;
    }
}
function showPreview () {
   let file = document.getElementById(FILENAME); 
   window.open('/exist/restxq/preview?file=' + file.value, '_blank');
}
function deleteVersion(all){
    if (all){
        let file = document.getElementById(FILENAME);
        let dialogText = 'Alle alten Versionen wirklich löschen?'
        if (file && confirm(dialogText) == true){
            location.href = '/exist/restxq/deleteBak?file=' + file.value;
        }
    } else {
        let form = document.getElementById(VERSIONS);
        if (form && form.elements.file.value){
            let currentFile = 'bak/' + form.elements.file.value;   
            location.href = '/exist/restxq/deleteBak?file=' + currentFile;
        }
    }
}
function showDefaultVersion(defaultFile){
    location.href = '/exist/restxq/transform?file=' + defaultFile;
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
function exportManuscript(button){
    button.setAttribute('disabled', true)
    let promiseA = new Promise((resolve, reject) => {
        resolve(location.href = '/exist/restxq/manuscript');
    });
    promiseA.then(() => button.removeAttribute('disabled'));
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
function downloadFile(button){
    if (!button.getAttribute('disabled')){
       let link = document.getElementById(DOWNLOAD_LINK);
       if (link){
            if(runsOnBakFile){
                let currentFile = link.href.substring(link.href.indexOf('?')).replace('?file=','');   
                let filename = currentFile.substring(0, currentFile.indexOf('.')) + '_' + currentFile.substring(currentFile.indexOf('.')).replace('.xml_','')  + '.xml';
                link.setAttribute('download', filename);
                console.log(currentFile, filename)
                let newHref = link.href.substring(0, link.href.indexOf('?')) + "?file=bak/" + currentFile;
                link.setAttribute('href', newHref)
            }
            link.click();    
        } 
    }
}
function openFile(button){
    if (!button.getAttribute('disabled')){
        let collection = document.getElementById(COLLECTION);
        let file = document.getElementById(FILENAME);
        if (collection && file){
            redoStack = [];
            handleButtons();
            Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
            let filepath = (runsOnBakFile) ? collection.value + '/bak/' + file.value : collection.value + '/' + file.value;
            fileIsOpenedInEditor = true;
            window.open('/exist/apps/eXide/index.html?open=' + filepath, '_blank');
            
           
        }
    }
}

