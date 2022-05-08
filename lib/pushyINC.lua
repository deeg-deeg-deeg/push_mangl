--
-- Created by IntelliJ IDEA.
-- User: eric
-- Date: 7/15/2020
-- Time: 12:23 PM
-- To change this template use File | Settings | File Templates.
--

-- ------------------------------------------------------------------------------------------
-- this library is by @ericmoderbacher
-- I reduced the code to the bare minimum I needed.
-- check his original library out, it has a lot of interesting stuff!
-- thank you erci for your great work on this!!!
-- ------------------------------------------------------------------------------------------



local midi_out = midi.connect(3)
local midi_in = midi.connect(3)

local lcdLines = {{dirty=true, elementsMoved = false, message={}},{dirty=true, elementsMoved = false, message={}},{dirty=true, elementsMoved = false, message={}},{dirty=true, elementsMoved = false, message={}} }

 texts = {}
lineToBeRefreshed = 1 -- the screen cant be updated all at once so instead of adding logic to wait before sending the next line we will just do it like this
local numberOfCharsPerLine = 68

local PUSH_SCREEN_FRAMERATE = 40

local pushyLib = {}

local function send_sysex(m, d)
  --given to me by zebra on lines
  m:send{0xf0}
  for i,v in ipairs(d) do
    m:send{d[i]}
  end
  m:send{0xf7}
end


local function setupEmptyLine(lineNumber)
  header = {71, 127, 21, (23 + lineNumber), 0, 69, 0}
  for i=1,7,1 do
    lcdLines[lineNumber].message[i]=header[i]
  end
  for i=8,75,1 do
    lcdLines[lineNumber].message[i]=32
  end
end

local function setEmptyScreen()
  print("trying to set screen empty")
  for i=1,4,1 do
    setupEmptyLine(i)
    lcdLines[i].dirty = true
  end
  pushScreenDirty = true
end



function lcdRedraw(line)


  for i,v in ipairs(texts) do
    if (texts[i].line == line and texts[i].dirty) then
      texts[i]:redraw()
      texts[i].dirty = false
    end
  end

  send_sysex(midi_out, lcdLines[line].message)
end



pushyLib.text = {}
pushyLib.text.__index = pushyLib.text

function pushyLib.text.new(x, entry, line, width, height)
  local text = {
    x = x or 0,
    entry = entry or "nil",
    line = line or 0,
    width = width or 17,
    height = height or 1,
    active = true,
    dirty = true
  }
  lcdLines[line].dirty = true
  setmetatable(pushyLib.text, {__index = UI})
  setmetatable(text, pushyLib.text)
  return text
end


function pushyLib.text:redraw()

  local pos = 1
  local charVal
  for i=(7 + self.x),(6 + self.x + self.width),1 do
    if pos <= string.len(self.entry) then
      charVal = string.byte(self.entry, pos)

    else
      charVal = 32
    end

    if charVal > 127 then charval = 1 end

    lcdLines[self.line].message[i]= charVal
    pos = pos + 1
  end
  self.dirty = false
end



function pushyLib.init()

  -- Metro to call redraw()
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if lcdLines[lineToBeRefreshed].dirty then
      lcdLines[lineToBeRefreshed].dirty = false
      lcdRedraw(lineToBeRefreshed)
    end
    lineToBeRefreshed = lineToBeRefreshed + 1
    if lineToBeRefreshed > 4 then lineToBeRefreshed = 1 end
  end
  screen_refresh_metro:start(1 / PUSH_SCREEN_FRAMERATE)
  setEmptyScreen()
end


return pushyLib
