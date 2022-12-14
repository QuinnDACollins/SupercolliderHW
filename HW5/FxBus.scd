// HW5

// First, save this scd file as a new file, renaming it with your Last name at the beginning of the file name (e.g. "Fieldsteel HW5.scd"). Write your answers and upload this renamed file to the course website for your submission.

//For this problem set, I am providing you with some starting SynthDefs - one that loops a buffer, one that applies a flanger effect to an input signal, and one that applies a reverb effect to an input signal. A drum loop sample is also provided:

https://uofi.box.com/s/vrh8j78mhend29hvyydpt4gygtlb0wfh

//Boot the server, evaluate the SynthDefs below, and take some time to study them.

(
SynthDef.new(\playbuf, {
	arg buf = 0, rate = 1, amp = 0.3, gate = 1, out = 0;
	var sig, env;
	env = EnvGen.kr(Env.asr(0,1,2,-1), gate, doneAction:2);
	sig = PlayBuf.ar(2, buf, BufRateScale.ir(buf) * rate, loop:1);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\flanger, {
	arg in = 0, out = 0;
	var sig, flanger;
	sig = In.ar(in, 2);

	//For the curious: a flanger effect is created by summing a signal with a delayed copy of itself, in which the delay time is fluctuating, often sinusoidally. This creates predictable patterns of constructive and destructive interference, resulting in a sweeping resonance effect that follows the pattern of the sine wave (in this case, the pitch of the resonance varies between 100 and 1000 Hz)
	flanger = CombL.ar(sig, 0.01, 1 / SinOsc.ar(0.1).range(100,1000), 0.03);
	sig = (sig + flanger) * 0.5;

	Out.ar(out, sig);
}).add;

SynthDef.new(\reverb, {
	arg in = 0, mix = 0.3, out = 0;
	var sig;
	sig = In.ar(in, 2);
	sig = FreeVerb2.ar(sig[0], sig[1], mix: mix, room: 0.99);
	sig = LPF.ar(sig, 1500);
	Out.ar(out, sig);
}).add;


SynthDef.new(\playbufparallel, {
	arg buf = 0, rate = 1, amp = 0.3, gate = 1, out = 0, out2 = 0;
	var sig, env;
	env = EnvGen.kr(Env.asr(0,1,2,-1), gate, doneAction:2);
	sig = PlayBuf.ar(2, buf, BufRateScale.ir(buf) * rate, loop:1);
	sig = sig * env * amp;
	Out.ar(out, sig);
	Out.ar(out2, sig);
}).add;
)

// ----------
// Problem 1.
// Load the drum loop into a Buffer, stored in a global variable. Using "thisProcess.nowExecutingPath" or "resolveRelative", as you did on a previous problem set. This code file and the drum sample should be placed in the same folder. When you are ready to submit, create a zip of this folder and submit the zip. I should be able to run your code without needing to change the file path.
s.boot;
Buffer.freeAll;
~myPath = PathName.new(thisProcess.nowExecutingPath);
~myPath = ~myPath.pathOnly;

~bDrumloop = Buffer.read(s, "drumloop1.wav".resolveRelative);
~bDrumloop.play;





// ----------
// Problem 2.
// Write some code that plays through the buffer, and sends the audio signal through the flanger effect, and then sends the flanger output through the reverb. This will involve allocating some audio busses using Bus.audio(). Add one or more lines of code afterward that stop the sound and handle cleanup (e.g. fade out the Synth that plays the buffer, and free the effect Synths). Do this without using Groups. The signal path should look like this:

// [buf] --> [flanger] --> [reverb] --> [speakers]

{
	s.newBusAllocators;
	~flangerBus = Bus.audio(s, 2);
	~reverbBus = Bus.audio(s, 2);
}
s.scope;
f = Synth(\flanger, [in: ~flangerBus, out:~reverbBus]);
r = Synth(\reverb, [in:~reverbBus]);

d = Synth(\playbuf, [out:~flangerBus]);

d.free;
f.free;
r.free;
s.freeAll;
// ----------
// Problem 3.
// Do the same thing that you did in the previous problem, but this time, create and use Groups to organize your signal flow. Remember that you only have to allocate busses once, and redundant bus allocation can lead to problems. Reuse the busses you allocated from the previous problem. Don't forget to include cleanup code again, making sure to remove the Groups as well.

~sourceGroup = Group.new();
~fxGroup = Group.new(~sourceGroup, \addAfter);

f = Synth(\flanger, [in: ~flangerBus], ~fxGroup);
r = Synth(\reverb, [in:~reverbBus], ~fxGroup);

d = Synth(\playbuf, [out:~flangerBus], ~sourceGroup);

~sourceGroup.freeAll;
~fxGroup.freeAll;
s.freeAll;
// ----------
// Problem 4.
// Do the same thing that you did in the previous problem, but swap the order of the two effects. Include some cleanup code. The signal path should look like this:

// [buf] --> [reverb] --> [flanger] --> [speakers]

//The result will sound *mostly* the same as the previous problem, but there is a very subtle difference ??? in this case, the reverb tail will have an audible flanger effect applied to it, whereas in the previous problem, the reverb sounds more "normal."
~sourceGroup = Group.new();
~fxGroup = Group.new(~sourceGroup, \addAfter);

r = Synth(\reverb, [in:~reverbBus], ~fxGroup);
f = Synth(\flanger, [in: ~flangerBus], ~fxGroup);


d = Synth(\playbuf, [out:~flangerBus], ~sourceGroup);

~sourceGroup.freeAll;
~fxGroup.freeAll;
s.freeAll;


// ----------
// Problem 5.
// Write some code that loops through the buffer, and sends that audio signal to both effects in parallel, instead of in series. This will involve modifying the \playbuf SynthDef so that there are two "Out.ar" UGens with two different bus arguments, allowing the signal to branch and follow two different paths. You can use Groups if you want, but this can also be done without Groups. The signal path should look like this:

// [buf] ----->  [reverb]  ----> [speakers]
//         |                         ^
//         |                         |
//         |                         |
//         \--> [flanger] ----------/

f = Synth(\flanger, [in: ~flangerBus]);
r = Synth(\reverb, [in:~reverbBus]);

d = Synth(\playbufparallel, [out:~reverbBus, out2:~flangerBus]);

d.free;
f.free;
r.free;
s.freeAll;
