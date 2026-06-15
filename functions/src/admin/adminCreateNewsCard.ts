import { onCall } from 'firebase-functions/v2/https';
import { getDb, FieldValue } from '../core/admin';
import { assertRole } from '../core/auth';
import { requireString } from '../core/validate';
import type { NewsCard, Sport } from '@bluegrass/shared-models';

interface CreateNewsCardPayload {
  title: string;
  sourceName: string;
  url: string;
  summary: string;
  sport: Sport | 'high_school';
  tags?: string[];
  featured?: boolean;
}

export const adminCreateNewsCard = onCall<CreateNewsCardPayload>(async (request) => {
  const uid = assertRole(request, ['editor', 'admin']);
  const { data } = request;

  const title = requireString(data?.title, 'title');
  const sourceName = requireString(data?.sourceName, 'sourceName');
  const url = requireString(data?.url, 'url');
  const summary = requireString(data?.summary, 'summary');
  const sport = requireString(data?.sport, 'sport');

  const card: Omit<NewsCard, 'id'> = {
    title,
    sourceName,
    url,
    summary,
    sport: sport as Sport,
    tags: Array.isArray(data?.tags) ? data.tags.map(String) : [],
    featured: data?.featured ?? false,
    publishedAt: new Date().toISOString(),
    createdBy: uid,
  };

  const ref = await getDb().collection('news_cards').add({
    ...card,
    publishedAt: FieldValue.serverTimestamp(),
  });

  return { cardId: ref.id, message: 'News card created.' };
});
