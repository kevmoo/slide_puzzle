// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            AB: x0 => new Int16Array(x0),
      AC: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      AD: x0 => x0.getBoundingClientRect(),
      AE: x0 => x0.matches,
      AF: (x0,x1) => x0.exec(x1),
      AG: (x0,x1) => x0.add(x1),
      AH: (x0,x1) => x0.querySelector(x1),
      AI: (x0,x1) => { x0.decoding = x1 },
      AJ: x0 => x0.ctrlKey,
      B: s => printToConsole(s),
      BB: x0 => new Uint16Array(x0),
      BC: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      BD: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      BE: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      BF: x0 => x0.flags,
      BG: x0 => x0.data,
      BH: (x0,x1) => { x0.title = x1 },
      BI: (x0,x1) => { x0.crossOrigin = x1 },
      BJ: x0 => x0.isComposing,
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: x0 => new Int32Array(x0),
      CC: (x0,x1) => x0.querySelector(x1),
      CD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      CE: f => f.dartFunction,
      CF: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      CG: (x0,x1) => { x0.scrollTop = x1 },
      CH: (x0,x1) => x0.vibrate(x1),
      CI: (x0,x1) => x0.createObjectURL(x1),
      CJ: x0 => x0.code,
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      DC: (x0,x1) => x0.item(x1),
      DD: Date.now,
      DE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      DF: o => o instanceof RegExp,
      DG: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      DH: x0 => x0.arrayBuffer(),
      DI: x0 => x0.URL,
      DJ: x0 => x0.repeat,
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: x0 => new Uint32Array(x0),
      EC: x0 => x0.length,
      ED: (handle) => clearTimeout(handle),
      EE: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      EF: (a, s) => a.join(s),
      EG: (x0,x1) => { x0.value = x1 },
      EH: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      EI: x0 => new Blob(x0),
      EJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      F: () => new Error().stack,
      FB: x0 => new Float32Array(x0),
      FC: (x0,x1) => x0.querySelectorAll(x1),
      FD: (x0,x1) => x0.closest(x1),
      FE: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      FF: (x0,x1) => x0.error(x1),
      FG: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      FH: x0 => x0.status,
      FI: (x0,x1,x2) => x0.set(x1,x2),
      FJ: x0 => x0.length,
      G: s => JSON.stringify(s),
      GB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      GC: (x0,x1) => x0.getAttribute(x1),
      GD: x0 => x0.bottom,
      GE: (o, i) => o[i],
      GF: () => globalThis.console,
      GG: (x0,x1) => { x0.value = x1 },
      GH: (x0,x1) => x0.fetch(x1),
      GI: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      GJ: x0 => x0.getReader(),
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: x0 => new Float64Array(x0),
      HC: x0 => x0.remove(),
      HD: x0 => x0.top,
      HE: o => o.length,
      HF: s => s.trimRight(),
      HG: x0 => x0.index,
      HH: x0 => x0.content,
      HI: x0 => new window.ImageDecoder(x0),
      HJ: x0 => x0.value,
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      IC: (x0,x1) => x0.appendChild(x1),
      ID: x0 => x0.right,
      IE: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      IF: x0 => x0.blur(),
      IG: x0 => x0.unicode,
      IH: x0 => x0.document,
      II: x0 => x0.name,
      IJ: x0 => x0.done,
      J: (s, p, i) => s.lastIndexOf(p, i),
      JB: x0 => new ArrayBuffer(x0),
      JC: (x0,x1) => x0.append(x1),
      JD: x0 => x0.left,
      JE: x0 => x0.language,
      JF: x0 => x0.button,
      JG: (x0,x1) => { x0.lastIndex = x1 },
      JH: () => typeof dartUseDateNowForTicks !== "undefined",
      JI: x0 => x0.repetitionCount,
      JJ: x0 => x0.read(),
      K: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      KB: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      KC: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      KD: x0 => x0.clientY,
      KE: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      KF: x0 => x0.innerHeight,
      KG: x0 => x0.dotAll,
      KH: () => Date.now(),
      KI: x0 => x0.frameCount,
      KJ: x0 => x0.body,
      L: o => o === undefined,
      LB: (x0,x1,x2) => new DataView(x0,x1,x2),
      LC: x0 => x0.style,
      LD: x0 => x0.clientX,
      LE: () => globalThis.window.FinalizationRegistry,
      LF: x0 => x0.innerWidth,
      LG: x0 => x0.ignoreCase,
      LH: () => 1000 * performance.now(),
      LI: x0 => x0.selectedTrack,
      LJ: (x0,x1) => new OffscreenCanvas(x0,x1),
      M: o => String(o),
      MB: (o, p) => o[p],
      MC: x0 => x0.debugShowSemanticsNodes,
      MD: x0 => x0.changedTouches,
      ME: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      MF: x0 => x0.height,
      MG: x0 => x0.multiline,
      MH: x0 => new Uint8Array(x0),
      MI: x0 => x0.completed,
      MJ: x0 => x0.assetBase,
      N: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      NB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      NC: o => o,
      ND: x0 => x0.offsetY,
      NE: x0 => new window.FinalizationRegistry(x0),
      NF: x0 => x0.width,
      NG: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      NH: (x0,x1,x2) => x0.slice(x1,x2),
      NI: x0 => x0.ready,
      NJ: x0 => x0.loader,
      O: (x0,x1) => x0.didCreateEngineInitializer(x1),
      OB: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      OC: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      OD: x0 => x0.offsetX,
      OE: (x0,x1) => x0.unregister(x1),
      OF: x0 => x0.clientHeight,
      OG: x0 => x0.value,
      OH: (x0,x1) => x0.decode(x1),
      OI: x0 => x0.tracks,
      OJ: () => globalThis._flutter,
      P: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      PB: o => o.byteOffset,
      PC: (x0,x1) => x0.warn(x1),
      PD: x0 => x0.type,
      PE: (x0,x1) => x0.contains(x1),
      PF: x0 => x0.clientWidth,
      PG: x0 => x0.selectionDirection,
      PH: (x0,x1) => x0.adoptText(x1),
      PI: x0 => x0.close(),
      Q: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      QB: o => o.buffer,
      QC: x0 => x0.console,
      QD: x0 => x0.maxTouchPoints,
      QE: (s) => +s,
      QF: (x0,x1) => { x0.content = x1 },
      QG: x0 => x0.selectionStart,
      QH: x0 => x0.first(),
      QI: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      R: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      RB: Function.prototype.call.bind(DataView.prototype.getUint8),
      RC: () => globalThis.window,
      RD: x0 => x0.platform,
      RE: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      RF: (x0,x1) => { x0.name = x1 },
      RG: x0 => x0.selectionEnd,
      RH: x0 => x0.next(),
      RI: (x0,x1) => x0.decode(x1),
      S: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      SB: (b, o) => new DataView(b, o),
      SC: (o, c) => o instanceof c,
      SD: x0 => x0.body,
      SE: s => s.trim(),
      SF: x0 => x0.head,
      SG: x0 => x0.value,
      SH: x0 => x0.current(),
      SI: x0 => x0.displayHeight,
      T: x0 => new Promise(x0),
      TB: (b, o, l) => new DataView(b, o, l),
      TC: (string, token) => string.split(token),
      TD: () => globalThis.document,
      TE: x0 => x0.classList,
      TF: (x0,x1) => x0.removeChild(x1),
      TG: x0 => x0.selectionDirection,
      TH: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      TI: x0 => x0.displayWidth,
      U: (x0,x1,x2) => x0.call(x1,x2),
      UB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      UC: o => o instanceof Array,
      UD: (x0,x1,x2) => x0.addEventListener(x1,x2),
      UE: x0 => x0.preventDefault(),
      UF: x0 => x0.firstChild,
      UG: x0 => x0.selectionStart,
      UH: x0 => x0.v8BreakIterator,
      UI: x0 => x0.duration,
      V: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      VB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      VC: (a, i) => a[i],
      VD: x0 => x0.hasFocus(),
      VE: x0 => x0.parent,
      VF: x0 => x0.viewConstraints,
      VG: x0 => x0.selectionEnd,
      VH: () => globalThis.Intl,
      VI: x0 => x0.image,
      W: x0 => new Array(x0),
      WB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      WC: a => a.length,
      WD: x0 => x0.relatedTarget,
      WE: x0 => x0.timeStamp,
      WF: x0 => x0.hostElement,
      WG: x0 => x0.keyCode,
      WH: (x0,x1) => x0.segment(x1),
      WI: () => globalThis.window.ImageDecoder,
      X: o => [o],
      XB: (t, s) => t.set(s),
      XC: x0 => x0.userAgent,
      XD: x0 => x0.shiftKey,
      XE: (x0,x1) => x0.hasAttribute(x1),
      XF: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      XG: (x0,x1) => x0.scrollIntoView(x1),
      XH: x0 => x0.index,
      XI: (x0,x1,x2) => x0.insertBefore(x1,x2),
      Y: (o0, o1) => [o0, o1],
      YB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      YC: x0 => x0.navigator,
      YD: (decoder, codeUnits) => decoder.decode(codeUnits),
      YE: x0 => x0.buttons,
      YF: x0 => ({runApp: x0}),
      YG: x0 => x0.multiViewEnabled,
      YH: x0 => x0.next(),
      YI: x0 => x0.id,
      Z: (o0, o1, o2) => [o0, o1, o2],
      ZB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      ZC: Function.prototype.call.bind(String.prototype.toLowerCase),
      ZD: () => new TextDecoder("utf-8", {fatal: true}),
      ZE: x0 => x0.ctrlKey,
      ZF: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      ZG: (x0,x1) => x0.replaceWith(x1),
      ZH: x0 => x0.value,
      ZI: x0 => x0.offsetHeight,
      a: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      aB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      aC: Object.is,
      aD: () => new TextDecoder("utf-8", {fatal: false}),
      aE: x0 => x0.y,
      aF: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      aG: (x0,x1) => { x0.type = x1 },
      aH: x0 => x0.done,
      aI: x0 => x0.offsetWidth,
      b: (x0,x1,x2) => { x0[x1] = x2 },
      bB: Function.prototype.call.bind(DataView.prototype.getUint32),
      bC: x0 => x0.vendor,
      bD: (a, i, v) => a[i] = v,
      bE: x0 => x0.x,
      bF: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      bG: (x0,x1) => { x0.className = x1 },
      bH: (o, m, a) => o[m].apply(o, a),
      bI: x0 => x0.stopPropagation(),
      c: o => o,
      cB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      cC: (x0,x1) => x0.createTextNode(x1),
      cD: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      cE: x0 => x0.scrollTop,
      cF: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      cG: (x0,x1) => { x0.tabIndex = x1 },
      cH: x0 => x0.iterator,
      cI: x0 => x0.disabled,
      d: (o, p) => o[p],
      dB: Function.prototype.call.bind(DataView.prototype.getInt32),
      dC: (x0,x1) => { x0.id = x1 },
      dD: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      dE: x0 => x0.offsetTop,
      dF: x0 => x0.history,
      dG: (x0,x1) => { x0.name = x1 },
      dH: () => globalThis.Symbol,
      dI: (x0,x1) => { x0.min = x1 },
      e: () => globalThis,
      eB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      eC: (x0,x1) => { x0.nonce = x1 },
      eD: x0 => x0.visibilityState,
      eE: x0 => x0.scrollLeft,
      eF: x0 => x0.search,
      eG: (x0,x1) => { x0.placeholder = x1 },
      eH: (x0,x1) => new Intl.Segmenter(x0,x1),
      eI: (x0,x1) => { x0.max = x1 },
      f: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      fB: o => o instanceof Uint16Array,
      fC: x0 => x0.nonce,
      fD: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      fE: x0 => x0.offsetLeft,
      fF: x0 => x0.location,
      fG: (x0,x1) => { x0.autocomplete = x1 },
      fH: x0 => x0.Segmenter,
      fI: (x0,x1) => { x0.disabled = x1 },
      g: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gB: Function.prototype.call.bind(DataView.prototype.getUint16),
      gC: () => globalThis.window.flutterConfiguration,
      gD: x0 => x0.disconnect(),
      gE: x0 => x0.offsetParent,
      gF: x0 => x0.pathname,
      gG: (x0,x1) => { x0.name = x1 },
      gH: x0 => x0.buffer,
      gI: (x0,x1) => { x0.scrollLeft = x1 },
      h: (x0,x1) => ({addView: x0,removeView: x1}),
      hB: o => o instanceof Int16Array,
      hC: (x0,x1) => x0.attachShadow(x1),
      hD: x0 => new Intl.Locale(x0),
      hE: (o, p, r) => o.replaceAll(p, () => r),
      hF: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      hG: (x0,x1) => { x0.placeholder = x1 },
      hH: x0 => x0.wasmMemory,
      hI: (x0,x1) => { x0.spellcheck = x1 },
      i: (l, r) => l === r,
      iB: Function.prototype.call.bind(DataView.prototype.getInt16),
      iC: (x0,x1) => x0.createElement(x1),
      iD: x0 => x0.region,
      iE: x0 => x0.deltaMode,
      iF: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      iG: (x0,x1) => { x0.action = x1 },
      iH: () => globalThis.window._flutter_skwasmInstance,
      iI: (x0,x1) => { x0.disabled = x1 },
      j: x0 => x0.random(),
      jB: o => o instanceof Uint8ClampedArray,
      jC: x0 => x0.scale,
      jD: x0 => x0.script,
      jE: x0 => x0.deltaY,
      jF: o => Object.keys(o),
      jG: (x0,x1) => { x0.method = x1 },
      jH: () => new TextDecoder(),
      jI: x0 => x0.debugSkipFontRetryDelay,
      k: o => o,
      kB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      kC: x0 => x0.visualViewport,
      kD: x0 => x0.language,
      kE: x0 => x0.deltaX,
      kF: x0 => x0.state,
      kG: (x0,x1) => { x0.noValidate = x1 },
      kH: (a, i) => a.splice(i, 1),
      kI: x0 => x0.fontFallbackBaseUrl,
      l: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      lB: Function.prototype.call.bind(DataView.prototype.setInt32),
      lC: x0 => x0.devicePixelRatio,
      lD: x0 => x0.languages,
      lE: x0 => x0.wheelDeltaY,
      lF: x0 => x0.hash,
      lG: (x0,x1) => x0.removeAttribute(x1),
      lH: a => a.pop(),
      lI: (x0,x1) => x0.transferFromImageBitmap(x1),
      m: () => globalThis.Math,
      mB: Function.prototype.call.bind(DataView.prototype.setUint32),
      mC: x0 => x0.height,
      mD: (x0,x1) => x0.observe(x1),
      mE: x0 => x0.wheelDeltaX,
      mF: x0 => x0.state,
      mG: x0 => x0.isConnected,
      mH: (map, o, v) => map.set(o, v),
      mI: (x0,x1) => x0.getContext(x1),
      n: (x0,x1) => x0.prepend(x1),
      nB: Function.prototype.call.bind(DataView.prototype.setInt16),
      nC: x0 => x0.width,
      nD: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      nE: x0 => x0.key,
      nF: (x0,x1) => x0.go(x1),
      nG: x0 => x0.click(),
      nH: (map, o) => map.get(o),
      nI: (x0,x1) => { x0.height = x1 },
      o: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      oB: Function.prototype.call.bind(DataView.prototype.setUint16),
      oC: x0 => x0.screen,
      oD: x0 => new ResizeObserver(x0),
      oE: x0 => x0.pressure,
      oF: x0 => x0.parentElement,
      oG: (x0,x1) => x0.getElementsByClassName(x1),
      oH: () => new WeakMap(),
      oI: (x0,x1) => { x0.width = x1 },
      p: b => !!b,
      pB: Function.prototype.call.bind(DataView.prototype.setUint8),
      pC: (string, times) => string.repeat(times),
      pD: (x0,x1) => x0.getPropertyValue(x1),
      pE: x0 => x0.tiltY,
      pF: (x0,x1) => x0.querySelectorAll(x1),
      pG: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      pH: x0 => new WeakRef(x0),
      pI: x0 => x0.height,
      q: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      qB: Function.prototype.call.bind(DataView.prototype.setInt8),
      qC: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      qD: x0 => globalThis.parseFloat(x0),
      qE: x0 => x0.tiltX,
      qF: (x0,x1) => x0.requestAnimationFrame(x1),
      qG: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      qH: x0 => x0.deref(),
      qI: x0 => x0.width,
      r: (x0,x1) => x0.focus(x1),
      rB: Function.prototype.call.bind(DataView.prototype.getInt8),
      rC: x0 => x0.tabIndex,
      rD: (x0,x1) => x0.getComputedStyle(x1),
      rE: x0 => x0.pointerType,
      rF: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      rG: (x0,x1) => x0.dispatchEvent(x1),
      rH: () => globalThis.WeakRef,
      rI: x0 => x0.rasterEndMilliseconds,
      s: () => ({}),
      sB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      sC: (x0,x1) => x0.contains(x1),
      sD: x0 => x0.documentElement,
      sE: x0 => x0.pointerId,
      sF: x0 => x0.now(),
      sG: (x0,x1) => x0.createEvent(x1),
      sH: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      sI: x0 => x0.rasterStartMilliseconds,
      t: (o, p, v) => o[p] = v,
      tB: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      tC: x0 => x0.activeElement,
      tD: x0 => x0.computedStyleMap(),
      tE: x0 => x0.getCoalescedEvents(),
      tF: x0 => x0.performance,
      tG: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      tH: (a, s, e) => a.slice(s, e),
      tI: x0 => x0.imageBitmaps,
      u: () => [],
      uB: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      uC: x0 => x0.parentNode,
      uD: (x0,x1) => x0.get(x1),
      uE: (x0,x1) => x0.getModifierState(x1),
      uF: (d, digits) => d.toFixed(digits),
      uG: x0 => x0.readText(),
      uH: (x0,x1) => x0.revokeObjectURL(x1),
      uI: x0 => x0.canvasKitMaximumSurfaces,
      v: (a, i) => a.push(i),
      vB: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      vC: x0 => x0.tagName,
      vD: (o, p) => p in o,
      vE: s => s.trimLeft(),
      vF: x0 => x0.maxHeight,
      vG: x0 => x0.clipboard,
      vH: (x0,x1) => { x0.src = x1 },
      vI: x0 => x0.hostElement,
      w: x0 => new Int8Array(x0),
      wB: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      wC: x0 => x0.target,
      wD: (x0,x1) => { x0.textContent = x1 },
      wE: s => s.toUpperCase(),
      wF: x0 => x0.maxWidth,
      wG: (x0,x1) => x0.writeText(x1),
      wH: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      wI: x0 => x0.location,
      x: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      xB: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      xC: x0 => x0.clientY,
      xD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      xE: (x0,x1) => x0.test(x1),
      xF: x0 => x0.minHeight,
      xG: x0 => x0.unlock(),
      xH: x0 => x0.naturalHeight,
      xI: (x0,x1) => x0.getModifierState(x1),
      y: x0 => new Uint8Array(x0),
      yB: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      yC: x0 => x0.clientX,
      yD: x0 => x0.matches,
      yE: (x0,x1) => x0[x1],
      yF: x0 => x0.minWidth,
      yG: (x0,x1) => x0.lock(x1),
      yH: x0 => x0.naturalWidth,
      yI: x0 => x0.metaKey,
      z: x0 => new Uint8ClampedArray(x0),
      zB: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      zC: (x0,x1,x2) => x0.setAttribute(x1,x2),
      zD: (x0,x1) => x0.matchMedia(x1),
      zE: x0 => x0.length,
      zF: (x0,x1) => x0.removeProperty(x1),
      zG: x0 => x0.orientation,
      zH: x0 => x0.decode(),
      zI: x0 => x0.altKey,

    };

    const baseImports = {
      _: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
