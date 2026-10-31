/*
 * MIT License
 *
 * Copyright (c) 2026 eakbulut and Foley contributors
 * https://github.com/eakbulut/foley (v2.9.0, commit 251fa6d8e970f47bf196c5305efd166a325a71a5)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/* ============================================================
   foley — sound effects for the interface, performed live.
   28 interaction cues synthesized with Web Audio.
   Zero dependencies. Zero audio files. MIT.
   https://github.com/eakbulut/foley
   ============================================================ */

export const version = "2.9.0";

/* ---------------- engine ---------------- */
const T = {
  ctx: null, master: null, limiter: null, analyser: null, dry: null, verb: null, wet: null,
  settings: { volume: 0.7, transpose: 0, space: 0.22, muted: false, hover: true, theme: "default", duck: 1, localize: 0 },
  _scale: 1, _cool: {}, _noise: null, _unlocked: false, _bus: null, _sendBus: null,

  applyGain() {
    if (!this.ctx) return;
    const g = this.settings.muted ? 0 : this.settings.volume * this.settings.duck;
    this.master.gain.setTargetAtTime(g, this.ctx.currentTime, 0.02);
  },

  ensure() {
    if (this.ctx) { if (this.ctx.state === "suspended") this.ctx.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    const ctx = new AC();
    this.ctx = ctx;
    this.master = ctx.createGain();
    this.master.gain.value = this.settings.muted ? 0 : this.settings.volume;
    this.analyser = ctx.createAnalyser();
    this.analyser.fftSize = 2048;
    this.analyser.smoothingTimeConstant = 0.4;
    /* brick-wall safety: overlapping arpeggios and hover storms never clip */
    this.limiter = ctx.createDynamicsCompressor();
    this.limiter.threshold.value = -10;
    this.limiter.knee.value = 4;
    this.limiter.ratio.value = 12;
    this.limiter.attack.value = 0.002;
    this.limiter.release.value = 0.12;
    this.master.connect(this.limiter);
    this.limiter.connect(this.analyser);
    this.analyser.connect(ctx.destination);
    this.dry = ctx.createGain();
    this.dry.connect(this.master);
    this.verb = ctx.createConvolver();
    this.verb.buffer = this.makeIR(1.4, 3.2);
    this.wet = ctx.createGain();
    this.wet.gain.value = this.settings.space;
    this.verb.connect(this.wet);
    this.wet.connect(this.master);
    if (!this._unlocked) { this._unlocked = true; emit("unlock", {}); }
  },

  makeIR(dur, decay) {
    const rate = this.ctx.sampleRate, len = Math.floor(rate * dur);
    const buf = this.ctx.createBuffer(2, len, rate);
    for (let ch = 0; ch < 2; ch++) {
      const d = buf.getChannelData(ch);
      for (let i = 0; i < len; i++) {
        d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, decay);
      }
    }
    return buf;
  },

  noiseBuf() {
    if (this._noise) return this._noise;
    const rate = this.ctx.sampleRate, len = rate;
    const buf = this.ctx.createBuffer(1, len, rate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    this._noise = buf;
    return buf;
  },

  pitch(f, extraSemis) {
    return f * Math.pow(2, (this.settings.transpose + (extraSemis || 0)) / 12);
  },
};

/* ---------------- events ---------------- */
const listeners = {};
function emit(ev, payload) {
  (listeners[ev] || []).forEach((cb) => { try { cb(payload); } catch (e) { /* listener errors stay theirs */ } });
}

/** Subscribe to engine events: "play" ({name, family}) and "unlock" ({}). Returns an unsubscribe function. */
export function on(ev, cb) {
  (listeners[ev] = listeners[ev] || []).push(cb);
  return () => {
    const a = listeners[ev];
    const i = a.indexOf(cb);
    if (i >= 0) a.splice(i, 1);
  };
}

/* ---------------- themes: one transform reshapes every spec ---------------- */
function mkTheme(o) {
  return Object.assign({ label: "", wave: null, pitch: 1, attack: 1, decay: 1, send: 1, noiseLvl: 1, noiseF: 1, q: 1, shimmer: false }, o);
}
const THEMES = {
  default:    mkTheme({ label: "Default" }),
  soft:       mkTheme({ label: "Soft",       wave: { sawtooth: "triangle", square: "sine", triangle: "sine" },
                        pitch: 0.8, attack: 2.6, decay: 1.45, send: 1.5, noiseLvl: 0.5, noiseF: 0.7, q: 0.7 }),
  mechanical: mkTheme({ label: "Mechanical", attack: 0.55, decay: 0.5, send: 0.25, noiseLvl: 1.6, noiseF: 1.25, q: 1.6 }),
  glass:      mkTheme({ label: "Glass",      pitch: 1.45, attack: 0.7, decay: 1.6, send: 1.7,
                        noiseLvl: 0.45, noiseF: 1.9, q: 3.2, shimmer: true }),
};
let theme = THEMES.default;
let overrides = {}; /* per-cue spec overrides from the active sound set */

function effectiveSpec(name) { return overrides[name] || CUES[name].spec; }

function sanitizeTransform(c) {
  const lim = (v, lo, hi, fb) => { const n = Number(v); return isFinite(n) ? Math.min(hi, Math.max(lo, n)) : fb; };
  return {
    label: "Custom",
    pitch: lim(c.pitch, 0.25, 4, 1), attack: lim(c.attack, 0.1, 6, 1), decay: lim(c.decay, 0.1, 6, 1),
    send: lim(c.send, 0, 3, 1), noiseLvl: lim(c.noiseLvl, 0, 3, 1), noiseF: lim(c.noiseF, 0.25, 4, 1),
    q: lim(c.q, 0.1, 6, 1), shimmer: !!c.shimmer,
    wave: (c.wave && typeof c.wave === "object") ? c.wave : null,
  };
}

export const themes = Object.freeze(Object.keys(THEMES));

/* ---------------- synth voices ---------------- */
function tone(o) {
  const th = theme, ctx = T.ctx, t0 = o.t0;
  const osc = ctx.createOscillator();
  osc.type = (th.wave && th.wave[o.type || "sine"]) || o.type || "sine";
  const f = T.pitch(o.f, o.semis) * th.pitch;
  osc.frequency.setValueAtTime(f, t0);
  if (o.f2) osc.frequency.exponentialRampToValueAtTime(Math.max(20, T.pitch(o.f2, o.semis) * th.pitch), t0 + (o.glide || 0.06));
  const g = ctx.createGain();
  const a = (o.a != null ? o.a : 0.004) * th.attack;
  const d = (o.d != null ? o.d : 0.15) * th.decay;
  const peak = (o.peak != null ? o.peak : 0.18) * T._scale;
  /* glass grows a quiet inharmonic partial on every pitched voice */
  if (th.shimmer && !o._plain) tone(Object.assign({}, o, { f: o.f * 2.99, f2: o.f2 ? o.f2 * 2.99 : null, peak: (o.peak != null ? o.peak : 0.18) * 0.16, d: (o.d != null ? o.d : 0.15) * 0.8, _plain: true }));
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.linearRampToValueAtTime(peak, t0 + a);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + a + d);
  osc.connect(g);
  g.connect(T._bus || T.dry);
  const sendAmt = (o.send || 0) * th.send;
  if (sendAmt > 0.01) {
    const s = ctx.createGain();
    s.gain.value = sendAmt;
    g.connect(s); s.connect(T._sendBus || T.verb);
  }
  osc.start(t0);
  osc.stop(t0 + a + d + 0.15);
}

function noise(o) {
  const th = theme, ctx = T.ctx, t0 = o.t0;
  const src = ctx.createBufferSource();
  src.buffer = T.noiseBuf();
  src.loop = true;
  const fl = ctx.createBiquadFilter();
  fl.type = o.type || "bandpass";
  fl.frequency.setValueAtTime((o.f || 2000) * th.noiseF, t0);
  if (o.f2) fl.frequency.exponentialRampToValueAtTime(o.f2 * th.noiseF, t0 + (o.glide || 0.1));
  fl.Q.value = (o.q != null ? o.q : 1) * th.q;
  const g = ctx.createGain();
  const a = (o.a != null ? o.a : 0.002) * th.attack;
  const d = (o.d != null ? o.d : 0.05) * (th.decay * 0.7 + 0.3);
  const peak = (o.peak != null ? o.peak : 0.15) * T._scale * th.noiseLvl;
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.linearRampToValueAtTime(peak, t0 + a);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + a + d);
  src.connect(fl); fl.connect(g); g.connect(T._bus || T.dry);
  const sendAmt = (o.send || 0) * th.send;
  if (sendAmt > 0.01) {
    const s = ctx.createGain();
    s.gain.value = sendAmt;
    g.connect(s); s.connect(T._sendBus || T.verb);
  }
  src.start(t0);
  src.stop(t0 + a + d + 0.1);
}

/* ---------------- specs: cues as data ----------------
   A cue is an array of layers. Layer kinds:
   tone:    { kind, at, wave, f, f2, glide, a, d, peak, send }
   noise:   { kind, at, filter, f, f2, glide, q, a, d, peak, send }
   cluster: { kind, at, n, step, fMin, fMax, d, peak, send, seed } - seeded random grains */

function mulberry32(seed) {
  let s = seed >>> 0;
  return function () {
    s |= 0; s = (s + 0x6D2B79F5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function L(kind, at, o) { return Object.assign({ kind, at }, o); }
function bellLayers(at, f, peak, decay, send) {
  const ratios = [1, 2.76, 5.40, 8.93], gains = [1, 0.42, 0.18, 0.07];
  return ratios.map((r, i) =>
    L("tone", at, { wave: "sine", f: f * r, f2: null, glide: 0.06, a: 0.002, d: decay * (1 - i * 0.16), peak: peak * gains[i], send })
  );
}

function runSpec(spec, t0) {
  for (const lay of spec) {
    const at = t0 + (lay.at || 0);
    if (lay.kind === "tone") {
      tone({ t0: at, type: lay.wave, f: lay.f, f2: lay.f2 || null, glide: lay.glide, a: lay.a, d: lay.d, peak: lay.peak, send: lay.send || 0 });
    } else if (lay.kind === "noise") {
      noise({ t0: at, type: lay.filter, f: lay.f, f2: lay.f2 || null, glide: lay.glide, q: lay.q, a: lay.a, d: lay.d, peak: lay.peak, send: lay.send || 0 });
    } else if (lay.kind === "cluster") {
      const rnd = mulberry32(lay.seed != null ? lay.seed : 1);
      for (let i = 0; i < lay.n; i++) {
        tone({ t0: at + i * lay.step, type: "sine", f: lay.fMin + rnd() * (lay.fMax - lay.fMin), a: 0.004, d: lay.d, peak: lay.peak, send: lay.send || 0 });
      }
    }
  }
}

/* ---------------- the 28 cues ---------------- */
const CUES = {
  /* pointer */
  tick:    { cat: "pointer", key: "1", ds: "a grain as the pointer crosses", spec: [
    L("noise", 0, { filter: "bandpass", f: 5200, f2: null, glide: 0.1, q: 2.5, a: 0.002, d: 0.018, peak: 0.10, send: 0 }),
    L("tone", 0, { wave: "sine", f: 2400, f2: null, glide: 0.06, a: 0.004, d: 0.02, peak: 0.05, send: 0 }),
  ]},
  hover:   { cat: "pointer", key: "2", ds: "a breath of pitch, barely there", spec: [
    L("tone", 0, { wave: "sine", f: 880, f2: 1150, glide: 0.05, a: 0.004, d: 0.07, peak: 0.06, send: 0 }),
  ]},
  glide:   { cat: "pointer", key: "3", ds: "a longer sweep for big targets", spec: [
    L("tone", 0, { wave: "sine", f: 420, f2: 940, glide: 0.11, a: 0.004, d: 0.13, peak: 0.09, send: 0.2 }),
  ]},
  pop:     { cat: "pointer", key: "4", ds: "a bubble bursting under the cursor", spec: [
    L("tone", 0, { wave: "sine", f: 640, f2: 190, glide: 0.05, a: 0.004, d: 0.06, peak: 0.2, send: 0 }),
    L("noise", 0, { filter: "bandpass", f: 3000, f2: null, glide: 0.1, q: 1, a: 0.002, d: 0.012, peak: 0.06, send: 0 }),
  ]},

  /* press */
  press:   { cat: "press", key: "5", ds: "the down-stroke, weighted", spec: [
    L("tone", 0, { wave: "triangle", f: 190, f2: 150, glide: 0.03, a: 0.004, d: 0.06, peak: 0.28, send: 0 }),
    L("noise", 0, { filter: "bandpass", f: 1800, f2: null, glide: 0.1, q: 0.8, a: 0.002, d: 0.012, peak: 0.12, send: 0 }),
  ]},
  release: { cat: "press", key: "6", ds: "the up-stroke, lighter", spec: [
    L("tone", 0, { wave: "triangle", f: 300, f2: 250, glide: 0.02, a: 0.004, d: 0.045, peak: 0.18, send: 0 }),
    L("noise", 0, { filter: "bandpass", f: 3200, f2: null, glide: 0.1, q: 0.8, a: 0.002, d: 0.01, peak: 0.08, send: 0 }),
  ]},
  tap:     { cat: "press", key: "7", ds: "a neutral single click", spec: [
    L("noise", 0, { filter: "bandpass", f: 2200, f2: null, glide: 0.1, q: 1.4, a: 0.002, d: 0.02, peak: 0.16, send: 0 }),
    L("tone", 0, { wave: "sine", f: 1100, f2: null, glide: 0.06, a: 0.004, d: 0.025, peak: 0.07, send: 0 }),
  ]},
  thock:   { cat: "press", key: "8", ds: "mechanical keyboard, lubed", spec: [
    L("tone", 0, { wave: "sine", f: 120, f2: 95, glide: 0.03, a: 0.004, d: 0.055, peak: 0.3, send: 0 }),
    L("noise", 0, { filter: "lowpass", f: 900, f2: null, glide: 0.1, q: 1, a: 0.002, d: 0.02, peak: 0.2, send: 0 }),
  ]},

  /* toggle */
  on:      { cat: "toggle", key: "9", ds: "two notes stepping up", spec: [
    L("tone", 0, { wave: "sine", f: 660, f2: null, glide: 0.06, a: 0.004, d: 0.05, peak: 0.14, send: 0 }),
    L("tone", 0.07, { wave: "sine", f: 990, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.16, send: 0.15 }),
  ]},
  off:     { cat: "toggle", key: "0", ds: "the same figure, descending", spec: [
    L("tone", 0, { wave: "sine", f: 990, f2: null, glide: 0.06, a: 0.004, d: 0.05, peak: 0.14, send: 0 }),
    L("tone", 0.07, { wave: "sine", f: 620, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.15, send: 0 }),
  ]},
  switch:  { cat: "toggle", key: "Q", ds: "a hard mode-change snap", spec: [
    L("noise", 0, { filter: "bandpass", f: 2600, f2: null, glide: 0.1, q: 3, a: 0.002, d: 0.015, peak: 0.18, send: 0 }),
    L("tone", 0.01, { wave: "sine", f: 520, f2: null, glide: 0.06, a: 0.004, d: 0.05, peak: 0.12, send: 0 }),
  ]},
  latch:   { cat: "toggle", key: "W", ds: "a low clunk that stays put", spec: [
    L("tone", 0, { wave: "triangle", f: 140, f2: 110, glide: 0.04, a: 0.004, d: 0.09, peak: 0.3, send: 0 }),
    L("noise", 0, { filter: "lowpass", f: 500, f2: null, glide: 0.1, q: 1, a: 0.002, d: 0.03, peak: 0.18, send: 0 }),
  ]},

  /* feedback */
  success: { cat: "feedback", key: "E", ds: "a small major lift", spec: [
    L("tone", 0, { wave: "sine", f: 523.25, f2: null, glide: 0.06, a: 0.004, d: 0.1, peak: 0.13, send: 0 }),
    L("tone", 0.09, { wave: "sine", f: 659.25, f2: null, glide: 0.06, a: 0.004, d: 0.12, peak: 0.13, send: 0 }),
    L("tone", 0.18, { wave: "sine", f: 783.99, f2: null, glide: 0.06, a: 0.004, d: 0.22, peak: 0.15, send: 0.3 }),
  ]},
  error:   { cat: "feedback", key: "R", ds: "two flat buzzes, no drama", spec: [
    L("tone", 0, { wave: "sawtooth", f: 220, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.09, send: 0 }),
    L("tone", 0.13, { wave: "sawtooth", f: 185, f2: null, glide: 0.06, a: 0.004, d: 0.13, peak: 0.09, send: 0 }),
  ]},
  warning: { cat: "feedback", key: "T", ds: "the same note, twice", spec: [
    L("tone", 0, { wave: "triangle", f: 493.88, f2: null, glide: 0.06, a: 0.004, d: 0.07, peak: 0.13, send: 0 }),
    L("tone", 0.15, { wave: "triangle", f: 493.88, f2: null, glide: 0.06, a: 0.004, d: 0.1, peak: 0.13, send: 0 }),
  ]},
  denied:  { cat: "feedback", key: "Y", ds: "a thud against the limit", spec: [
    L("tone", 0, { wave: "triangle", f: 160, f2: 120, glide: 0.05, a: 0.004, d: 0.08, peak: 0.26, send: 0 }),
    L("noise", 0, { filter: "lowpass", f: 400, f2: null, glide: 0.1, q: 1, a: 0.002, d: 0.04, peak: 0.14, send: 0 }),
  ]},

  /* notify */
  chime:   { cat: "notify", key: "U", ds: "a struck bar with partials", spec: bellLayers(0, 880, 0.14, 0.7, 0.45) },
  ping:    { cat: "notify", key: "I", ds: "one bright point of light", spec: [
    L("tone", 0, { wave: "sine", f: 1318.5, f2: null, glide: 0.06, a: 0.004, d: 0.28, peak: 0.12, send: 0.35 }),
    L("tone", 0, { wave: "sine", f: 1324, f2: null, glide: 0.06, a: 0.004, d: 0.24, peak: 0.05, send: 0.3 }),
  ]},
  bell:    { cat: "notify", key: "O", ds: "rounder and further away", spec: bellLayers(0, 523.25, 0.13, 0.9, 0.55) },
  bubble:  { cat: "notify", key: "P", ds: "a message surfacing", spec: [
    L("tone", 0, { wave: "sine", f: 320, f2: 900, glide: 0.09, a: 0.004, d: 0.1, peak: 0.14, send: 0.2 }),
  ]},

  /* motion */
  swoosh:  { cat: "motion", key: "A", ds: "air moving forward", spec: [
    L("noise", 0, { filter: "bandpass", f: 350, f2: 3400, glide: 0.22, q: 1.6, a: 0.03, d: 0.22, peak: 0.14, send: 0.25 }),
  ]},
  whoosh:  { cat: "motion", key: "S", ds: "the same air, leaving", spec: [
    L("noise", 0, { filter: "bandpass", f: 3200, f2: 320, glide: 0.22, q: 1.6, a: 0.03, d: 0.2, peak: 0.13, send: 0 }),
  ]},
  drop:    { cat: "motion", key: "D", ds: "something set down", spec: [
    L("tone", 0, { wave: "sine", f: 620, f2: 130, glide: 0.16, a: 0.004, d: 0.18, peak: 0.16, send: 0 }),
    L("noise", 0.15, { filter: "lowpass", f: 700, f2: null, glide: 0.1, q: 1, a: 0.002, d: 0.03, peak: 0.12, send: 0 }),
  ]},
  rise:    { cat: "motion", key: "F", ds: "something lifting off", spec: [
    L("tone", 0, { wave: "sine", f: 210, f2: 860, glide: 0.18, a: 0.004, d: 0.2, peak: 0.13, send: 0.25 }),
    L("noise", 0.1, { filter: "bandpass", f: 2400, f2: 5200, glide: 0.1, q: 1, a: 0.002, d: 0.1, peak: 0.05, send: 0 }),
  ]},

  /* state */
  loading:  { cat: "state", key: "G", ds: "three patient ticks", spec: [
    L("tone", 0, { wave: "sine", f: 700, f2: null, glide: 0.06, a: 0.004, d: 0.035, peak: 0.09, send: 0 }),
    L("tone", 0.12, { wave: "sine", f: 820, f2: null, glide: 0.06, a: 0.004, d: 0.035, peak: 0.09, send: 0 }),
    L("tone", 0.24, { wave: "sine", f: 940, f2: null, glide: 0.06, a: 0.004, d: 0.035, peak: 0.09, send: 0 }),
  ]},
  ready:    { cat: "state", key: "H", ds: "a warm open third", spec: [
    L("tone", 0, { wave: "sine", f: 440, f2: null, glide: 0.06, a: 0.004, d: 0.3, peak: 0.1, send: 0.25 }),
    L("tone", 0, { wave: "sine", f: 554.37, f2: null, glide: 0.06, a: 0.004, d: 0.3, peak: 0.09, send: 0.25 }),
  ]},
  complete: { cat: "state", key: "J", ds: "arpeggio, then shimmer", spec: [
    L("tone", 0, { wave: "sine", f: 523.25, f2: null, glide: 0.06, a: 0.004, d: 0.16, peak: 0.12, send: 0.3 }),
    L("tone", 0.08, { wave: "sine", f: 659.25, f2: null, glide: 0.06, a: 0.004, d: 0.21, peak: 0.12, send: 0.3 }),
    L("tone", 0.16, { wave: "sine", f: 783.99, f2: null, glide: 0.06, a: 0.004, d: 0.26, peak: 0.12, send: 0.3 }),
    L("tone", 0.24, { wave: "sine", f: 1046.5, f2: null, glide: 0.06, a: 0.004, d: 0.31, peak: 0.12, send: 0.3 }),
    /* the shimmer is the arpeggio's own chord, two octaves up - C7 E7 G7 C8.
       Random grains across 2-4.5k clashed with the C major underneath them. */
    L("tone", 0.34, { wave: "sine", f: 2093, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.03, send: 0.5 }),
    L("tone", 0.37, { wave: "sine", f: 2637, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.03, send: 0.5 }),
    L("tone", 0.40, { wave: "sine", f: 3135.96, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.03, send: 0.5 }),
    L("tone", 0.43, { wave: "sine", f: 4186, f2: null, glide: 0.06, a: 0.004, d: 0.09, peak: 0.03, send: 0.5 }),
  ]},
  sparkle:  { cat: "state", key: "K", ds: "a handful of glitter", spec: [
    L("cluster", 0, { n: 6, step: 0.035, fMin: 1600, fMax: 4600, d: 0.1, peak: 0.045, send: 0.5, seed: 11 }),
  ]},
};

/** Cue metadata: { family, key, description } per cue name. Specs stay behind getSpec(). */
export const cues = Object.freeze(Object.fromEntries(
  Object.entries(CUES).map(([n, c]) => [n, Object.freeze({ family: c.cat, key: c.key, description: c.ds })])
));

/** The seven cue families. */
export const families = Object.freeze({
  pointer:  Object.freeze({ name: "Pointer",  description: "grains and breaths for hover and focus" }),
  press:    Object.freeze({ name: "Press",    description: "weight for down-strokes and keys" }),
  toggle:   Object.freeze({ name: "Toggle",   description: "paired figures for binary state" }),
  feedback: Object.freeze({ name: "Feedback", description: "verdicts - lifted, flat, or blocked" }),
  notify:   Object.freeze({ name: "Notify",   description: "bells and pings for the unasked-for" }),
  motion:   Object.freeze({ name: "Motion",   description: "air and travel for transitions" }),
  state:    Object.freeze({ name: "State",    description: "loading, ready, and the arrival" }),
});

/* ---------------- spec validation ---------------- */
const LIMITS = {
  at: [0, 1.5], f: [40, 8000], f2: [40, 8000], glide: [0.005, 1],
  a: [0, 0.5], d: [0.005, 2.5], peak: [0, 0.4], send: [0, 1], q: [0.3, 12],
  n: [1, 12], step: [0, 0.2], fMin: [40, 8000], fMax: [40, 8000],
};
const WAVES = ["sine", "triangle", "square", "sawtooth"];
const FILTERS = ["bandpass", "lowpass", "highpass"];
const MAX_LAYERS = 8;

function clampNum(v, key, fallback) {
  const lim = LIMITS[key];
  const n = Number(v);
  if (!isFinite(n)) return fallback != null ? fallback : lim[0];
  return Math.min(lim[1], Math.max(lim[0], n));
}

/** Validate and clamp a spec (array of layers) into a safe, playable copy.
    Unknown kinds are dropped; unknown fields are stripped; at most 8 layers. */
export function normalizeSpec(spec) {
  if (!Array.isArray(spec)) return [];
  const out = [];
  for (const raw of spec) {
    if (!raw || typeof raw !== "object") continue;
    const at = clampNum(raw.at, "at", 0);
    if (raw.kind === "tone") {
      out.push({
        kind: "tone", at,
        wave: WAVES.includes(raw.wave) ? raw.wave : "sine",
        f: clampNum(raw.f, "f", 440),
        f2: raw.f2 ? clampNum(raw.f2, "f2") : null,
        glide: clampNum(raw.glide, "glide", 0.06),
        a: clampNum(raw.a, "a", 0.004),
        d: clampNum(raw.d, "d", 0.15),
        peak: clampNum(raw.peak, "peak", 0.15),
        send: clampNum(raw.send, "send", 0),
      });
    } else if (raw.kind === "noise") {
      out.push({
        kind: "noise", at,
        filter: FILTERS.includes(raw.filter) ? raw.filter : "bandpass",
        f: clampNum(raw.f, "f", 2000),
        f2: raw.f2 ? clampNum(raw.f2, "f2") : null,
        glide: clampNum(raw.glide, "glide", 0.1),
        q: clampNum(raw.q, "q", 1),
        a: clampNum(raw.a, "a", 0.002),
        d: clampNum(raw.d, "d", 0.05),
        peak: clampNum(raw.peak, "peak", 0.12),
        send: clampNum(raw.send, "send", 0),
      });
    } else if (raw.kind === "cluster") {
      const fMin = clampNum(raw.fMin, "fMin", 1600);
      out.push({
        kind: "cluster", at,
        n: Math.round(clampNum(raw.n, "n", 5)),
        step: clampNum(raw.step, "step", 0.035),
        fMin,
        fMax: Math.max(fMin, clampNum(raw.fMax, "fMax", 4600)),
        d: clampNum(raw.d, "d", 0.1),
        peak: clampNum(raw.peak, "peak", 0.04),
        send: clampNum(raw.send, "send", 0.5),
        seed: Math.round(Number(raw.seed)) || 1,
      });
    }
    if (out.length >= MAX_LAYERS) break;
  }
  return out;
}

/** A deep, editable copy of the cue's effective spec - the sound set's override
    if one is active, the built-in otherwise. */
export function getSpec(name) {
  const cue = CUES[name];
  if (!cue) return null;
  return JSON.parse(JSON.stringify(effectiveSpec(name)));
}

/** A snapshot of the active sonic identity as a portable sound set:
    { name, transform, cues }. Feed it back through set({ theme: soundSet }). */
export function getSet() {
  const base = mkTheme({});
  const tr = {};
  for (const k of ["pitch", "attack", "decay", "send", "noiseLvl", "noiseF", "q"]) {
    if (theme[k] !== base[k]) tr[k] = theme[k];
  }
  if (theme.shimmer) tr.shimmer = true;
  if (theme.wave) tr.wave = Object.assign({}, theme.wave);
  return {
    name: T.settings.theme,
    transform: tr,
    cues: JSON.parse(JSON.stringify(overrides)),
  };
}

/* ---------------- public API ---------------- */

/** Resume/create the AudioContext. Call from a user gesture, or let play()/bind() handle it. */
export function unlock() { T.ensure(); }

/** The engine's AnalyserNode (2048-point), or null before the first unlock. For scopes and meters. */
export function getAnalyser() { return T.analyser; }

/** Update engine settings: volume (0-1), transpose (semitones), space (0-1 reverb),
    muted, hover, theme, duck (0-1), localize (0-1 stereo spread for bind()'s cues). */
export function set(opts) {
  if (!opts) return;
  if (opts.localize != null) T.settings.localize = Math.min(1, Math.max(0, Number(opts.localize) || 0));
  if (opts.volume != null) { T.settings.volume = opts.volume; T.applyGain(); }
  if (opts.duck != null) { T.settings.duck = Math.min(1, Math.max(0, opts.duck)); T.applyGain(); }
  if (opts.space != null) {
    T.settings.space = opts.space;
    if (T.ctx) T.wet.gain.setTargetAtTime(opts.space, T.ctx.currentTime, 0.02);
  }
  if (opts.muted != null) { T.settings.muted = opts.muted; T.applyGain(); }
  if (opts.transpose != null) T.settings.transpose = opts.transpose;
  if (opts.hover != null) T.settings.hover = opts.hover;
  if (opts.theme != null) {
    if (typeof opts.theme === "string" && THEMES[opts.theme]) {
      /* a theme assignment replaces the whole sonic identity, overrides included */
      T.settings.theme = opts.theme;
      theme = THEMES[opts.theme];
      overrides = {};
    } else if (typeof opts.theme === "object" && opts.theme) {
      const o = opts.theme;
      const isSet = ("cues" in o) || ("transform" in o) || ("name" in o);
      theme = mkTheme(sanitizeTransform(isSet ? (o.transform || {}) : o));
      overrides = {};
      if (isSet && o.cues && typeof o.cues === "object") {
        for (const [n, sp] of Object.entries(o.cues)) {
          if (!CUES[n]) continue;           /* unknown cue names are dropped */
          const norm = normalizeSpec(sp);
          if (norm.length) overrides[n] = norm;
        }
      }
      T.settings.theme = (isSet && typeof o.name === "string" && o.name.trim())
        ? String(o.name).trim().slice(0, 40)
        : "custom";
    }
  }
}

/** A snapshot of the current settings. */
export function get() { return Object.assign({}, T.settings); }

/* the audible length of a spec, for loop scheduling */
function specDuration(spec) {
  let end = 0;
  for (const lay of spec) {
    const at = lay.at || 0;
    let tail;
    if (lay.kind === "cluster") tail = (lay.n - 1) * lay.step + (lay.d || 0.1) + 0.01;
    else tail = (lay.a || 0.004) + (lay.d || 0.15);
    if (at + tail > end) end = at + tail;
  }
  return end;
}

/* ---------------- spatial placement ----------------
   A cue is a ~200ms one-shot: it is over long before anything could move. So
   position is a play option, fixed at the moment of the trigger, and not a
   property of the sound. Deliberately absent, and not an oversight: listener
   position/orientation, cones, distance attributes, repositioning through the
   handle, and panned exports. Those exist to serve long-running sources; here
   they would be surface with nothing behind it. A WebXR listener API, if it is
   ever wanted, is an issue-driven follow-up. */

function clampPan(v) {
  const n = Number(v);
  return isFinite(n) ? Math.min(1, Math.max(-1, n)) : 0;
}

function validPos(p) {
  if (!Array.isArray(p) || p.length !== 3) return null;
  const xyz = p.map(Number);
  return xyz.every((n) => isFinite(n)) ? xyz : null;
}

/** The pan (-1..1) that the current `localize` setting derives for an element from
    where it sits horizontally on screen; 0 when localize is 0. bind() applies this
    to every data-foley-* cue - use it when you call play() yourself. */
export function panFor(el) {
  const lz = T.settings.localize;
  if (!lz || !el || typeof el.getBoundingClientRect !== "function") return 0;
  const r = el.getBoundingClientRect();
  return clampPan(((r.left + r.width / 2) / window.innerWidth * 2 - 1) * lz);
}

/* A loop in a backgrounded tab is noise from a page the user can't see, and an
   AudioContext is not reliably suspended there - so repetitions are skipped while the
   tab is hidden. One-shots are deliberately left alone: a ping for an incoming message
   is exactly what a background tab should still be allowed to do. setInterval keeps
   running either way, so the loop simply picks up again when the tab comes back. */
function loopAudible() {
  return !T.settings.muted && !(typeof document !== "undefined" && document.hidden);
}

/* shared performance path: cooldown, humanization, loop, stop handle, emit */
function perform(key, spec, opts, emitName, emitFamily) {
  const nowMs = performance.now();
  if (nowMs - (T._cool[key] || 0) < 60) return;
  T._cool[key] = nowMs;
  T.ensure();
  opts = opts || {};
  const ctx = T.ctx;
  /* every performance gets its own bus, so it can be stopped without touching the rest */
  const bus = ctx.createGain();
  /* placement sits on the bus, not on the voices, so a looping cue's repetitions
     - which re-run through this same bus - inherit it without rescheduling. */
  const xyz = validPos(opts.pos);
  const pan = xyz ? 0 : clampPan(opts.pan);
  let place = null;
  if (xyz) {
    place = ctx.createPanner();
    place.panningModel = "HRTF";
    place.distanceModel = "inverse";
    place.refDistance = 1;
    place.rolloffFactor = 1;
    if (place.positionX) { place.positionX.value = xyz[0]; place.positionY.value = xyz[1]; place.positionZ.value = xyz[2]; }
    else place.setPosition(xyz[0], xyz[1], xyz[2]); /* older Safari */
  } else if (pan) {
    place = ctx.createStereoPanner();
    place.pan.value = pan;
  }
  if (place) { bus.connect(place); place.connect(T.dry); } else bus.connect(T.dry);
  /* the reverb send stays center and unpanned on purpose: rooms don't pan, sources
     do. A tail that swings with the source reads as the walls moving, not the button. */
  const sendBus = ctx.createGain(); sendBus.connect(T.verb);

  function once() {
    const t0 = ctx.currentTime + 0.015;
    const prevT = T.settings.transpose;
    /* humanization: +/-30 cents and +/-8% level per performance - whole cue shifts together */
    const drift = Math.random() * 0.6 - 0.3;
    T.settings.transpose = prevT + (opts.pitch || 0) + drift;
    T._scale = (opts.volume != null ? opts.volume : 1) * (0.92 + Math.random() * 0.16);
    T._bus = bus; T._sendBus = sendBus;
    runSpec(spec, t0);
    T._bus = null; T._sendBus = null;
    T._scale = 1;
    T.settings.transpose = prevT;
  }
  once();

  let iv = null;
  if (opts.loop) {
    const period = ((opts.every != null ? opts.every : specDuration(spec)) + 0.06) * 1000;
    iv = setInterval(() => { if (loopAudible()) once(); }, Math.max(80, period));
  }
  emit("play", { name: emitName, family: emitFamily });

  let stopped = false;
  return {
    stop() {
      if (stopped) return;
      stopped = true;
      if (iv) clearInterval(iv);
      const t = ctx.currentTime;
      bus.gain.setTargetAtTime(0, t, 0.02);
      sendBus.gain.setTargetAtTime(0, t, 0.02);
      setTimeout(() => { try { bus.disconnect(); sendBus.disconnect(); if (place) place.disconnect(); } catch (e) { /* already gone */ } }, 300);
    },
  };
}

/** Play a cue by name. Options: { pitch, volume, loop, every, pan, pos }.
    Returns a handle: { stop() }. With loop: true the cue repeats (spaced by its own
    duration, or opts.every seconds) until stopped - for loading states.
    pan (-1..1) places it in the stereo field; pos ([x,y,z]) places it in 3D and
    wins over pan. Both are fixed for the life of the performance. */
export function play(name, opts) {
  const cue = CUES[name];
  if (!cue) return;
  return perform(name, effectiveSpec(name), opts, name, cue.cat);
}

/** Play a custom spec (array of layers). It is normalized/clamped first.
    Options: { pitch, volume, pan, pos, id } - id keys the 60ms cooldown (default "custom"). */
export function playSpec(spec, opts) {
  const s = normalizeSpec(spec);
  if (!s.length) return;
  const id = (opts && opts.id) || "custom";
  return perform("spec:" + id, s, opts, id, null);
}

/** Wire every data-foley-* attribute under root (default: document).
    Attributes: data-foley-hover, -press, -release, -click, -toggle, -type. Safe to call again.
    Delegated, so markup added later - modals, routes, list items - is covered too:
    call this once at startup and never think about it again.
    With set({ localize }) nonzero, every cue is panned to its element's place on screen. */
export function bind(root) {
  root = root || document;
  /* one delegated listener set per root. Binding both a subtree and the document
     would double-fire, but the 60ms cooldown swallows the duplicate. */
  if (root._fyBound) return;
  root._fyBound = 1;

  /* the nearest ancestor of the event target carrying this attribute, if any.
     Attribute names stay literal here so the docs guards can enumerate them. */
  const hit = (e, sel) => (e.target && e.target.closest) ? e.target.closest(sel) : null;
  const at = (el, attr, fallback, opts) =>
    play(el.getAttribute(attr) || fallback, Object.assign({ pan: panFor(el) }, opts));

  root.addEventListener("pointerdown", (e) => {
    const el = hit(e, "[data-foley-press]");
    if (el) at(el, "data-foley-press", "press");
  });
  root.addEventListener("pointerup", (e) => {
    const el = hit(e, "[data-foley-release]");
    if (el) at(el, "data-foley-release", "release");
  });
  root.addEventListener("click", (e) => {
    const c = hit(e, "[data-foley-click]");
    if (c) at(c, "data-foley-click", "tap");
    const t = hit(e, "[data-foley-toggle]");   /* an element may carry both; both should sound */
    if (t) play(t.getAttribute("aria-pressed") === "true" ? "on" : "off", { pan: panFor(t) });
  });
  root.addEventListener("keydown", (e) => {
    const el = hit(e, "[data-foley-type]");
    if (!el) return;
    if (e.key === "Enter") { play("complete", { pan: panFor(el) }); return; }
    if (e.key.length === 1 || e.key === "Backspace") at(el, "data-foley-type", "thock", { pitch: (Math.random() * 2 - 1) });
  });

  /* hover is the one event that resists delegation: pointerenter doesn't bubble, so
     we listen to pointerover and fire only when the matched element actually changes
     - sliding across a button's own children must stay silent. pointerout clears the
     latch only when the pointer leaves the element entirely, not for a child. */
  let hovered = null;
  root.addEventListener("pointerover", (e) => {
    const el = hit(e, "[data-foley-hover]");
    if (el === hovered) return;
    hovered = el;
    if (el && T.settings.hover) at(el, "data-foley-hover", "tick");
  });
  root.addEventListener("pointerout", (e) => {
    if (hovered && !hovered.contains(e.relatedTarget)) hovered = null;
  });
  /* keyboard users get the same cue: focusin bubbles where focus does not */
  root.addEventListener("focusin", (e) => {
    const el = hit(e, "[data-foley-hover]");
    if (el && T.settings.hover) at(el, "data-foley-hover", "tick");
  });

  /* first gesture anywhere unlocks audio */
  ["pointerdown", "keydown"].forEach((ev) =>
    document.addEventListener(ev, () => T.ensure(), { once: true, capture: true })
  );
}

/* ---------------- observing the DOM itself ----------------
   bind() covers what the user does. This covers what the interface does on its
   own: a toast arriving, a dialog leaving, a drawer flipping aria-expanded. One
   MutationObserver per root, and opt-in rather than folded into bind(), because
   it watches for the life of the page and most apps only want click sounds.

   Only state attributes are watched, never class - class churns on every hover
   and focus, which would turn the page into a rattle. */
const STATE_ATTRS = ["aria-expanded", "aria-selected", "aria-checked", "aria-pressed", "open", "data-state"];

/** Sound elements that appear, leave, or change state under root (default: document).
    Attributes: data-foley-enter, data-foley-exit, data-foley-change.
    Only fires for changes after this call, so the initial render stays silent.
    Returns a function that stops observing; calling again on the same root is a no-op. */
export function observe(root) {
  root = root || document;
  if (root._fyObserve) return root._fyObserve;
  if (typeof MutationObserver === "undefined") return () => {}; /* SSR, old engines */

  const sound = (el, attr, fallback, pan) =>
    play(el.getAttribute(attr) || fallback, { pan });
  /* a subtree is reported by its root only, so the match may be nested inside */
  const each = (node, sel, fn) => {
    if (!node || node.nodeType !== 1) return; /* text nodes, comments */
    if (node.matches(sel)) fn(node);
    node.querySelectorAll(sel).forEach(fn);
  };

  const obs = new MutationObserver((records) => {
    for (const r of records) {
      if (r.type === "attributes") {
        if (r.target.hasAttribute("data-foley-change")) {
          sound(r.target, "data-foley-change", "switch", panFor(r.target));
        }
        continue;
      }
      r.addedNodes.forEach((n) => each(n, "[data-foley-enter]", (el) =>
        sound(el, "data-foley-enter", "bubble", panFor(el))));
      /* a removed node is already detached, so getBoundingClientRect reads all
         zeros and panFor would hard-pan every exit to the left. Exits stay center. */
      r.removedNodes.forEach((n) => each(n, "[data-foley-exit]", (el) =>
        sound(el, "data-foley-exit", "whoosh", 0)));
    }
  });
  obs.observe(root === document ? document.documentElement : root, {
    childList: true, subtree: true, attributes: true, attributeFilter: STATE_ATTRS,
  });

  /* a list rendering 100 rows fires 100 enters; the 60ms per-cue cooldown in
     perform() collapses them to one, which is why this needs no throttle here. */
  const stop = () => { obs.disconnect(); root._fyObserve = null; };
  root._fyObserve = stop;
  return stop;
}

/* ---------------- offline render & WAV export ---------------- */

function renderSpecOffline(spec) {
  const rate = 44100;
  const off = new OfflineAudioContext(2, Math.ceil(rate * 2.8), rate);
  /* temporarily point the engine at the offline graph; scheduling is synchronous */
  const saved = { ctx: T.ctx, dry: T.dry, verb: T.verb, wet: T.wet, master: T.master, noise: T._noise };
  T.ctx = off; T._noise = null;
  T.master = off.createGain(); T.master.gain.value = 1;
  const lim = off.createDynamicsCompressor();
  lim.threshold.value = -10; lim.knee.value = 4; lim.ratio.value = 12;
  lim.attack.value = 0.002; lim.release.value = 0.12;
  T.master.connect(lim); lim.connect(off.destination);
  T.dry = off.createGain(); T.dry.connect(T.master);
  T.verb = off.createConvolver(); T.verb.buffer = T.makeIR(1.4, 3.2);
  T.wet = off.createGain(); T.wet.gain.value = T.settings.space;
  T.verb.connect(T.wet); T.wet.connect(T.master);
  try { runSpec(spec, 0.03); }
  finally {
    T.ctx = saved.ctx; T.dry = saved.dry; T.verb = saved.verb;
    T.wet = saved.wet; T.master = saved.master; T._noise = saved.noise;
  }
  return off.startRendering();
}

/** Offline-render a cue to an AudioBuffer, honoring the current transpose, space, and theme.
    Deterministic: no humanization drift. For envelopes, meters, or custom encoding. */
export async function toBuffer(name) {
  const cue = CUES[name];
  if (!cue) return null;
  return renderSpecOffline(effectiveSpec(name));
}

/** Offline-render a custom spec to an AudioBuffer (normalized first). */
export async function toBufferSpec(spec) {
  const s = normalizeSpec(spec);
  if (!s.length) return null;
  return renderSpecOffline(s);
}

/** Render a cue to a 16-bit 44.1kHz stereo WAV Blob, honoring the current transpose, space, and theme.
    Deterministic: no humanization drift is applied to exports. */
export async function toWav(name) {
  const buf = await toBuffer(name);
  if (!buf) return null;
  return encodeWav(trimAndNormalize(buf), 44100);
}

/** Render a custom spec to a WAV Blob (normalized first). */
export async function toWavSpec(spec) {
  const buf = await toBufferSpec(spec);
  if (!buf) return null;
  return encodeWav(trimAndNormalize(buf), 44100);
}

/** Render all 28 cues into one audio sprite: a single WAV Blob plus a map of
    { name: { start, duration } } offsets in seconds. gap defaults to 50ms. */
export async function toSprite(gap) {
  const g = gap != null ? gap : 0.05;
  const rate = 44100;
  const parts = [], map = {};
  let cursor = 0;
  for (const name of Object.keys(CUES)) {
    const buf = await renderSpecOffline(effectiveSpec(name));
    const t = trimAndNormalize(buf);
    map[name] = { start: +cursor.toFixed(4), duration: +(t.length / rate).toFixed(4) };
    parts.push(t);
    cursor += t.length / rate + g;
  }
  const total = Math.ceil(cursor * rate);
  const left = new Float32Array(total), right = new Float32Array(total);
  let o = 0;
  for (let i = 0; i < parts.length; i++) {
    left.set(parts[i].left, o);
    right.set(parts[i].right, o);
    o += parts[i].length + Math.round(g * rate);
  }
  return { blob: encodeWav({ left, right, length: total }, rate), map };
}

function trimAndNormalize(buf) {
  const Lc = buf.getChannelData(0), R = buf.getChannelData(1);
  let end = 0, peak = 0;
  for (let i = 0; i < Lc.length; i++) {
    const m = Math.max(Math.abs(Lc[i]), Math.abs(R[i]));
    if (m > peak) peak = m;
    if (m > 0.002) end = i;
  }
  const len = Math.min(Lc.length, end + Math.floor(buf.sampleRate * 0.08));
  const scale = peak > 0 ? 0.891 / peak : 1; /* about -1 dBFS */
  return {
    left: Float32Array.prototype.slice.call(Lc, 0, len).map((v) => v * scale),
    right: Float32Array.prototype.slice.call(R, 0, len).map((v) => v * scale),
    length: len,
  };
}

function encodeWav(d, rate) {
  const n = d.length, bytes = 44 + n * 4;
  const ab = new ArrayBuffer(bytes), v = new DataView(ab);
  function str(o, x) { for (let i = 0; i < x.length; i++) v.setUint8(o + i, x.charCodeAt(i)); }
  str(0, "RIFF"); v.setUint32(4, bytes - 8, true); str(8, "WAVE");
  str(12, "fmt "); v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 2, true);
  v.setUint32(24, rate, true); v.setUint32(28, rate * 4, true); v.setUint16(32, 4, true); v.setUint16(34, 16, true);
  str(36, "data"); v.setUint32(40, n * 4, true);
  let o = 44;
  for (let i = 0; i < n; i++) {
    v.setInt16(o, Math.max(-1, Math.min(1, d.left[i])) * 0x7FFF, true); o += 2;
    v.setInt16(o, Math.max(-1, Math.min(1, d.right[i])) * 0x7FFF, true); o += 2;
  }
  return new Blob([ab], { type: "audio/wav" });
}
