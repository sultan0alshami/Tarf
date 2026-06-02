const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { setDoc, getDoc, doc, deleteDoc } = require('firebase/firestore');

let env;
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-tarf',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
afterAll(() => env.cleanup());
beforeEach(() => env.clearFirestore());

test('owner can write a valid state doc', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/state/settings'), { payload: { localeCode: 'ar' }, updatedAt: 123 })
  );
});

test('a different user cannot read or write your data', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(alice, 'users/alice/state/todos'), { payload: [], updatedAt: 1 }));
  const mallory = env.authenticatedContext('mallory').firestore();
  await assertFails(getDoc(doc(mallory, 'users/alice/state/todos')));
  await assertFails(setDoc(doc(mallory, 'users/alice/state/todos'), { payload: [], updatedAt: 2 }));
});

test('unauthenticated access is denied', async () => {
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon, 'users/alice/state/settings')));
});

test('state docs require updatedAt and a payload field (shape validation)', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/state/settings'), { payload: { x: 1 } })); // no updatedAt
  await assertFails(setDoc(doc(db, 'users/alice/state/settings'), { updatedAt: 1 }));       // no payload
});

test('owner can delete their own doc (delete-all path)', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice/state/alarms'), { payload: [], updatedAt: 1 }));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/state/alarms')));
});

test('writes to collections outside /users are denied', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'global/anything'), { x: 1 }));
});
