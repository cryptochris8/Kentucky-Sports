// Firestore data converters for typed reads/writes.
import type {
  QueryDocumentSnapshot,
  SnapshotOptions,
  FirestoreDataConverter,
  DocumentData,
  WithFieldValue,
} from 'firebase/firestore';
import type { Game, Prediction, CommunityPost, NewsCard, SyncRun, VaultLegend, LegendBrief } from './types';

function withId<T extends object>(
  snap: QueryDocumentSnapshot,
  _options: SnapshotOptions | undefined,
): T & { id: string } {
  return { id: snap.id, ...(snap.data(_options) as T) };
}

// A minimal toFirestore that simply returns the model object as DocumentData.
// We strip the local `id` field (it lives in the document path, not the data).
function toDoc<T extends { id?: string }>(obj: WithFieldValue<T>): WithFieldValue<DocumentData> {
  const { id: _id, ...rest } = obj as T & { id?: string };
  void _id;
  return rest as WithFieldValue<DocumentData>;
}

export const gameConverter: FirestoreDataConverter<Game> = {
  toFirestore(game) { return toDoc(game); },
  fromFirestore(snap, opts) { return withId<Game>(snap, opts); },
};

export const predictionConverter: FirestoreDataConverter<Prediction> = {
  toFirestore(pred) { return toDoc(pred); },
  fromFirestore(snap, opts) { return withId<Prediction>(snap, opts); },
};

export const communityPostConverter: FirestoreDataConverter<CommunityPost> = {
  toFirestore(post) { return toDoc(post); },
  fromFirestore(snap, opts) { return withId<CommunityPost>(snap, opts); },
};

export const newsCardConverter: FirestoreDataConverter<NewsCard> = {
  toFirestore(card) { return toDoc(card); },
  fromFirestore(snap, opts) { return withId<NewsCard>(snap, opts); },
};

export const syncRunConverter: FirestoreDataConverter<SyncRun> = {
  toFirestore(run) { return toDoc(run); },
  fromFirestore(snap, opts) { return withId<SyncRun>(snap, opts); },
};

export const vaultLegendConverter: FirestoreDataConverter<VaultLegend> = {
  toFirestore(legend) { return toDoc(legend); },
  fromFirestore(snap, opts) { return withId<VaultLegend>(snap, opts); },
};

export const legendBriefConverter: FirestoreDataConverter<LegendBrief> = {
  toFirestore(brief) { return toDoc(brief); },
  fromFirestore(snap, opts) { return withId<LegendBrief>(snap, opts); },
};
