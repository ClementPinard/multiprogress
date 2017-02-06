----------------------------------------------------------------------
--
-- Copyright (c) 2011 Clement Farabet (original xlua progress function)
--               2017 Clement Pinard
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
----------------------------------------------------------------------
-- description:
--     xlua widely inspired from xlua's progress function:
--     this package extends the progress function and allows you to log
--     info on several lines and multiple progress bars,
--     to keep track of the info you need.
--
----------------------------------------------------------------------

local os = require 'os'
local sys = require 'sys'
local io = require 'io'
local math = require 'math'
local torch = require 'torch'
local xlua = require 'xlua'

multiprogress = {}


----------------------------------------------------------------------
-- progress bars and logs
----------------------------------------------------------------------
do
   local function getTermLength()
      if sys.uname() == 'windows' then return 80 end
      local tputf = io.popen('tput cols', 'r')
      local w = tonumber(tputf:read('*a'))
      local rc = {tputf:close()}
      if rc[3] == 0 then return w
      else return 80 end 
   end

   local barDoneList
   local previousList
   local tm = ''
   local timerList
   local timesList
   local indicesList
   local linesNumber

   function multiprogress.resetProgress()
     barDoneList = {true}
     previousList = {-1}
     timerList = {}
     timesList = {}
     indicesList = {}
     linesNumber = 1
     print('')
   end
   multiprogress.resetProgress()

   local termLength = math.min(getTermLength(), 120)
   function multiprogress.progress(current, goal, index)
      -- defaults:
      index = index or 1
      local barLength = termLength - 34
      local smoothing = 100 
      local maxfps = 10
      if barDoneList[index] == nil then
         --adds empty lines to console to adjust size of print zone
         for i=linesNumber+1, index do
            io.write('\n')
         end
         io.flush()
         barDoneList[index] = true
         previousList[index] = -1
         linesNumber = math.max(linesNumber,index)
      elseif index < linesNumber then
         --put cursor on the right line
         io.write('\27['..linesNumber-index..'A')
         io.flush()
      end
      --get progressBar variables
      local previous = previousList[index]
      local timer = timerList[index]
      local times = timesList[index]
      local indices = indicesList[index]
      local barDone = barDoneList[index]

      -- Compute percentage
      local percent = math.floor(((current) * barLength) / goal)


      -- start new bar
      if (barDone and ((previous == -1) or (percent < previous))) then
         barDone = false
         previous = -1
         tm = ''
         timer = torch.Timer()
         times = {timer:time().real}
         indices = {current}
      else
         io.write('\r')
      end

      --if (percent ~= previous and not barDone) then
      if (not barDone) then
         previous = percent
         -- print bar
         io.write(' [')
         for i=1,barLength do
            if (i < percent) then io.write('=')
            elseif (i == percent) then io.write('>')
            else io.write('.') end
         end
         io.write('] ')
         for i=1,termLength-barLength-4 do io.write(' ') end
         for i=1,termLength-barLength-4 do io.write('\b') end
         -- time stats
         local elapsed = timer:time().real
         local step = (elapsed-times[1]) / (current-indices[1])
         if current==indices[1] then step = 0 end
         local remaining = math.max(0,(goal - current)*step)
         table.insert(indices, current)
         table.insert(times, elapsed)
         if #indices > smoothing then
            indices = table.splice(indices)
            times = table.splice(times)
         end
         -- Print remaining time when running or total time when done.
         if (percent < barLength) then
            tm = ' ETA: ' .. xlua.formatTime(remaining)
         else
            tm = ' Tot: ' .. xlua.formatTime(elapsed)
         end
         tm = tm .. ' | Step: ' .. xlua.formatTime(step)
         io.write(tm)
         -- go back to center of bar, and print progress
         for i=1,5+#tm+barLength/2 do io.write('\b') end
         io.write(' ', current, '/', goal, ' ')
         -- reset for next bar
         if (percent == barLength) then
            barDone = true
            if linesNumber == 1 then
               multiprogress.resetProgress()
            end
         end
         -- flush
         io.write('\r')
         io.write('\27['..linesNumber..'B')
         io.flush()
      end

      --copy back variables in state tables
      previousList[index] = previous
      timerList[index] = timer
      timesList[index] = times
      indicesList[index] = indices
      barDoneList[index] = barDone
   end

   function multiprogress.info(msg,index)
      if index > linesNumber then
         for i=linesNumber+1, index do
            io.write('\n')
         end
         linesNumber = index
      elseif index < linesNumber then
         --put cursor on the right line
         io.write('\27['..linesNumber-index..'A')
      end
      io.flush()
      if barDoneList[index] ~= nil then
         --erase progress bar to avoid overlapping strings
         io.write('\27[K')
         io.flush()
      end
      io.write(' ')
      io.write(msg:sub(1,termLength)) --avoid info to take more than one line
      io.write('\r')
      io.write('\27['..linesNumber..'B')
      io.flush()
   end
   
   function multiprogress.erase(index)
     barDoneList[index] = true
     previousList[index] = -1
     multiprogress.info('\27[K',index)
   end
   
end

return multiprogress
