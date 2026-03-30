import { sanitizeProperties } from '../helpers/OTPublisherHelper';

describe('sanitizeProperties', () => {
  it('returns defaults for invalid input', () => {
    const result = sanitizeProperties(undefined);

    expect(result.publishAudio).toBe(true);
    expect(result.publishVideo).toBe(true);
    expect(result.resolution).toBe('MEDIUM');
    expect(result.frameRate).toBe(30);
  });

  it('sanitizes preferred video codecs array', () => {
    const result = sanitizeProperties({
      preferredVideoCodecs: ['vp8', 'invalid', 'h264', 'vp8'],
    });

    expect(result.preferredVideoCodecs).toBe('vp8;h264'); //it should clear duplicates and remove invalid values
  });
});
