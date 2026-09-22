'use strict';

const test = require('node:test');
const assert = require('node:assert');

const m = require('./exportar-evidencias.js');

// ------------------------------------------------------------ ehComandoDeTeste

test('ehComandoDeTeste reconhece "&" com caminho entre aspas terminado em dart.exe', () => {
  assert.equal(m.ehComandoDeTeste('& "C:/SDK com espacos/bin/dart.exe" test'), true);
});

test('ehComandoDeTeste reconhece "&" com caminho entre aspas terminado em flutter.bat', () => {
  assert.equal(m.ehComandoDeTeste('& "C:/SDK com espacos/bin/flutter.bat" test'), true);
});

test('ehComandoDeTeste reconhece caminho entre aspas sem "&" terminado em dart.exe', () => {
  assert.equal(m.ehComandoDeTeste('"C:/SDK com espacos/bin/dart.exe" test'), true);
});

test('ehComandoDeTeste reconhece flutter.bat test sem aspas', () => {
  assert.equal(m.ehComandoDeTeste('bin/flutter.bat test'), true);
});

test('ehComandoDeTeste reconhece dart test no Linux', () => {
  assert.equal(m.ehComandoDeTeste('dart test'), true);
});

test('ehComandoDeTeste reconhece flutter test no Linux', () => {
  assert.equal(m.ehComandoDeTeste('flutter test'), true);
});

test('ehComandoDeTeste rejeita git commit -m "dart test"', () => {
  assert.equal(m.ehComandoDeTeste('git commit -m "dart test"'), false);
});

test('ehComandoDeTeste rejeita echo dart test', () => {
  assert.equal(m.ehComandoDeTeste('echo dart test'), false);
});

test('ehComandoDeTeste rejeita analyze', () => {
  assert.equal(m.ehComandoDeTeste('analyze'), false);
});

test('ehComandoDeTeste rejeita pub get', () => {
  assert.equal(m.ehComandoDeTeste('pub get'), false);
});

test('ehComandoDeTeste rejeita dart test citado num commit', () => {
  assert.equal(m.ehComandoDeTeste('git commit -am "roda dart test"'), false);
});

// ------------------------------------------------------ resultado de compilação Dart

test('resultadoDeTeste: "Failed to load" é vermelho mesmo com exit 0 no pipe', () => {
  const r = m.resultadoDeTeste(
    'Failed to load "C:/projeto/test/x_test.dart":\n  compilação quebrada\n+0: Some tests failed',
    0, undefined);
  assert.equal(r.vermelho, true);
  assert.equal(r.verde, false);
});

test('resultadoDeTeste: "Some tests failed" é vermelho mesmo com exit 0', () => {
  const r = m.resultadoDeTeste('+1 -0: Some tests failed', 0, undefined);
  assert.equal(r.vermelho, true);
  assert.equal(r.verde, false);
});

test('resultadoDeTeste: "All tests passed" com exit 0 é verde', () => {
  const r = m.resultadoDeTeste('+5 -0: All tests passed', 0, undefined);
  assert.equal(r.vermelho, false);
  assert.equal(r.verde, true);
});

test('resultadoDeTeste: exit 1 é vermelho e não verde', () => {
  const r = m.resultadoDeTeste('+3 -0: All tests passed', 1, undefined);
  assert.equal(r.vermelho, true);
  assert.equal(r.verde, false);
});