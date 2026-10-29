ui.label = class('ui.label', component)

function ui.label:created()
    self.text = ""
    self.fontSize = 32
    self.color = color(255)
    self.align = CENTER|MIDDLE
    self.textRenderer = style.native
    self.shadowOffset = vec2(1, 1)
    self.shadowRadius = 5
end

function ui.label:draw()
    style.fontSize(self.fontSize)
    style.fill(self.color)
    style.textAlign(self.align).textRenderer(self.textRenderer)
    if self.font then style.font(self.font) end
    if self.shadow then
        style.textShadow(self.shadow, self.shadowOffset, self.shadowRadius)
    else
        style.noTextShadow()
    end
    text(self.text, 0, 0, self.entity.size:unpack())
end

ui.image = class('ui.image', component)

ui.image:property
{
    'image', image,
    set = function(self, v)
        self._image = v
        self.entity.sprite = v
    end
}

function ui.image:created(image)
    self.image = image
end

ui.button = class('ui.button', component)

ui.button:property
{
    'style', 'table',
    set = function(self, v)
        self._style = v
        self:updateState()
    end
}

ui.button:property
{
    'selected', 'boolean',
    set = function(self, v)
        self._selected = v
        self:updateState()
    end
}

ui.button:property
{
    'icon', image,
    set = function(self, v)
        self._icon = v
        self:updateState()
    end
}

function ui.button:created()
    self.entity.hitTest = true
    self.pressed = false
        
    local lab = self.entity:child("label")
    lab:anchor(STRETCH, STRETCH)
    lab.size = self.entity.size
    self.label = lab:add(ui.label)
    self.label.text = "PRESS ME!"
    self.label.color = color(64)
    self.label.font = "Helvetica-Bold"

    local img = self.entity:child("image")
    img:anchor(STRETCH, STRETCH)
    img.size = self.entity.size - vec2(8, 8)
    self.iconImage = img:add(ui.image) 

    self.style =
    {
        normal = { sprite = image.read(asset.builtin.UI.Grey_Button_10).slice:patch(10), color = color.white },
        pressed = { sprite = image.read(asset.builtin.UI.Grey_Button_11).slice:patch(10), color = color.white },
        disabled = {color = color(100)},
        selected = {color = color(200)}
    }
end

function ui.button:updateState()
    local style = self.style
    if style then
        local spr = self.pressed and style.pressed.sprite or (self.selected and style.selected.sprite or style.normal.sprite)
        local col = self.pressed and style.pressed.color or (self.selected and style.selected.color or style.normal.color)
        if spr then
            self.entity.sprite = spr
        end
        if col then 
            self.entity.color = col 
        end
    end
    self.iconImage.image = self._icon
end

function ui.button:touched(touch, hit)
    if touch.began then
        self.pressed = true
        self:updateState()
        return true
    elseif touch.moving then
        self.pressed = hit
        self:updateState()
    elseif touch.ended then
        self.pressed = false
        self:updateState()
        if hit then
            self.entity:dispatch('tapped', self)
        end
    end
end

ui.vstack = class('ui.vstack')

function ui.vstack:created()
    self.padding = 10
    self.spacing = 5
end

function ui.vstack:computeSize()
    local e = self.entity
    local pd = self.padding
    local sp = self.spacing

    local size = e.size
    size.y = pd
    
    for i = 1, e.childCount do
        local child = e:childAt(i)
        if child.active then
            size.y = size.y + child.size.y + ((i < e.childCount) and sp or 0)
        end
    end
    size.y = size.y + pd

    e.size = size
end

function ui.vstack:layout()
    local e = self.entity
    local pd = self.padding
    local sp = self.spacing
    local y = -pd
    
    for i = 1, e.childCount do
        local child = e:childAt(i)
        if child.active then
            child.x = 0
            child.y = y
            child.pivot = vec2(0.5, 1)
            child:anchor(STRETCH, TOP)
            local s = child.size
            child.size = vec2(e.size.x - pd * 2, s.y)
            y = y - s.y - ((i < e.childCount) and sp or 0)
        end
    end
    y = y - pd
end

ui.hstack = class('ui.hstack')

function ui.hstack:created()
    self.padding = 10
    self.spacing = 5
end

function ui.hstack:computeSize()
    local e = self.entity
    local pd = self.padding
    local sp = self.spacing

    local size = e.size
    size.x = pd
    
    for i = 1, e.childCount do
        local child = e:childAt(i)
        if child.active then
            size.x = size.x + child.size.x + ((i < e.childCount) and sp or 0)
        end
    end
    size.x = size.x + pd

    e.size = size
end

function ui.hstack:layout()
    local e = self.entity
    local pd = self.padding
    local sp = self.spacing
    local x = pd
    
    for i = 1, e.childCount do
        local child = e:childAt(i)
        if child.active then            
            child.x = x
            child.y = 0
            child.pivot = vec2(0, 0.5)
            child:anchor(LEFT, STRETCH)
            local s = child.size
            child.size = vec2(s.x, e.size.y - pd * 2)
            x = x + s.x + ((i < e.childCount) and sp or 0)
        end
    end
    x = x + pd
end
