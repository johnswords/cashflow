let audioEnabled = true;
let audioContext = null;

const getContext = () => {
  if (!audioContext) {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return null;
    audioContext = new AudioCtx();
  }
  return audioContext;
};

const makeBeep = (freq, duration, type = "square", gain = 0.12) => {
  const ctx = getContext();
  if (!ctx) return;
  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();
  oscillator.type = type;
  oscillator.frequency.value = freq;
  gainNode.gain.value = gain;
  oscillator.connect(gainNode);
  gainNode.connect(ctx.destination);
  const startTime = ctx.currentTime;
  oscillator.start(startTime);
  oscillator.stop(startTime + duration);
  gainNode.gain.setTargetAtTime(0, startTime + duration - 0.05, 0.03);
};

export const setAudioEnabled = value => {
  audioEnabled = Boolean(value);
  if (!audioEnabled && audioContext) {
    audioContext.close();
    audioContext = null;
  }
};

export const playSound = name => {
  if (!audioEnabled) return;
  switch (name) {
    case "save":
      makeBeep(880, 0.09, "square", 0.1);
      makeBeep(1320, 0.07, "square", 0.08);
      break;
    case "victory": {
      const ctx = getContext();
      if (!ctx) return;
      const sequence = [
        { freq: 659, time: 0 },
        { freq: 784, time: 0.15 },
        { freq: 988, time: 0.32 },
        { freq: 1318, time: 0.45 }
      ];
      sequence.forEach(step => {
        setTimeout(() => makeBeep(step.freq, 0.13, "triangle", 0.11), step.time * 1000);
      });
      break;
    }
    default:
      break;
  }
};
