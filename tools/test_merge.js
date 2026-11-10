/* Testa a juncao de dados (mergeShared / mergePrivate) direto do index.html.
   Uso: node tools/test_merge.js */
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const a = html.indexOf('/* ---------- Dados iniciais ---------- */');
const b = html.indexOf('/* ---------- Estado no aparelho ---------- */');
assert.ok(a > 0 && b > a, 'trecho do modelo de dados nao encontrado');
const head = "const WHO = {nana: 'Nana', dani: 'Dani'};" +
  "const plainText = s => String(s || '').normalize('NFD').toLowerCase().replace(/[^a-z0-9]/g, '');";
const api = new Function(head + html.slice(a, b) +
  'return {freshShared, freshPrivate, mergeShared, mergePrivate, sanitizeShared, sanitizePrivate};')();
const {freshShared, freshPrivate, mergeShared, mergePrivate, sanitizeShared} = api;
let t = 1000; const now = () => ++t;
const clone = o => JSON.parse(JSON.stringify(o));
let checks = 0; const ok = (c, m) => { assert.ok(c, m); checks++; };
const eq = (x, y, m) => { assert.deepStrictEqual(x, y, m); checks++; };

const N = freshShared(), D = freshShared();
/* checklist */
N.checklist.docs[0].done = true; N.checklist.docs[0].t = now();
N.checklist.mala.push({id: 'n1', text: 'Chapeu', done: false, t: now(), c: now()});
D.checklist.docs[1].done = true; D.checklist.docs[1].t = now();
D.ckDel[D.checklist.mala[2].id] = now(); D.checklist.mala.splice(2, 1);
/* roteiro: campos diferentes do mesmo dia */
N.itinerary[2].title = 'Mdina cedo'; N.itinerary[2].tt = now();
D.itinerary[2].note = 'Levar agua'; D.itinerary[2].tn = now(); D.itinerary[2].done = true; D.itinerary[2].td = now();
/* roteiro: mesmo campo, vence a mais recente */
N.itinerary[5].title = 'Gozo de manha'; N.itinerary[5].tt = now();
D.itinerary[5].title = 'Gozo a tarde'; D.itinerary[5].tt = now();
/* lugar do mapa: Nana tira do dia 1, Dani salva um lugar no dia 2 */
N.itinerary[0].place = null; N.itinerary[0].tp = now();
D.itinerary[1].place = {name: 'Upper Barrakka', lat: 35.89, lon: 14.51}; D.itinerary[1].tp = now();
/* tamanho da viagem: Dani adiciona um dia */
D.itinerary.push({title: 'Dia extra', tt: now(), note: '', tn: 0, done: false, td: 0, place: null, tp: 0}); D.days = {v: 22, t: now()};
/* diario, gastos, fotos, reservas */
N.diary['0'] = {nana: {note: 'Cheguei cansada', t: now()}}; D.diary['0'] = {dani: {note: 'Amei o hotel', t: now()}};
N.expenses.push({id: 'e1', desc: 'Ferry', eur: 20, payer: 'nana', cat: 'transporte', split: 50, at: now(), t: now()});
D.expenses.push({id: 'e2', desc: 'Jantar', eur: 60, payer: 'dani', cat: 'comida', split: 70, at: now(), t: now()});
N.photos.push({id: 'p1', day: 0, by: 'nana', at: now()}); D.photos.push({id: 'p2', day: 0, by: 'dani', at: now()});
N.res.push({id: 'r1', kind: 'voo', title: 'Voo de ida', code: 'ABC123', when: '2027-08-28', detail: '', files: [], at: now(), t: now()});

const AB = mergeShared(N, D), BA = mergeShared(D, N);
eq(AB, BA, 'a ordem da juncao nao pode mudar o resultado');
eq(mergeShared(AB, N), AB, 'juntar de novo nao pode mudar nada');
eq(mergeShared(AB, AB), AB);
ok(AB.checklist.docs[0].done && AB.checklist.docs[1].done, 'as duas marcacoes ficam');
ok(AB.checklist.mala.some(i => i.id === 'n1') && !AB.checklist.mala.some(i => i.id === 'mala-2'), 'item novo fica, apagado some');
eq([AB.itinerary[2].title, AB.itinerary[2].note, AB.itinerary[2].done], ['Mdina cedo', 'Levar agua', true]);
eq(AB.itinerary[5].title, 'Gozo a tarde');
eq(AB.itinerary[0].place, null); eq(AB.itinerary[1].place.name, 'Upper Barrakka');
ok(AB.itinerary[2].place && AB.itinerary[2].place.name === 'Mdina e Rabat', 'lugar original preservado');
eq(AB.itinerary.length, 22); eq(AB.itinerary[21].title, 'Dia extra');
eq([AB.diary['0'].nana.note, AB.diary['0'].dani.note], ['Cheguei cansada', 'Amei o hotel']);
eq(AB.expenses.length, 2); eq(AB.expenses.find(e => e.id === 'e2').split, 70);
eq(AB.photos.length, 2); eq(AB.res.length, 1);

/* edicao de gasto: a versao mais nova do mesmo id vence nos dois sentidos */
const E1 = clone(AB), E2 = clone(AB);
Object.assign(E1.expenses.find(e => e.id === 'e1'), {eur: 25, t: now()});
eq(mergeShared(E2, E1).expenses.find(e => e.id === 'e1').eur, 25);
eq(mergeShared(E1, E2).expenses.find(e => e.id === 'e1').eur, 25);
/* apagado nao ressuscita */
const X = clone(AB); X.expDel.e1 = now(); X.expenses = X.expenses.filter(e => e.id !== 'e1');
ok(!mergeShared(X, AB).expenses.some(e => e.id === 'e1') && !mergeShared(AB, X).expenses.some(e => e.id === 'e1'), 'gasto apagado nao volta');
const R = clone(AB); R.resDel.r1 = now(); R.res = [];
eq(mergeShared(AB, R).res.length, 0);
/* remover o ultimo dia vale para as duas */
const S1 = clone(AB); S1.itinerary.pop(); S1.days = {v: 21, t: now()};
eq(mergeShared(AB, S1).itinerary.length, 21);
/* estado antigo, sem campo de lugar, ganha o lugar original */
const old = clone(freshShared()); old.itinerary.forEach(r => { delete r.place; delete r.tp; }); delete old.days;
eq(sanitizeShared(old).itinerary[0].place.name, 'Valletta');

/* pessoal */
const P1 = freshPrivate(), P2 = freshPrivate();
P1.personal = {saved: 500, monthly: 800, meta: 10000, t: now()};
P1.deposits.push({id: 'd1', brl: 800, at: now(), t: now()});
P2.expenses.push({id: 'x', desc: 'Perfume', eur: 30, payer: 'nana', at: now(), t: now()});
P2.res.push({id: 'pr', kind: 'documento', title: 'Passaporte', files: [{id: 'f1', name: 'foto.jpg', type: 'image/jpeg'}], at: now(), t: now()});
const PM = mergePrivate(P1, P2);
eq([PM.personal.saved, PM.deposits.length, PM.expenses.length, PM.res[0].files.length], [500, 1, 1, 1]);
eq(PM, mergePrivate(P2, P1));
/* lixo vindo de fora nao quebra */
assert.doesNotThrow(() => mergeShared({itinerary: 'x', checklist: {docs: [null, {id: 1}]}, diary: {a: 5}, photos: [{}], res: [{}], days: {v: 'z'}}, null)); checks++;
console.log('JUNCAO_OK ' + checks + ' verificacoes');
