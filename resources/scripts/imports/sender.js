class Sender {
    constructor(file){
        this.file = file;
    }
    send(data){
        if (this.file && data.length > 0) {
            let xhr = new XMLHttpRequest()
            xhr.open('POST', "/exist/restxq/save", true)
            xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
            xhr.send("file=" + file + "&elements=" + JSON.stringify(data));
            xhr.onload = function () {
                undoStack = [];
                location.href = '/exist/restxq/transform?file=' + file
            }
        }
    }
    sendConfig(jsonData, recallFunc){
        let xhr = new XMLHttpRequest()
        xhr.open('POST', "/exist/restxq/config", true)
        xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhr.send('configuration=' + jsonData);
        xhr.onload = function () {
            if(this.status == '205'){
                window.location.reload(true);    
            }
            recallFunc();
        }
    }
}