import { play, set, unlock } from './foley.js';

for (const eventName of ['pointerdown', 'keydown']) {
  document.addEventListener(eventName, () => unlock(), {
    once: true,
    capture: true,
  });
}

globalThis._slidePuzzleFoley = {
  play(cue, pitch, volume, pan) {
    play(cue, { pitch, volume, pan });
  },
  setMuted(muted) {
    set({ muted });
  },
  setTheme(theme) {
    set({ theme });
  },
};
