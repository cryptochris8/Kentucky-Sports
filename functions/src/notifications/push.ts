// Push notification stubs — Phase 1 does not send real FCM messages

export async function sendMorningPulse(_userIds: string[]): Promise<void> {
  console.log(
    '[sendMorningPulse] Phase 1 stub — no real FCM send. ' +
    `Would notify ${_userIds.length} user(s).`,
  );
}

export async function sendGamedayNotifications(
  _gameId: string,
  _userIds: string[],
): Promise<void> {
  console.log(
    `[sendGamedayNotifications] Phase 1 stub — no real FCM send. ` +
    `Would notify ${_userIds.length} user(s) for game ${_gameId}.`,
  );
}
