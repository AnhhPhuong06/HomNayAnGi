import { before, after, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, collection, query, orderBy, limit, getDocs, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-meal-community', firestore: { rules: readFileSync('../../firestore.rules', 'utf8') } });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const db = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const post = (uid, overrides = {}) => ({ authorId: uid, authorName: 'An', kind: 'meal', title: 'Bữa trưa hôm nay', body: 'Mình đã ăn một bữa trưa rất ngon hôm nay.', category: 'rice', restaurantId: '', restaurantName: '', area: '', createdAt: serverTimestamp(), termsVersion: 1, ...overrides });

test('anonymous cannot read or write even via direct API', async () => {
  await assertFails(getDocs(collection(db(), 'posts')));
  await assertFails(setDoc(doc(db(), 'posts/p'), post('alice')));
});
test('signed in author publishes and another member reads the feed', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'posts/p'), post('alice')));
  await assertSucceeds(getDocs(query(collection(db('bob'), 'posts'), orderBy('createdAt', 'desc'), limit(30))));
});
test('reject impersonation, short content and arbitrary photo URL', async () => {
  await assertFails(setDoc(doc(db('bob'), 'posts/p'), post('alice')));
  await assertFails(setDoc(doc(db('alice'), 'posts/p'), post('alice', { body: 'ngon' })));
  await assertFails(setDoc(doc(db('alice'), 'posts/p'), post('alice', { imageUrl: 'https://invalid.example/photo.jpg' })));
  await assertFails(setDoc(doc(db('alice'), 'posts/p'), post('alice', { category: 'madeup' })));
});
test('restaurant sharing requires name and area, timestamps are server controlled', async () => {
  await assertFails(setDoc(doc(db('alice'), 'posts/p'), post('alice', { kind: 'restaurant' })));
  await assertFails(setDoc(doc(db('alice'), 'posts/p'), post('alice', { createdAt: new Date(0) })));
  await assertSucceeds(setDoc(doc(db('alice'), 'posts/p'), post('alice', { kind: 'restaurant', restaurantName: 'Quán A', area: 'Hà Nội' })));
});

test('public places require coordinates, keep author ownership and reject malformed direct writes', async () => {
  const place = post('alice', {kind: 'place', restaurantName: 'Quán mới', area: 'Địa chỉ quán', latitude: 10.77734, longitude: 106.700248});
  await assertSucceeds(setDoc(doc(db('alice'), 'posts/place'), place));
  await assertSucceeds(getDoc(doc(db('bob'), 'posts/place')));
  await assertFails(setDoc(doc(db('bob'), 'posts/spoof'), place));
  for (const change of [{latitude: 91}, {longitude: -181}, {latitude: '10'}, {latitude: null}, {restaurantName: ''}, {area: ''}, {restaurantId: 'osm-node-1'}]) {
    await assertFails(setDoc(doc(db('alice'), 'posts/invalid'), {...place, ...change}));
  }
  const {longitude, ...missingCoordinate} = place;
  await assertFails(setDoc(doc(db('alice'), 'posts/missing'), missingCoordinate));
  await assertFails(setDoc(doc(db('alice'), 'posts/meal-location'), post('alice', {latitude: 10, longitude: 106})));
  await assertFails(deleteDoc(doc(db('bob'), 'posts/place')));
  await assertSucceeds(deleteDoc(doc(db('alice'), 'posts/place')));
});
test('only author deletes and nobody edits published posts', async () => {
  await setDoc(doc(db('alice'), 'posts/p'), post('alice'));
  await assertFails(deleteDoc(doc(db('bob'), 'posts/p')));
  await assertFails(setDoc(doc(db('alice'), 'posts/p'), post('alice')));
  await assertSucceeds(deleteDoc(doc(db('alice'), 'posts/p')));
});
test('reports are private and can be removed by reporter for account deletion', async () => {
  await setDoc(doc(db('alice'), 'posts/p'), post('alice'));
  const report = { postId: 'p', reporterId: 'bob', reason: 'Nội dung cần xem xét', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(db('bob'), 'reports/bob_p'), report));
  await assertFails(getDoc(doc(db('alice'), 'reports/bob_p')));
  await assertFails(setDoc(doc(db('alice'), 'reports/bob_p'), report));
  await assertSucceeds(deleteDoc(doc(db('bob'), 'reports/bob_p')));
});
test('blocks are scoped to member, no self block or cross-account access', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'members/alice/blocked/bob'), { createdAt: serverTimestamp() }));
  await assertFails(getDocs(collection(db('bob'), 'members/alice/blocked')));
  await assertFails(setDoc(doc(db('alice'), 'members/alice/blocked/alice'), { createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db('bob'), 'members/alice/blocked/charlie'), { createdAt: serverTimestamp() }));
});

const backup = (overrides = {}) => ({
  version: 1, revision: 1, updatedAt: serverTimestamp(),
  data: { favorites: ['osm:node:1'], history: ['osm:node:2'],
    preference: {budgetMin: null, budgetMax: null, maxDistance: 3, mealTime: null, companion: null, selectedCategories: ['rice']},
    taste: {dislikedCategories: ['cafe'], hiddenRestaurantIds: ['osm:node:3'], avoidedKeywords: ['oc'], avoidRecentCount: 5}},
  ...overrides,
});
test('personal backups are private to the exact owner including direct reads', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'profiles/alice'), backup()));
  await assertSucceeds(getDoc(doc(db('alice'), 'profiles/alice')));
  await assertFails(getDoc(doc(db('bob'), 'profiles/alice')));
  await assertFails(getDoc(doc(db(), 'profiles/alice')));
  await assertFails(setDoc(doc(db('bob'), 'profiles/alice'), backup({revision: 2})));
  await assertFails(deleteDoc(doc(db('bob'), 'profiles/alice')));
  await assertSucceeds(deleteDoc(doc(db('alice'), 'profiles/alice')));
});
test('backup schema rejects coordinates, excess history and invalid tastes', async () => {
  const good = backup();
  await assertFails(setDoc(doc(db('alice'), 'profiles/alice'), backup({data: {...good.data, location: {latitude: 21, longitude: 106}}})));
  await assertFails(setDoc(doc(db('alice'), 'profiles/alice'), backup({data: {...good.data, history: Array(21).fill('a')}})));
  await assertFails(setDoc(doc(db('alice'), 'profiles/alice'), backup({data: {...good.data, taste: {...good.data.taste, dislikedCategories: ['madeup']}}})));
  await assertFails(setDoc(doc(db('alice'), 'profiles/alice'), backup({data: {...good.data, taste: {...good.data.taste, avoidRecentCount: -5}}})));
  await assertFails(setDoc(doc(db('alice'), 'profiles/alice'), backup({data: {...good.data, preference: {...good.data.preference, latitude: 21}}})));
});
test('backup revisions advance exactly once and server owns the timestamp', async () => {
  const target = doc(db('alice'), 'profiles/alice');
  await assertFails(setDoc(target, backup({revision: 4})));
  await assertFails(setDoc(target, backup({updatedAt: new Date(0)})));
  await assertSucceeds(setDoc(target, backup()));
  await assertFails(setDoc(target, backup()));
  await assertSucceeds(setDoc(target, backup({revision: 2})));
  await assertFails(setDoc(target, backup({revision: 2})));
});


async function grantModerator(uid) {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'roles/' + uid), {admin: true});
  });
}

test('clients cannot grant roles or enumerate other members roles', async () => {
  await assertFails(setDoc(doc(db('alice'), 'roles/alice'), {admin: true}));
  await grantModerator('mod');
  await assertSucceeds(getDoc(doc(db('mod'), 'roles/mod')));
  await assertFails(getDoc(doc(db('alice'), 'roles/mod')));
  await assertFails(getDocs(collection(db('mod'), 'roles')));
  await assertFails(deleteDoc(doc(db('mod'), 'roles/mod')));
});

test('moderator reads reports and removes violating posts without accessing private backups', async () => {
  await grantModerator('mod');
  await setDoc(doc(db('alice'), 'posts/p'), post('alice'));
  await setDoc(doc(db('bob'), 'reports/bob_p'), {postId: 'p', reporterId: 'bob', reason: 'Content requires moderation', status: 'open', createdAt: serverTimestamp()});
  await assertSucceeds(getDocs(collection(db('mod'), 'reports')));
  await assertFails(getDocs(collection(db('charlie'), 'reports')));
  await setDoc(doc(db('alice'), 'profiles/alice'), backup());
  await assertFails(getDoc(doc(db('mod'), 'profiles/alice')));
  await assertSucceeds(deleteDoc(doc(db('mod'), 'posts/p')));
});

test('only moderator resolves reports and cannot rewrite their original contents', async () => {
  await grantModerator('mod');
  await setDoc(doc(db('alice'), 'posts/p'), post('alice'));
  const report = {postId: 'p', reporterId: 'bob', reason: 'Content requires moderation', createdAt: serverTimestamp()};
  await setDoc(doc(db('bob'), 'reports/bob_p'), report);
  const resolution = {status: 'resolved', moderatorId: 'mod', resolvedAt: serverTimestamp()};
  await assertFails(updateDoc(doc(db('bob'), 'reports/bob_p'), resolution));
  await assertFails(updateDoc(doc(db('mod'), 'reports/bob_p'), {...resolution, moderatorId: 'someone-else'}));
  await assertFails(updateDoc(doc(db('mod'), 'reports/bob_p'), {...resolution, reason: 'Changed accusation'}));
  await assertSucceeds(updateDoc(doc(db('mod'), 'reports/bob_p'), resolution));
  await assertFails(updateDoc(doc(db('mod'), 'reports/bob_p'), {status: 'open'}));
});

test('role revocation immediately prevents moderation writes and reporters cannot pre-resolve a report', async () => {
  await grantModerator('mod');
  await setDoc(doc(db('alice'), 'posts/p'), post('alice'));
  await assertFails(setDoc(doc(db('bob'), 'reports/bob_p'), {postId: 'p', reporterId: 'bob', reason: 'Content requires moderation', status: 'resolved', createdAt: serverTimestamp()}));
  await env.withSecurityRulesDisabled(async context => { await deleteDoc(doc(context.firestore(), 'roles/mod')); });
  await assertFails(deleteDoc(doc(db('mod'), 'posts/p')));
});
