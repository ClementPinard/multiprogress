# Multi levels progress logging extension for torch

![img](https://github.com/ClementPinard/imagenet-multiGPU.torch/raw/master/images/multiprogress.png)

## Dependencies:
Torch7 (www.torch.ch)
xlua

## Install:
```
$ luarocks install xlua
$ luarocks make
```

## Use

This extension allows you to log multiple progress bars and info messages on several lines without
having to reprint everything every time.

`mp.progress(i,length,line)`

lets you log a progress bar xlua style, last argument lets you choose which line you want it to appear in the print zone. If no line argument is given, original `xla.progress` behaviour is applied

`mp.info(msg,line)`

lets you log a message the line you want. message will be truncated to terminal length, in order to fit on one line.
For long messages, you can split your message in 2 lines.

`mp.erase(line)`

erases the line and the progress bar if any. Can be useful if you want to log messages with tabs (which will overlap with previous text)

`mp.resetProgress()`

lets you start from scratch a new print zone. You should print it as soon as you have finished your progress operation, to flush print zone


First example shows you you can log progress bar anywhere you want, not necessarily on last line,
it will make the print zone the right size automatically.

```lua
mp = require 'multiprogress'
require 'sys'

for i =1,10 do
  mp.progress(i,10,3)
  for j=1,10 do
    sys.sleep(0.1)
    mp.progress(j,10,1)
  end
end

mp.resetProgress()
```

Second example shows you how to log dynamic messages above progress bars.

```lua
mp = require 'multiprogress'
require 'sys'

for i =1,10 do
  mp.info('overall progress',5)
  mp.progress(i,10,6)
  for j=1,10 do
    mp.info(i..(i>1 and 'th' or 'st')..' step',3)
    mp.progress(j,10,4)
    for k=1,10 do
      sys.sleep(0.1)
      mp.info(j..(j>1 and 'th' or 'st')..' sub-step',1)
      mp.progress(k,10,2)
    end
  end
end
mp.resetProgress()

```
For a thorough example, go [here](https://github.com/ClementPinard/imagenet-multiGPU.torch)
