width = height = 0
rows = []
columns = []
average =
    rows: []
    columns: []
halfSize = 63
fullSize = halfSize * 2 + 1

rad = (degree) -> degree * Math.PI / 180
cos = (degree) -> Math.cos rad degree
sin = (degree) -> Math.sin rad degree

ring = (min, max) ->
    range = max - min
    (value) ->
        value -= range while value > max
        value += range while value < min
        value
degreeRing = ring 0, 360

CanvasRenderingContext2D.prototype.horizontalLine = (color, x, y) ->
    @fillStyle = color
    @fillRect 0, y, x, 1
CanvasRenderingContext2D.prototype.verticalLine = (color, x, y) ->
    @fillStyle = color
    @fillRect x, 0, 1, y

CanvasRenderingContext2D.prototype.fillPixel = (color, x, y) ->
    @fillStyle = color
    @fillRect x, y, 1, 1
Array.prototype.pluck = (key) ->
    @map (item) -> item[key]
Array.prototype.sum = ->
    @reduce (a, b) ->
        result = {}
        for key of a
            continue if isNaN a[key]
            result[key] = a[key] + b[key]
        result
Array.prototype.average = ->
    sum = @sum()
    for key, value of sum
        sum[key] = value / @length
    sum

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
    
    context
    
window.loadPixels = (data) ->
    bytes = data.data
    width = data.width
    height = data.height
    
    image = prepareCanvas 'image', width, height
    
    sl     = prepareCanvas 'sl',     fullSize, fullSize
    cl_hcl = prepareCanvas 'cl_hcl', fullSize, fullSize
    cl_hsl = prepareCanvas 'cl_hsl', fullSize, fullSize
    hs     = prepareCanvas 'hs',     fullSize, fullSize
    hc_hcl = prepareCanvas 'hc_hcl', fullSize, fullSize
    hc_hsl = prepareCanvas 'hc_hsl', fullSize, fullSize

    hl_hcl = prepareCanvas 'hl_hcl', fullSize, fullSize
    hl_hsl = prepareCanvas 'hl_hsl', fullSize, fullSize

    #average_columns = prepareCanvas 'columns', width, fullSize
    #average_rows    = prepareCanvas 'rows',    fullSize, height
        
    #columns[x] = [] for x in [0...width]
    #rows[y] = [] for y in [0...height]
    animate = (y) -> ->
        for x in [0...width]
            pixel = createPixel x, y
            rows[y][x] = pixel
            columns[x][y] = pixel
            drawPixel pixel
        if y + 1 < height
            requestAnimationFrame animate y + 1
        #else
            #requestAnimationFrame buildStatictics
    
    buildStatictics = ->
        average.rows = rows.map (row) -> row.average()
        average.columns = columns.map (column) -> column.average()
        console.log average.columns
        for row, y in average.rows
            components = []
            #components.push color: 'black', value: fullSize
            components.push color: 'white', value: (row.r + row.g + row.b) * fullSize / 255 / 3
            components.push color: 'red',   value:  row.r * fullSize / 255
            components.push color: 'lime',  value: row.g * fullSize / 255
            components.push color: 'blue',  value: row.b * fullSize / 255
            components.sort (a, b) -> a.value < b.value
            for component in components
                average_rows.horizontalLine component.color, component.value, row.y
        
        for column, x in average.columns
            components = []
            #components.push color: 'black', value: fullSize
            components.push color: 'white', value: (column.r + column.g + column.b) * fullSize / 255 / 3
            components.push color: 'red',   value: column.r * fullSize / 255
            components.push color: 'lime',  value: column.g * fullSize / 255
            components.push color: 'blue',  value: column.b * fullSize / 255
            components.sort (a, b) -> a.value < b.value
            for component in components
                average_columns.verticalLine component.color, column.x, component.value

    requestAnimationFrame animate 0
    
    # pixel knows its location (x, y), hsl, hcl and r, g, b + rgb hex string
    createPixel = (x, y) ->
        pixelPosition = 4 * (x + y * width)
        pixel =
            r: bytes[pixelPosition + 0]
            g: bytes[pixelPosition + 1]
            b: bytes[pixelPosition + 2]
            x: x
            y: y
        pixel.rgb = "rgb(#{pixel.r}, #{pixel.g}, #{pixel.b})"
        
        pixel.hsl = d3.hsl pixel.rgb
        pixel.hcl = d3.hcl pixel.rgb

        # some corrections
        pixel.hcl.l /= 100
        pixel.hcl.h -= 25
        pixel.hcl.c /= 134
        pixel
    
    drawPixel = (pixel) ->
        # m is in range of 0..1, returning 1 on L = 0.5, 0 on L = 0 or 1
        m = 2 * (0.5 - Math.abs(pixel.hsl.l - 0.5))
        hsl_chroma = pixel.hsl.s * m
        
        image.fillPixel pixel.rgb, pixel.x, pixel.y
        
        hsl_l = fullSize * (1 - pixel.hsl.l)
        sl.fillPixel pixel.rgb, pixel.hsl.s * fullSize, hsl_l
        cl_hcl.fillPixel pixel.rgb, pixel.hcl.c * fullSize, fullSize * (1 - pixel.hcl.l)
        cl_hsl.fillPixel pixel.rgb, hsl_chroma * fullSize, hsl_l

        hs.fillPixel pixel.rgb, halfSize * (1 + pixel.hsl.s * sin pixel.hsl.h), halfSize * (1 - pixel.hsl.s * cos pixel.hsl.h)
        
        hc_hcl.fillPixel pixel.rgb, halfSize * (1 + pixel.hcl.c * sin pixel.hcl.h), halfSize * (1 - pixel.hcl.c * cos pixel.hcl.h)
        hc_hsl.fillPixel pixel.rgb, halfSize * (1 + hsl_chroma * sin pixel.hsl.h), halfSize * (1 - hsl_chroma * cos pixel.hsl.h)
        
        hl_hcl.fillPixel pixel.rgb, (degreeRing pixel.hcl.h) * fullSize / 360, fullSize * (1 - pixel.hcl.l)
        hl_hsl.fillPixel pixel.rgb, (degreeRing pixel.hsl.h) * fullSize / 360, fullSize * (1 - pixel.hsl.l)
