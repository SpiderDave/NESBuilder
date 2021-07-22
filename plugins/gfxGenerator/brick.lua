local generator = {}


function generator.makePalette(brick)
    local palette = {}
    local basecolor
    
    local rng = generator.rng
    local random = rng.random
    
    local scheme = rng.choice('normal', 'normal','normal','normal','ice')
    
    --scheme = 'basic1'
    
    if scheme == 'normal' then
        baseColor = random(0,0x0c)
        
        palette = {0x0f, baseColor, baseColor+0x10, baseColor+0x20}
        
        palette[3] = palette[3] + random(-2,2)
        palette[3] = math.max(0x10, palette[3])
        palette[3] = math.min(0x1c, palette[3])
        
        palette[4] = palette[3] + 0x10
        palette[4] = palette[4] + random(-2,2)
        palette[4] = math.max(0x21, palette[4])
        palette[4] = math.min(0x2c, palette[4])
    elseif scheme == 'basic1' then
        baseColor = random(0,0x0c)
        palette[1] = 0x0f
        palette[2] = baseColor
        palette[3] = baseColor + 0x10
        palette[4] = baseColor + 0x20
    elseif scheme == 'ice' then
        palette[1] = rng.choice(0x02,0x11, 0x12)
        palette[2] = rng.choice(0x21,0x22,0x2c)
        palette[3] = rng.choice(0x31,0x32,0x33,0x3c)
        palette[4] = 0x20
    end
    
    brick.palette = palette
    brick.paletteType = scheme
    return brick
end

function generator.make(opt)
    local brick = {}
    opt = opt or {}
    
    local rng = generator.rng
    local random = rng.random
    brick.type = opt.type or "single"
    brick.width = 16
    brick.height = 16
    
    brick.seed = opt.seed or random(0,1000000)
    
    rng.seed(brick.seed)
    
    -- random choice from arguments
    local choice = rng.choice
    
    -- create new surface
    local surface = NESBuilder:makeNESPixmap(brick.width, brick.height)
    
    -- create new CHR data and load to surface
    local chr = NESBuilder:newCHRData(brick.width, brick.height)
    surface.loadCHR()
    
    brick = generator.makePalette(brick)
    
    brick.innerBrickWidth = choice(4,7,15)
    brick.innerBrickHeight = choice(4,7)
    
    if brick.innerBrickHeight > brick.innerBrickWidth then
        brick.innerBrickWidth = choice(7,15)
    end
    
    brick.innerBrickXOffset = random(2, brick.innerBrickWidth-1)
    brick.leftHighlight1Start = 1
    brick.leftHighlight1Length = random(2, 7)
    brick.leftHighlight2Start = 1
    brick.leftHighlight2Length = 1
    brick.rightShadow1Length = math.max(1, math.floor(brick.leftHighlight1Length *.6))
    brick.rightShadow1Start = brick.width - 1 - brick.rightShadow1Length
    
    brick.smudgeTop = (random(7) == 0)
    brick.smudgeTop = true
    
    local r = random(0,9000)
    local r2 = random(0,9000)
    local r3 = random(0,9000)
    local r4 = random(0,9000)
    local r5 = random(0,9000)
    
    local fixColor = function(c)
        return math.min(3, math.max(0, math.floor(c+.5)))
    end
    local clamp = function(n, min, max)
        return math.min(max, math.max(min, math.floor(c+.5)))
    end
    
    local t = {single=random(10000),left=0,middle=brick.width*1,middle2=brick.width*2,right=brick.width*3}
    local noiseX = t[brick.type] or 0
    
    --local slant1 = random(-4,4)
    
    -- create a function to pass to mapPixels
    local f=function(x, y, c)
        local n, n2
        n = .1
        n2 = 1.1
        local innerX = ((x+noiseX) + (math.floor(y/(brick.innerBrickHeight+1)) * brick.innerBrickXOffset)) % (brick.innerBrickWidth+1)
        
        c = fixColor(NESBuilder:noise(r+(x + noiseX)*n, y*n)*4 * n2)
        c = math.max(1, c)
        
        -- inner brick highlight on left
        if (x + (math.floor(y/(brick.innerBrickHeight+1)) * brick.innerBrickXOffset)) % (brick.innerBrickWidth+1) == 1 then c = 2 end
        
        --if innerX > 1 and innerX < brick.innerBrickWidth+1-1 then
            -- inner brick highlight on top
            if y % (brick.innerBrickHeight+1) == 1 then c = 2 end
        --end
        
        if brick.smudgeTop and (y % (brick.innerBrickHeight+1) == 1) then
            if math.random(100) <= 70 then c = c+1 end
        end
        
        if (brick.type == "left") or (brick.type == "single") then
            if math.random(0,math.floor(x*.3)) == 0 then
                -- highlight on left side of brick
                if x >= brick.leftHighlight1Start and x < brick.leftHighlight1Start + brick.leftHighlight1Length then c = c + 1 end
                -- secondary (brighter) highlight
                if x >= brick.leftHighlight2Start and x < brick.leftHighlight2Start + brick.leftHighlight2Length then c = c + 1 end
            end
            -- truncate left side column
            if x == 0 then c = 0 end
        end
        
        if (brick.type == "right") or (brick.type == "single") then
            -- create shade on right side of brick
            if x >= brick.rightShadow1Start and c > 0 then c = c - 1 end
            
            --if x > brick.rightShadow1Start +(y/brick.height)*slant1 and c > 0 then c = c - 1 end
            
            -- truncate right side column
            if x == brick.width - 1 then c = 0 end
        end
        
--        if y % (brick.innerBrickHeight+1) == brick.innerBrickHeight-1 then
--            if c == 1 and math.random(100) <= 70 then c = 2 end
--        end
--        if y % (brick.innerBrickHeight+1) == brick.innerBrickHeight-2 then
--            if c == 1 and math.random(100) <= 60 then c = 2 end
--        end
        
        -- inner brick gaps
        if (x + (math.floor(y/(brick.innerBrickHeight+1)) * brick.innerBrickXOffset)) % (brick.innerBrickWidth+1) == 0 then c = 0 end
        if y % (brick.innerBrickHeight+1) == 0 then c = 0 end
        
        return c
    end
    
    -- wipe surface
    surface.loadCHR()
    -- apply the function to the surface
    surface.mapPixels(f)
    -- apply palette
    surface.applyPalette(brick.palette)
    
    brick.surface = surface
    
    return brick
end


return generator