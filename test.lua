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
print('\n')

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
