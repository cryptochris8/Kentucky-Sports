import { useEffect, useState } from 'react';
import { listPosts, updatePostStatus, toDisplayDate } from '../data/firestore';
import type { CommunityPost, PostStatus } from '../data/types';
import {
  PageHeader, Button, Badge, Table, Thead, Th, Tbody, Tr, Td,
  LoadingState, EmptyState, ErrorState, Card,
} from '../components/ui';

const FILTERS: Array<{ label: string; status: PostStatus | undefined }> = [
  { label: 'All', status: undefined },
  { label: 'Visible', status: 'visible' },
  { label: 'Pending', status: 'pending' },
  { label: 'Hidden', status: 'hidden' },
  { label: 'Removed', status: 'removed' },
];

function statusColor(s: PostStatus): 'green' | 'yellow' | 'gray' | 'red' {
  switch (s) {
    case 'visible': return 'green';
    case 'pending': return 'yellow';
    case 'hidden': return 'gray';
    case 'removed': return 'red';
    default: return 'gray';
  }
}

export function ModerationPage() {
  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filterStatus, setFilterStatus] = useState<PostStatus | undefined>(undefined);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      setPosts(await listPosts(filterStatus));
    } catch (err: unknown) {
      setError((err as { message?: string }).message ?? 'Failed to load posts.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, [filterStatus]);

  const handleStatusChange = async (post: CommunityPost, status: PostStatus) => {
    setActionLoading(post.id);
    try {
      await updatePostStatus(post.id, status);
      await load();
    } catch (err: unknown) {
      alert((err as { message?: string }).message ?? 'Action failed.');
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Moderation"
        subtitle="Review and moderate community posts."
      />

      {/* Filter tabs */}
      <Card>
        <div className="flex flex-wrap gap-2">
          {FILTERS.map((f) => (
            <button
              key={f.label}
              onClick={() => setFilterStatus(f.status)}
              className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
                filterStatus === f.status
                  ? 'bg-[#1E5AA8] text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>
      </Card>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} />}

      {!loading && !error && (
        posts.length === 0
          ? (
            <EmptyState
              label={filterStatus
                ? `No ${filterStatus} posts.`
                : 'No community posts yet.'}
            />
          )
          : (
            <Table>
              <Thead>
                <tr>
                  <Th>Post</Th>
                  <Th>User ID</Th>
                  <Th>Sport</Th>
                  <Th>Created</Th>
                  <Th>Status</Th>
                  <Th>Actions</Th>
                </tr>
              </Thead>
              <Tbody>
                {posts.map((p) => (
                  <Tr key={p.id}>
                    <Td className="max-w-xs">
                      {p.title && (
                        <p className="font-medium text-gray-800 text-sm truncate">{p.title}</p>
                      )}
                      <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{p.body}</p>
                    </Td>
                    <Td className="text-xs text-gray-500 font-mono">{p.userId}</Td>
                    <Td>
                      {p.sport
                        ? <Badge color="blue">{p.sport.replace(/_/g, ' ')}</Badge>
                        : <span className="text-gray-400 text-xs">—</span>}
                    </Td>
                    <Td className="text-xs text-gray-500">{toDisplayDate(p.createdAt)}</Td>
                    <Td><Badge color={statusColor(p.status)}>{p.status}</Badge></Td>
                    <Td>
                      <div className="flex items-center gap-1.5">
                        {p.status !== 'visible' && (
                          <Button
                            size="sm"
                            variant="secondary"
                            disabled={actionLoading === p.id}
                            onClick={() => handleStatusChange(p, 'visible')}
                          >
                            Approve
                          </Button>
                        )}
                        {p.status !== 'hidden' && (
                          <Button
                            size="sm"
                            variant="ghost"
                            disabled={actionLoading === p.id}
                            onClick={() => handleStatusChange(p, 'hidden')}
                          >
                            Hide
                          </Button>
                        )}
                        {p.status !== 'removed' && (
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={actionLoading === p.id}
                            onClick={() => handleStatusChange(p, 'removed')}
                          >
                            Remove
                          </Button>
                        )}
                      </div>
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          )
      )}
    </div>
  );
}
