readAndShow = (f, cb) ->
    reader = new FileReader()
    reader.onload = (e) -> cb e.target.result
    reader.readAsDataURL f

handleFileSelect = (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    files = evt.dataTransfer.files

    f = files[0]
    readAndShow f, (dataUrl) ->
        dataUrlToImageData dataUrl, loadPixels
    
handleDragOver = (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = "copy" # Explicitly show this is a copy.

# Setup the dnd listeners.
dropZone = document.body
dropZone.addEventListener "dragover", handleDragOver, false
dropZone.addEventListener "drop", handleFileSelect, false
