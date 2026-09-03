#!/usr/bin/env python3
"""Minimal FFXI SeWave (.spw) -> WAV decoder (PS-ADPCM / PCM16).

Used to produce files/call21.wav from a local FFXI installation, so the chime
can be regenerated or swapped for a different call without trusting a binary
blob in this repository.

The call jingles live in the base sound bank as uncompressed PCM:

    <FFXI>/sound/win/se/se000/se0000NN.spw

where file 17 is <call1> and file 37 is <call21>, i.e. NN = 16 + call number. So:

    python3 tools/spw2wav.py ".../sound/win/se/se000/se000037.spw" files/call21.wav

Header layout follows vgmstream's bgw.c.
"""
import struct, sys, os, wave

COEF = [(0, 0), (60, 0), (115, -52), (98, -55), (122, -60),
        (0, 0), (0, 0), (0, 0), (0, 0), (0, 0),
        (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)]


def parse_header(b):
    if b[0:6] != b'SeWave':
        raise ValueError('not SeWave')
    file_size = struct.unpack_from('<I', b, 0x08)[0]
    codec = struct.unpack_from('<I', b, 0x0c)[0]
    block_size = struct.unpack_from('<I', b, 0x14)[0]
    loop_start = struct.unpack_from('<i', b, 0x18)[0]
    sr = (struct.unpack_from('<I', b, 0x1c)[0] + struct.unpack_from('<I', b, 0x20)[0]) & 0xFFFFFFFF
    sample_rate = sr & 0x7FFFFFFF
    start = struct.unpack_from('<I', b, 0x24)[0]
    channels = struct.unpack_from('<b', b, 0x2a)[0]
    block_align = b[0x2c]
    return dict(file_size=file_size, codec=codec, block_size=block_size,
                loop_start=loop_start, sample_rate=sample_rate, start=start,
                channels=channels, block_align=block_align)


def decode_psx(data, frame_size):
    """Decode configurable-frame PS-ADPCM. Returns list of int16."""
    out = []
    h1 = h2 = 0
    for off in range(0, len(data) - frame_size + 1, frame_size):
        hdr = data[off]
        shift = hdr & 0x0F
        idx = (hdr >> 4) & 0x0F
        if idx > 5:
            idx = 0
        if shift > 12:
            shift = 9
        c0, c1 = COEF[idx]
        flag = data[off + 1]
        if flag == 0x07:  # stop
            break
        for i in range(2, frame_size):
            byte = data[off + i]
            for nib in (byte & 0x0F, byte >> 4):
                s = nib
                if s > 7:
                    s -= 16
                s = s << (12 - shift)
                s = s + ((h1 * c0 + h2 * c1) >> 6)
                s = max(-32768, min(32767, s))
                out.append(s)
                h2 = h1
                h1 = s
    return out


def convert(path, outpath):
    b = open(path, 'rb').read()
    h = parse_header(b)
    data = b[h['start']:]
    ch = max(1, h['channels'])
    if h['codec'] == 1:
        samples = list(struct.unpack('<%dh' % (len(data) // 2), data[:len(data) // 2 * 2]))
    elif h['codec'] == 0:
        frame = (h['block_align'] // 2) + 1
        if ch == 1:
            samples = decode_psx(data, frame)
        else:
            # interleaved per-channel blocks of `frame` bytes
            chans = [[] for _ in range(ch)]
            per = frame
            i = 0
            while i + per * ch <= len(data):
                for c in range(ch):
                    chans[c].extend(decode_psx(data[i + c * per:i + (c + 1) * per], per))
                i += per * ch
            samples = [s for tup in zip(*chans) for s in tup]
    else:
        raise ValueError('unsupported codec %d' % h['codec'])
    w = wave.open(outpath, 'wb')
    w.setnchannels(ch)
    w.setsampwidth(2)
    w.setframerate(h['sample_rate'])
    w.writeframes(struct.pack('<%dh' % len(samples), *samples))
    w.close()
    return h, len(samples) / ch / h['sample_rate']


if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    h, dur = convert(src, dst)
    print(os.path.basename(src), h, '%.2fs' % dur)
