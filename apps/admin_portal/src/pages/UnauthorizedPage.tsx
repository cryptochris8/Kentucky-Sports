import { Link } from 'react-router-dom';

export function UnauthorizedPage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center px-4">
      <div className="text-5xl mb-4">🚫</div>
      <h2 className="text-2xl font-bold text-gray-800 mb-2">Access Denied</h2>
      <p className="text-gray-500 text-sm mb-6 max-w-sm">
        Your account does not have permission to access this page. Contact an admin to
        request the appropriate role.
      </p>
      <Link
        to="/"
        className="text-sm text-[#1E5AA8] underline underline-offset-2 hover:text-[#1a4d94]"
      >
        Back to Dashboard
      </Link>
    </div>
  );
}
