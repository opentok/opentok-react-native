import {
  addEventListener,
  clearStreams,
  dispatchEvent,
  getPublisherStream,
  sanitizeSessionOptions,
} from '../helpers/OTSessionHelper';

describe('OTSessionHelper', () => {
  it('dispatches publisher stream events and tracks publisher stream', () => {
    const sessionId = 'session-1';
    const listener = jest.fn();

    addEventListener(sessionId, 'publisherStreamCreated', listener);
    dispatchEvent(sessionId, 'publisherStreamCreated', {
      streamId: 'stream-1',
    });

    expect(listener).toHaveBeenCalledWith({ streamId: 'stream-1' });
    expect(getPublisherStream(sessionId)).toBe('stream-1');

    clearStreams(sessionId);
  });

  it('sanitizes session options', () => {
    const result = sanitizeSessionOptions({
      apiUrl: 42,
      connectionEventsSuppressed: true,
    });

    expect(result.apiUrl).toBe('');
    expect(result.connectionEventsSuppressed).toBe(true);
  });
});
