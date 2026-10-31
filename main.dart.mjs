// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(
      await _compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

let _isCompileStreamingSupported;
async function _compileStreaming(source, builtins) {
  _isCompileStreamingSupported ??= WebAssembly.compileStreaming(
    new Response(
      new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),
      {headers: {'Content-Type': 'application/wasm'}},
    ),
    builtins,
  ).then(() => false, (e) => e instanceof WebAssembly.CompileError);
  if (await _isCompileStreamingSupported) {
    return WebAssembly.compileStreaming(source, builtins);
  }
  return WebAssembly.compile(await (await source).arrayBuffer(), builtins);
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
      AD: (x0,x1,x2) => x0.setAttribute(x1,x2),
      AE: x0 => x0.language,
      AF: x0 => x0.flags,
      AG: (d, digits) => d.toFixed(digits),
      AH: x0 => x0.arrayBuffer(),
      AI: (x0,x1) => x0.createImageBitmap(x1),
      AJ: x0 => x0.isComposing,
      B: s => printToConsole(s),
      BB: x0 => new Uint16Array(x0),
      BC: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      BD: (x0,x1) => x0.closest(x1),
      BE: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      BF: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      BG: x0 => x0.maxHeight,
      BH: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      BI: x0 => new Blob(x0),
      BJ: x0 => x0.code,
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: x0 => new Int32Array(x0),
      CC: (x0,x1) => x0.querySelector(x1),
      CD: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      CE: () => globalThis.window.FinalizationRegistry,
      CF: o => o instanceof RegExp,
      CG: x0 => x0.maxWidth,
      CH: x0 => x0.status,
      CI: x0 => x0.close(),
      CJ: x0 => x0.repeat,
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      DC: (x0,x1) => x0.item(x1),
      DD: (handle) => clearTimeout(handle),
      DE: x0 => new window.FinalizationRegistry(x0),
      DF: (x0,x1) => x0.error(x1),
      DG: x0 => x0.minHeight,
      DH: (x0,x1) => x0.fetch(x1),
      DI: x0 => x0.naturalHeight,
      DJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
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
      ED: x0 => x0.maxTouchPoints,
      EE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      EF: () => globalThis.console,
      EG: x0 => x0.minWidth,
      EH: x0 => x0.content,
      EI: x0 => x0.naturalWidth,
      EJ: x0 => x0.userAgent,
      F: o => String(o),
      FB: x0 => new Float32Array(x0),
      FC: (x0,x1) => x0.querySelectorAll(x1),
      FD: x0 => x0.platform,
      FE: (x0,x1) => x0.unregister(x1),
      FF: s => s.trimRight(),
      FG: (x0,x1) => x0.removeProperty(x1),
      FH: x0 => x0.document,
      FI: (x0,x1) => { x0.src = x1 },
      FJ: x0 => x0.navigator,
      G: () => new Error().stack,
      GB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      GC: (x0,x1) => x0.getAttribute(x1),
      GD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      GE: x0 => x0.preventDefault(),
      GF: x0 => x0.blur(),
      GG: (x0,x1) => x0.add(x1),
      GH: () => typeof dartUseDateNowForTicks !== "undefined",
      GI: x0 => x0.displayHeight,
      GJ: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      H: s => JSON.stringify(s),
      HB: x0 => new Float64Array(x0),
      HC: x0 => x0.remove(),
      HD: Date.now,
      HE: x0 => x0.parent,
      HF: (x0,x1) => x0.setPointerCapture(x1),
      HG: x0 => x0.data,
      HH: () => Date.now(),
      HI: x0 => x0.displayWidth,
      HJ: () => globalThis.window,
      I: Function.prototype.call.bind(Number.prototype.toString),
      IB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      IC: (x0,x1) => x0.appendChild(x1),
      ID: (x0,x1) => x0.contains(x1),
      IE: x0 => x0.timeStamp,
      IF: x0 => x0.button,
      IG: (x0,x1) => x0.removeAttribute(x1),
      IH: () => 1000 * performance.now(),
      II: x0 => x0.duration,
      IJ: x0 => x0.extraAssets,
      J: Function.prototype.call.bind(String.prototype.indexOf),
      JB: x0 => new ArrayBuffer(x0),
      JC: (x0,x1) => x0.append(x1),
      JD: (decoder, codeUnits) => decoder.decode(codeUnits),
      JE: (x0,x1) => x0.hasAttribute(x1),
      JF: (x0,x1) => x0.prepend(x1),
      JG: (x0,x1) => { x0.value = x1 },
      JH: (x0,x1) => x0.decode(x1),
      JI: (x0,x1) => x0.decode(x1),
      JJ: x0 => x0.fontManifest,
      K: (s, p, i) => s.lastIndexOf(p, i),
      KB: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      KC: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      KD: () => new TextDecoder("utf-8", {fatal: true}),
      KE: x0 => x0.type,
      KF: x0 => x0.parentElement,
      KG: (x0,x1) => { x0.value = x1 },
      KH: (x0,x1,x2) => x0.slice(x1,x2),
      KI: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      KJ: x0 => x0.assetManifest,
      L: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      LB: (x0,x1,x2) => new DataView(x0,x1,x2),
      LC: x0 => x0.style,
      LD: () => new TextDecoder("utf-8", {fatal: false}),
      LE: (x0,x1) => x0.getModifierState(x1),
      LF: x0 => x0.innerHeight,
      LG: x0 => x0.value,
      LH: x0 => new Uint8Array(x0),
      LI: x0 => x0.image,
      LJ: x0 => x0.buildConfig,
      M: o => o === undefined,
      MB: (o, p) => o[p],
      MC: x0 => x0.debugShowSemanticsNodes,
      MD: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      ME: x0 => x0.buttons,
      MF: x0 => x0.innerWidth,
      MG: x0 => x0.selectionDirection,
      MH: (x0,x1) => x0.adoptText(x1),
      MI: x0 => x0.close(),
      MJ: x0 => x0.length,
      N: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      NB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      NC: o => o,
      ND: (s) => +s,
      NE: x0 => x0.ctrlKey,
      NF: x0 => x0.height,
      NG: x0 => x0.selectionStart,
      NH: x0 => x0.first(),
      NI: x0 => new window.ImageDecoder(x0),
      NJ: x0 => x0.getReader(),
      O: (x0,x1) => x0.didCreateEngineInitializer(x1),
      OB: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      OC: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      OD: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      OE: x0 => x0.getBoundingClientRect(),
      OF: x0 => x0.width,
      OG: x0 => x0.selectionEnd,
      OH: x0 => x0.next(),
      OI: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      OJ: x0 => x0.value,
      P: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      PB: o => o.byteOffset,
      PC: (x0,x1) => x0.warn(x1),
      PD: s => s.trim(),
      PE: x0 => x0.y,
      PF: x0 => x0.clientHeight,
      PG: x0 => x0.value,
      PH: x0 => x0.current(),
      PI: x0 => x0.name,
      PJ: x0 => x0.done,
      Q: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      QB: o => o.buffer,
      QC: x0 => x0.console,
      QD: x0 => x0.classList,
      QE: x0 => x0.x,
      QF: x0 => x0.clientWidth,
      QG: x0 => x0.selectionDirection,
      QH: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      QI: x0 => x0.repetitionCount,
      QJ: x0 => x0.read(),
      R: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      RB: Function.prototype.call.bind(DataView.prototype.getUint8),
      RC: () => globalThis.window,
      RD: x0 => x0.relatedTarget,
      RE: x0 => x0.top,
      RF: x0 => x0.isConnected,
      RG: x0 => x0.selectionStart,
      RH: x0 => x0.v8BreakIterator,
      RI: x0 => x0.frameCount,
      RJ: x0 => x0.body,
      S: x0 => new Promise(x0),
      SB: (b, o) => new DataView(b, o),
      SC: (o, c) => o instanceof c,
      SD: x0 => x0.hasFocus(),
      SE: x0 => x0.left,
      SF: x0 => x0.unicode,
      SG: x0 => x0.selectionEnd,
      SH: () => globalThis.Intl,
      SI: x0 => x0.selectedTrack,
      SJ: (x0,x1) => new OffscreenCanvas(x0,x1),
      T: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      TB: (b, o, l) => new DataView(b, o, l),
      TC: (string, token) => string.split(token),
      TD: x0 => x0.shiftKey,
      TE: x0 => x0.scrollTop,
      TF: x0 => x0.index,
      TG: (x0,x1) => { x0.name = x1 },
      TH: (x0,x1) => x0.segment(x1),
      TI: x0 => x0.completed,
      TJ: x0 => x0.assetBase,
      U: (x0,x1,x2) => x0.call(x1,x2),
      UB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      UC: (a, i) => a[i],
      UD: x0 => x0.body,
      UE: x0 => x0.offsetTop,
      UF: (x0,x1) => { x0.lastIndex = x1 },
      UG: (x0,x1) => { x0.placeholder = x1 },
      UH: x0 => x0.index,
      UI: x0 => x0.ready,
      UJ: x0 => x0.loader,
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
      VC: a => a.length,
      VD: x0 => x0.visibilityState,
      VE: x0 => x0.scrollLeft,
      VF: x0 => x0.dotAll,
      VG: (x0,x1) => { x0.autocomplete = x1 },
      VH: x0 => x0.next(),
      VI: x0 => x0.tracks,
      VJ: () => globalThis._flutter,
      W: x0 => new Array(x0),
      WB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      WC: o => o instanceof Array,
      WD: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      WE: x0 => x0.offsetLeft,
      WF: x0 => x0.ignoreCase,
      WG: (x0,x1) => { x0.type = x1 },
      WH: x0 => x0.value,
      WI: () => globalThis.window.ImageDecoder,
      X: o => [o],
      XB: (t, s) => t.set(s),
      XC: x0 => x0.userAgent,
      XD: x0 => x0.disconnect(),
      XE: x0 => x0.offsetParent,
      XF: x0 => x0.multiline,
      XG: (x0,x1) => { x0.name = x1 },
      XH: x0 => x0.done,
      XI: (x0,x1,x2) => x0.insertBefore(x1,x2),
      Y: (o0, o1) => [o0, o1],
      YB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      YC: x0 => x0.navigator,
      YD: x0 => new Intl.Locale(x0),
      YE: x0 => x0.offsetY,
      YF: x0 => x0.head,
      YG: (x0,x1) => { x0.placeholder = x1 },
      YH: (o, m, a) => o[m].apply(o, a),
      YI: x0 => x0.id,
      Z: (o0, o1, o2) => [o0, o1, o2],
      ZB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      ZC: Function.prototype.call.bind(String.prototype.toLowerCase),
      ZD: x0 => x0.region,
      ZE: x0 => x0.offsetX,
      ZF: (x0,x1) => { x0.content = x1 },
      ZG: (x0,x1) => { x0.scrollTop = x1 },
      ZH: x0 => x0.iterator,
      ZI: x0 => x0.offsetHeight,
      a: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      aB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      aC: Object.is,
      aD: x0 => x0.script,
      aE: (o, p, r) => o.replaceAll(p, () => r),
      aF: (x0,x1) => { x0.name = x1 },
      aG: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      aH: () => globalThis.Symbol,
      aI: x0 => x0.offsetWidth,
      b: (x0,x1,x2) => { x0[x1] = x2 },
      bB: Function.prototype.call.bind(DataView.prototype.getUint32),
      bC: x0 => x0.vendor,
      bD: x0 => x0.language,
      bE: x0 => x0.deltaMode,
      bF: (x0,x1) => x0.removeChild(x1),
      bG: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      bH: (x0,x1) => new Intl.Segmenter(x0,x1),
      bI: x0 => x0.stopPropagation(),
      c: o => o,
      cB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      cC: (x0,x1) => x0.createTextNode(x1),
      cD: x0 => x0.languages,
      cE: x0 => x0.deltaY,
      cF: x0 => x0.firstChild,
      cG: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      cH: x0 => x0.Segmenter,
      cI: x0 => x0.disabled,
      d: (o, p) => o[p],
      dB: Function.prototype.call.bind(DataView.prototype.getInt32),
      dC: (x0,x1) => { x0.id = x1 },
      dD: (x0,x1) => x0.observe(x1),
      dE: x0 => x0.deltaX,
      dF: x0 => x0.viewConstraints,
      dG: x0 => x0.keyCode,
      dH: x0 => x0.buffer,
      dI: (x0,x1) => { x0.min = x1 },
      e: () => globalThis,
      eB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      eC: (x0,x1) => { x0.nonce = x1 },
      eD: x0 => new ResizeObserver(x0),
      eE: x0 => x0.wheelDeltaY,
      eF: x0 => x0.hostElement,
      eG: (x0,x1) => x0.scrollIntoView(x1),
      eH: x0 => x0.wasmMemory,
      eI: (x0,x1) => { x0.max = x1 },
      f: (x0,x1) => ({addView: x0,removeView: x1}),
      fB: Function.prototype.call.bind(DataView.prototype.getUint16),
      fC: x0 => x0.nonce,
      fD: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      fE: x0 => x0.wheelDeltaX,
      fF: x0 => ({runApp: x0}),
      fG: x0 => x0.multiViewEnabled,
      fH: () => globalThis.window._flutter_skwasmInstance,
      fI: (x0,x1) => { x0.disabled = x1 },
      g: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gB: o => o instanceof Uint16Array,
      gC: () => globalThis.window.flutterConfiguration,
      gD: (x0,x1) => x0.getPropertyValue(x1),
      gE: x0 => x0.bottom,
      gF: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gG: (x0,x1) => x0.replaceWith(x1),
      gH: () => new TextDecoder(),
      gI: (x0,x1) => { x0.scrollLeft = x1 },
      h: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      hB: Function.prototype.call.bind(DataView.prototype.getInt16),
      hC: (x0,x1) => x0.attachShadow(x1),
      hD: x0 => globalThis.parseFloat(x0),
      hE: x0 => x0.right,
      hF: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      hG: (x0,x1) => { x0.className = x1 },
      hH: (a, i) => a.splice(i, 1),
      hI: (x0,x1) => { x0.spellcheck = x1 },
      i: (l, r) => l === r,
      iB: o => o instanceof Int16Array,
      iC: (x0,x1) => x0.createElement(x1),
      iD: (x0,x1) => x0.getComputedStyle(x1),
      iE: x0 => x0.clientY,
      iF: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      iG: (x0,x1) => { x0.tabIndex = x1 },
      iH: a => a.pop(),
      iI: (x0,x1) => { x0.disabled = x1 },
      j: x0 => x0.random(),
      jB: o => o instanceof Uint8ClampedArray,
      jC: x0 => x0.scale,
      jD: x0 => x0.documentElement,
      jE: x0 => x0.clientX,
      jF: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      jG: (x0,x1) => { x0.action = x1 },
      jH: (map, o, v) => map.set(o, v),
      jI: x0 => x0.debugSkipFontRetryDelay,
      k: o => o,
      kB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      kC: x0 => x0.visualViewport,
      kD: (x0,x1) => x0.get(x1),
      kE: x0 => x0.changedTouches,
      kF: x0 => x0.history,
      kG: (x0,x1) => { x0.method = x1 },
      kH: (map, o) => map.get(o),
      kI: x0 => x0.fontFallbackBaseUrl,
      l: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      lB: Function.prototype.call.bind(DataView.prototype.setInt32),
      lC: x0 => x0.devicePixelRatio,
      lD: x0 => x0.computedStyleMap(),
      lE: x0 => x0.key,
      lF: x0 => x0.search,
      lG: (x0,x1) => { x0.noValidate = x1 },
      lH: () => new WeakMap(),
      lI: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => x0.drawImage(x1,x2,x3,x4,x5,x6,x7,x8,x9),
      m: () => globalThis.Math,
      mB: Function.prototype.call.bind(DataView.prototype.setUint32),
      mC: x0 => x0.height,
      mD: (o, p) => p in o,
      mE: x0 => x0.identifier,
      mF: x0 => x0.location,
      mG: x0 => x0.click(),
      mH: x0 => new WeakRef(x0),
      mI: (x0,x1) => x0.getContext(x1),
      n: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      nB: Function.prototype.call.bind(DataView.prototype.setInt16),
      nC: x0 => x0.width,
      nD: (x0,x1) => { x0.textContent = x1 },
      nE: x0 => x0.touches,
      nF: x0 => x0.pathname,
      nG: (x0,x1) => x0.getElementsByClassName(x1),
      nH: x0 => x0.deref(),
      nI: (x0,x1) => { x0.height = x1 },
      o: b => !!b,
      oB: Function.prototype.call.bind(DataView.prototype.setUint16),
      oC: x0 => x0.screen,
      oD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      oE: x0 => x0.pressure,
      oF: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      oG: (x0,x1) => x0.dispatchEvent(x1),
      oH: () => globalThis.WeakRef,
      oI: (x0,x1) => { x0.width = x1 },
      p: () => globalThis.document,
      pB: Function.prototype.call.bind(DataView.prototype.setUint8),
      pC: (string, times) => string.repeat(times),
      pD: x0 => x0.matches,
      pE: x0 => x0.tiltY,
      pF: o => Object.keys(o),
      pG: (x0,x1) => x0.createEvent(x1),
      pH: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      pI: (x0,x1) => x0.transferFromImageBitmap(x1),
      q: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      qB: Function.prototype.call.bind(DataView.prototype.setInt8),
      qC: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      qD: (x0,x1) => x0.matchMedia(x1),
      qE: x0 => x0.tiltX,
      qF: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      qG: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      qH: (a, s, e) => a.slice(s, e),
      qI: x0 => x0.rasterEndMilliseconds,
      r: (x0,x1) => x0.focus(x1),
      rB: Function.prototype.call.bind(DataView.prototype.getInt8),
      rC: x0 => x0.tabIndex,
      rD: x0 => x0.matches,
      rE: x0 => x0.pointerType,
      rF: x0 => x0.state,
      rG: x0 => x0.readText(),
      rH: (x0,x1,x2,x3,x4) => x0.play(x1,x2,x3,x4),
      rI: x0 => x0.rasterStartMilliseconds,
      s: () => ({}),
      sB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      sC: (x0,x1) => x0.contains(x1),
      sD: f => f.dartFunction,
      sE: x0 => x0.pointerId,
      sF: x0 => x0.hash,
      sG: x0 => x0.clipboard,
      sH: (x0,x1) => x0.setTheme(x1),
      sI: x0 => x0.imageBitmaps,
      t: (o, p, v) => o[p] = v,
      tB: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      tC: x0 => x0.activeElement,
      tD: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      tE: x0 => x0.getCoalescedEvents(),
      tF: x0 => x0.state,
      tG: (x0,x1) => x0.writeText(x1),
      tH: (x0,x1) => x0.setMuted(x1),
      tI: x0 => x0.canvasKitMaximumSurfaces,
      u: () => [],
      uB: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      uC: x0 => x0.parentNode,
      uD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      uE: s => s.trimLeft(),
      uF: (x0,x1) => x0.go(x1),
      uG: x0 => x0.unlock(),
      uH: () => globalThis._slidePuzzleFoley,
      uI: x0 => x0.hostElement,
      v: (a, i) => a.push(i),
      vB: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      vC: x0 => x0.tagName,
      vD: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      vE: s => s.toUpperCase(),
      vF: (x0,x1) => x0.querySelectorAll(x1),
      vG: (x0,x1) => x0.lock(x1),
      vH: (x0,x1,x2) => x0.set(x1,x2),
      vI: x0 => x0.location,
      w: x0 => new Int8Array(x0),
      wB: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      wC: x0 => x0.target,
      wD: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      wE: (x0,x1) => x0.test(x1),
      wF: (x0,x1) => x0.requestAnimationFrame(x1),
      wG: x0 => x0.orientation,
      wH: x0 => x0.close(),
      wI: (x0,x1) => x0.getModifierState(x1),
      x: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      xB: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      xC: x0 => x0.clientY,
      xD: (o, i) => o[i],
      xE: (x0,x1) => x0[x1],
      xF: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      xG: (x0,x1) => x0.querySelector(x1),
      xH: x0 => x0.height,
      xI: x0 => x0.metaKey,
      y: x0 => new Uint8Array(x0),
      yB: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      yC: x0 => x0.clientX,
      yD: o => o.length,
      yE: x0 => x0.length,
      yF: x0 => x0.now(),
      yG: (x0,x1) => { x0.title = x1 },
      yH: x0 => x0.width,
      yI: x0 => x0.altKey,
      z: x0 => new Uint8ClampedArray(x0),
      zB: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      zC: (x0,x1,x2) => x0.addEventListener(x1,x2),
      zD: o => {
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
      zE: (x0,x1) => x0.exec(x1),
      zF: x0 => x0.performance,
      zG: (x0,x1) => x0.vibrate(x1),
      zH: (x0,x1,x2,x3,x4,x5) => x0.createImageBitmap(x1,x2,x3,x4,x5),
      zI: x0 => x0.ctrlKey,

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

    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
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
