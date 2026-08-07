// Minimal in-memory Firestore fake for writer-layer unit tests (no emulator).
//
// Test files stub the admin module with:
//
//   vi.mock('../core/admin', async () => {
//     const { fakeDb, FieldValueMock, TimestampMock } = await import('./helpers/fakeFirestore');
//     return { getDb: () => fakeDb, FieldValue: FieldValueMock, Timestamp: TimestampMock };
//   });
//
// Supported surface (only what scoring.ts / adminScorePrediction.ts touch):
// collection().doc().get/update/set, equality-only where() queries over direct
// children, and runTransaction with immediate writes — single-threaded tests
// never see contention, so buffering writes would add complexity without
// changing observable behavior. Every write is appended to `writeLog` with a
// 'tx.'-prefixed op when it went through a transaction, so tests can pin that
// a write happened transactionally.

export type DocData = Record<string, unknown>;

export interface WriteLogEntry {
  op: 'update' | 'set' | 'tx.update' | 'tx.set';
  path: string;
  data: DocData;
}

export interface FakeDocSnap {
  exists: boolean;
  id: string;
  ref: FakeDocRef;
  data(): DocData | undefined;
}

export class FakeDocRef {
  constructor(
    private readonly db: FakeFirestore,
    readonly path: string,
  ) {}

  get id(): string {
    const segments = this.path.split('/');
    return segments[segments.length - 1];
  }

  collection(name: string): FakeCollection {
    return new FakeCollection(this.db, `${this.path}/${name}`);
  }

  snapshot(): FakeDocSnap {
    const data = this.db.read(this.path);
    return {
      exists: data !== undefined,
      id: this.id,
      ref: this,
      data: () => (data === undefined ? undefined : { ...data }),
    };
  }

  async get(): Promise<FakeDocSnap> {
    return this.snapshot();
  }

  async update(patch: DocData): Promise<void> {
    this.db.apply('update', this.path, patch, 'update');
  }

  async set(data: DocData, opts?: { merge?: boolean }): Promise<void> {
    this.db.apply('set', this.path, data, opts?.merge ? 'merge' : 'replace');
  }
}

export class FakeCollection {
  constructor(
    private readonly db: FakeFirestore,
    readonly path: string,
    private readonly filters: ReadonlyArray<{ field: string; value: unknown }> = [],
  ) {}

  doc(id: string): FakeDocRef {
    return new FakeDocRef(this.db, `${this.path}/${id}`);
  }

  where(field: string, op: string, value: unknown): FakeCollection {
    if (op !== '==') {
      throw new Error(`FakeFirestore only supports '==' filters (got '${op}').`);
    }
    return new FakeCollection(this.db, this.path, [...this.filters, { field, value }]);
  }

  async get(): Promise<{ empty: boolean; docs: FakeDocSnap[] }> {
    const prefix = `${this.path}/`;
    const docs: FakeDocSnap[] = [];
    for (const key of this.db.paths()) {
      if (!key.startsWith(prefix)) continue;
      if (key.slice(prefix.length).includes('/')) continue; // direct children only
      const snap = new FakeDocRef(this.db, key).snapshot();
      const data = snap.data() ?? {};
      if (this.filters.every((f) => data[f.field] === f.value)) docs.push(snap);
    }
    return { empty: docs.length === 0, docs };
  }
}

export class FakeTransaction {
  constructor(private readonly db: FakeFirestore) {}

  async get(ref: FakeDocRef): Promise<FakeDocSnap> {
    return ref.snapshot();
  }

  update(ref: FakeDocRef, patch: DocData): this {
    this.db.apply('tx.update', ref.path, patch, 'update');
    return this;
  }

  set(ref: FakeDocRef, data: DocData, opts?: { merge?: boolean }): this {
    this.db.apply('tx.set', ref.path, data, opts?.merge ? 'merge' : 'replace');
    return this;
  }
}

export class FakeFirestore {
  private readonly store = new Map<string, DocData>();
  readonly writeLog: WriteLogEntry[] = [];

  collection(name: string): FakeCollection {
    return new FakeCollection(this, name);
  }

  async runTransaction<T>(fn: (tx: FakeTransaction) => Promise<T>): Promise<T> {
    return fn(new FakeTransaction(this));
  }

  /** Test setup: place a document at `path` ('collection/docId'). */
  seed(path: string, data: DocData): void {
    this.store.set(path, { ...data });
  }

  /** Test assertion: the current document data at `path`, or undefined. */
  read(path: string): DocData | undefined {
    return this.store.get(path);
  }

  paths(): IterableIterator<string> {
    return this.store.keys();
  }

  apply(
    op: WriteLogEntry['op'],
    path: string,
    data: DocData,
    mode: 'update' | 'merge' | 'replace',
  ): void {
    this.writeLog.push({ op, path, data });
    const existing = this.store.get(path);
    if (mode === 'update') {
      if (existing === undefined) {
        throw new Error(`NOT_FOUND: no document to update at ${path}`);
      }
      this.store.set(path, { ...existing, ...data });
    } else if (mode === 'merge') {
      this.store.set(path, { ...(existing ?? {}), ...data });
    } else {
      this.store.set(path, { ...data });
    }
  }

  reset(): void {
    this.store.clear();
    this.writeLog.length = 0;
  }
}

/** Shared singleton the vi.mock factories and the tests both import. */
export const fakeDb = new FakeFirestore();

/** Sentinel stand-ins for the admin FieldValue/Timestamp statics. */
export const FieldValueMock = {
  serverTimestamp: () => ({ __fieldValue: 'serverTimestamp' }),
  increment: (by: number) => ({ __fieldValue: 'increment', by }),
};

export const TimestampMock = {
  now: () => ({ __timestamp: Date.now() }),
};
