#!/usr/bin/env python3
"""Generate the original seamless menu loop 'Neon Blood Drive'."""
import math, random, wave
from array import array
from pathlib import Path
RATE=44100; BPM=104; BEAT=60/BPM; BARS=32; DURATION=BARS*4*BEAT; COUNT=round(DURATION*RATE); TAU=math.tau
def midi(n): return 440*2**((n-69)/12)
def osc(kind,p):
 p%=1
 if kind=="saw": return 2*p-1
 if kind=="square": return 1 if p<.5 else -1
 return math.sin(TAU*p)
def env(t,length): return min(1,t/.015)*min(1,max(0,length-t)/.12)
left=array("f",[0])*COUNT; right=array("f",[0])*COUNT
def note(start,length,n,amp,kind="sine",pan=0,detune=0):
 begin=int(start*RATE); end=int((start+length)*RATE); freq=midi(n)*2**(detune/1200)
 lg=math.sqrt((1-pan)*.5); rg=math.sqrt((1+pan)*.5)
 for i in range(begin,end):
  t=(i-begin)/RATE; phase=freq*t; value=osc(kind,phase)
  if kind=="saw": value=.68*value+.32*math.sin(TAU*phase)
  value*=amp*env(t,length); destination=i%COUNT
  left[destination]+=value*lg; right[destination]+=value*rg
progression=[([50,53,57,60,64],38),([48,52,55,59,62],36),([46,50,53,57,60],34),([49,52,55,58,62],37)]
for bar in range(BARS):
 chord,bass=progression[bar%4]; start=bar*4*BEAT
 for j,n in enumerate(chord):
  note(start,4.15*BEAT,n,.027,"saw",(j-2)*.18,-5); note(start,4.15*BEAT,n,.027,"saw",(2-j)*.18,5)
 pattern=[bass,bass,bass+7,bass,bass+12,bass+7,bass,bass+3]
 for step,n in enumerate(pattern):
  note(start+step*BEAT/2,BEAT*.42,n,.13,"square",-.05); note(start+step*BEAT/2,BEAT*.4,n-12,.08,"sine",.05)
motif=[(0,69),(.5,72),(1,74),(1.75,72),(2,69),(2.75,67),(3.25,65),(3.5,64)]
answer=[(0,69),(.5,72),(1,73),(1.5,76),(2,74),(2.5,72),(3,68),(3.5,67)]
for bar in range(BARS):
 phrase=motif if bar%4 in (0,2) else answer; start=bar*4*BEAT
 if bar%8>=2:
  for pos,n in phrase:
   note(start+pos*BEAT,BEAT*.38,n,.085,"square",.24); note(start+(pos+.375)*BEAT,BEAT*.24,n,.026,"sine",-.35)
random.seed(13)
for step in range(BARS*16):
 start=step*BEAT/4; begin=int(start*RATE); length=int(.16*RATE)
 if step%4==0:
  for j in range(min(length,COUNT-begin)):
   t=j/RATE; phase=48*t+42*(1-math.exp(-26*t))/26; v=math.sin(TAU*phase)*math.exp(-28*t)*.4
   left[begin+j]+=v*.7; right[begin+j]+=v*.7
 if step%8==4:
  for j in range(min(length,COUNT-begin)):
   t=j/RATE; v=(random.uniform(-1,1)*.19+math.sin(TAU*185*t)*.1)*math.exp(-20*t)
   left[begin+j]+=v*.65; right[begin+j]+=v*.75
 if step%2==0:
  for j in range(min(int(.055*RATE),COUNT-begin)):
   t=j/RATE; v=random.uniform(-1,1)*math.exp(-65*t)*.1; pan=-.25 if step%4==0 else .25
   left[begin+j]+=v*(.58-pan*.2); right[begin+j]+=v*(.58+pan*.2)
dry_l=array("f",left); dry_r=array("f",right)
for delay,gain in ((.75,.16),(1.5,.08)):
 shift=round(delay*BEAT*RATE)
 for i in range(COUNT):
  source=(i-shift)%COUNT; left[i]+=dry_r[source]*gain; right[i]+=dry_l[source]*gain
peak=max(max(abs(v) for v in left),max(abs(v) for v in right),1e-9); gain=.78/peak; pcm=array("h")
for l,r in zip(left,right):
 pcm.append(int(math.tanh(l*gain*1.35)/math.tanh(1.35)*30000)); pcm.append(int(math.tanh(r*gain*1.35)/math.tanh(1.35)*30000))
output=Path(__file__).resolve().parents[1]/"assets"/"audio"/"neon_blood_drive.wav"; output.parent.mkdir(parents=True,exist_ok=True)
with wave.open(str(output),"wb") as wav:
 wav.setnchannels(2); wav.setsampwidth(2); wav.setframerate(RATE); wav.writeframes(pcm.tobytes())
print(f"Generated {output} ({DURATION:.3f}s)")
