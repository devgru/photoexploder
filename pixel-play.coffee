rects = []
width = height = 0

window.dataUrlToImageData = (dataUrl, cb) ->
    img = new Image()
    img.src = dataUrl
    img.onload = -> 
        console.log 'image onload'
        canvas = document.createElement 'canvas'
        console.log document.body.clientWidth, img.width
        width = Math.min document.body.clientWidth, img.width
        canvas.width = width
        canvas.height = img.height * width / img.width
        image = canvas.getContext '2d'
        image.drawImage img, 0, 0, canvas.width, canvas.height
        cb image.getImageData 0, 0, canvas.width, canvas.height

prepareCanvas = (id, width, height) ->
    canvas = document.getElementById id
    canvas.width = width
    canvas.height = height
    context = canvas.getContext '2d'
    context.fillPixel = (color, x, y) ->
        context.fillStyle = color
        context.fillRect x, y, 1, 1
    context
    
rad = (degree) -> degree * Math.PI / 180

window.loadPixels = (data) ->
    console.log 'load pixels'
    bytes = data.data
    width = data.width
    height = data.height

        
    image = prepareCanvas 'image', width, height
    
    diagramHalfSize = 127
    diagramFullSize = diagramHalfSize * 2 + 1
    # 128 + 128 + 1, for circle
    
    sl = prepareCanvas 'sl', diagramFullSize, diagramFullSize
    cl = prepareCanvas 'cl', diagramFullSize, diagramFullSize
    hs = prepareCanvas 'hs', diagramFullSize, diagramFullSize
    hc = prepareCanvas 'hc', diagramFullSize, diagramFullSize 
    hl1 = prepareCanvas 'hl1', diagramFullSize, diagramFullSize
    hl2 = prepareCanvas 'hl2', diagramFullSize, diagramFullSize

    animate = (y) -> ->
        for x in [0...width]
            pixel =
                r: bytes[4*(x+y*width)+0]
                g: bytes[4*(x+y*width)+1]
                b: bytes[4*(x+y*width)+2]
                x: x
                y: y
            pixel.rgb = "rgb(#{pixel.r}, #{pixel.g}, #{pixel.b})"

            pixel.hsl = d3.hsl pixel.rgb
            pixel.hcl = d3.hcl pixel.rgb
            pixel.hsl.h -= 90 # red at top point
            pixel.hcl.h -= 25 + 90 # correction

            m = 2 * (0.5 - Math.abs(pixel.hsl.l - 0.5))
            
            console.log 'hcl broken on', pixel if isNaN pixel.hcl.h or isNaN pixel.hcl.c or isNaN pixel.hcl.l
            console.log 'hsl broken on', pixel if isNaN pixel.hsl.h or isNaN pixel.hsl.s or isNaN pixel.hsl.l
            
            image.fillPixel pixel.rgb, x, y
            cl.fillPixel pixel.rgb, 2 * pixel.hcl.c, 2 * pixel.hcl.l
            hsl_chroma = pixel.hsl.s * m
            sl.fillPixel pixel.rgb, hsl_chroma * 255, pixel.hsl.l * 255
            hc.fillPixel pixel.rgb, (diagramHalfSize + pixel.hcl.c * (Math.cos rad pixel.hcl.h)), (diagramHalfSize + pixel.hcl.c * (Math.sin rad pixel.hcl.h))
            hs.fillPixel pixel.rgb, (diagramHalfSize + 100 * hsl_chroma * (Math.cos rad pixel.hsl.h)), (diagramHalfSize + 100 * hsl_chroma * (Math.sin rad pixel.hsl.h))
            hl1.fillPixel pixel.rgb, (diagramHalfSize + pixel.hcl.l * (Math.cos rad pixel.hcl.h)), (diagramHalfSize + pixel.hcl.l * (Math.sin rad pixel.hcl.h))
            hl2.fillPixel pixel.rgb, (diagramHalfSize + 100 * pixel.hsl.l * (Math.cos rad pixel.hsl.h)), (diagramHalfSize + 100 * pixel.hsl.l * (Math.sin rad pixel.hsl.h))
            #rows[y][x] = pixel
            #columns[x][y] = pixel
            #pixels.push pixel
        requestAnimationFrame animate y + 1 if y + 1 < height
    requestAnimationFrame animate 0

