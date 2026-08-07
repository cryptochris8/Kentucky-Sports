// Typed Firestore data-access layer for The Vault (Legends editor).
// Mirrors data/firestore.ts — all reads/writes go through these helpers so the
// Vault pages stay thin. Writes are editor-gated by firestore.rules.

import {
  collection,
  doc,
  getDocs,
  getDoc,
  updateDoc,
  deleteField,
  query,
  orderBy,
  limit,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '../lib/firebase';
import { vaultLegendConverter, legendBriefConverter } from './converters';
import type { VaultLegend, VaultLegendStatus, LegendBrief } from './types';

// ─── Collections ─────────────────────────────────────────────────────────────

const legendsCol = () => collection(db, 'vault_legends').withConverter(vaultLegendConverter);

// ─── Vault Legends ───────────────────────────────────────────────────────────

export async function listVaultLegends(): Promise<VaultLegend[]> {
  const snap = await getDocs(query(legendsCol(), orderBy('generatedAt', 'desc'), limit(100)));
  return snap.docs.map((d) => d.data());
}

export async function getVaultLegend(id: string): Promise<VaultLegend | null> {
  const snap = await getDoc(doc(db, 'vault_legends', id).withConverter(vaultLegendConverter));
  return snap.exists() ? snap.data() : null;
}

/** Save an editor's form patch. Always stamps `updatedAt`. */
export async function saveVaultLegend(
  id: string,
  patch: Partial<Omit<VaultLegend, 'id'>>,
): Promise<void> {
  await updateDoc(doc(db, 'vault_legends', id), {
    ...patch,
    updatedAt: serverTimestamp(),
  });
}

/**
 * Transition status, optionally carrying the editor's current form content in
 * the SAME write (so e.g. unpublishing never discards unsaved edits). Sets
 * `publishedAt` when publishing and clears it when leaving `published`.
 */
export async function setLegendStatus(
  id: string,
  status: VaultLegendStatus,
  contentPatch: Partial<Omit<VaultLegend, 'id'>> = {},
): Promise<void> {
  const patch: Record<string, unknown> = {
    ...contentPatch,
    status,
    updatedAt: serverTimestamp(),
  };
  patch.publishedAt = status === 'published' ? serverTimestamp() : deleteField();
  await updateDoc(doc(db, 'vault_legends', id), patch);
}

// ─── Legend Briefs (read-only context for the fact-check guard) ───────────────

export async function getLegendBrief(id: string): Promise<LegendBrief | null> {
  const snap = await getDoc(doc(db, 'legend_briefs', id).withConverter(legendBriefConverter));
  return snap.exists() ? snap.data() : null;
}
