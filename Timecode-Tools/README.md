This is a selection of small LUA plugins designed to manipulate timecode obkects in the MA2 ecosystem.

They're non-destructive, and allow you to use math to work around some of the more tedious and time consuming tasks related to changing or combining timecode pool objects. Input a timecode number, answer some questions, and a new timecode will be exported wherever you like.

Included functions:
- Insert Time at cut point
- Delete Time at cut point
- Trim Start of timecode
- Trim End of timecode
- Stretch timecode from one BPM to another BPM
- Stretch timecode by a multiplication factor
- Splice 2 timecodes together to make one combined timecode object

You will need to know some frame numbers to pull off most of these, and quite importantly, they all need to be calculated at 30FPS, regardless of the actual FPS of your timecode objects, so here's a [handy tool](https://chris.uk/timecode-tools) to help with that.
