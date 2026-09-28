#!/usr/bin/env python3
"""
Analizzatore file RMT - mostra quanti CANALI POKEY usa una canzone
Uso: python3 analyze_rmt_fixed.py file.rmt

In RMT:
- 4 canali POKEY (CH1, CH2, CH3, CH4)
- Fino a 255 tracce/pattern (distribuite sui 4 canali)

Questo script verifica quale canale POKEY è effettivamente usato,
leggendo le righe della song.
"""
import struct
import sys

def analyze_rmt(filename):
    try:
        with open(filename, 'rb') as f:
            data = f.read()
    except:
        print(f"❌ Errore: impossibile leggere {filename}")
        return
    
    # Verifica header Atari binary
    if data[:2] != b'\xff\xff':
        print(f"❌ Non è un file binario Atari")
        return
    
    start, end = struct.unpack('<HH', data[2:6])
    module = data[6:6 + end - start + 1]
    
    # Verifica RMT4 vs RMT8
    if module[:4] == b'RMT8':
        print(f"❌ STEREO (RMT8) - non supportato dal player")
        return
    
    if module[:4] != b'RMT4':
        print(f"❌ Non è un file RMT valido")
        return
    
    print(f"✓ File RMT4 (mono)")
    print(f"  Taglia modulo: {len(module)} byte")
    print(f"  Speed: {module[4]}")
    print(f"  Instr speed: {module[6]}")
    
    # Leggi puntatori
    p_instr = struct.unpack('<H', module[8:10])[0]
    p_tlo = struct.unpack('<H', module[10:12])[0]
    p_thi = struct.unpack('<H', module[12:14])[0]
    p_song = struct.unpack('<H', module[14:16])[0]
    
    o_instr = p_instr - start
    o_tlo = p_tlo - start
    o_thi = p_thi - start
    o_song = p_song - start
    
    # RMT4 ha sempre 4 canali POKEY. Le tabelle tracce lo/hi sono indicizzate
    # per numero di traccia, non per canale: i canali usati si leggono dalla
    # song, righe da 4 byte (un numero di traccia per canale, $FF = vuoto,
    # riga che inizia con $FE = goto).
    num_channels = 4
    print(f"  Tracce: {o_thi - o_tlo}")

    used = set()
    off = o_song
    while off + 3 < len(module):
        if module[off] != 0xFE:
            for ch in range(num_channels):
                if module[off + ch] != 0xFF:
                    used.add(ch + 1)
        off += 4
    active_channels = sorted(used)

    print(f"\n  Canali POKEY totali: 4 (sempre in RMT4)")
    print(f"  Canali POKEY usati: {active_channels}")
    print()
    
    # Verdict
    if active_channels == [1, 2]:
        print(f"✅ USA SOLO CANALI 1+2 - PERFETTO PER IL TUO PROGETTO!")
        print(f"   Durante SIO: continuano solo CH1+CH2 ✓")
        return True
    elif set(active_channels).issubset({1, 2}):
        print(f"✅ Usa un sottoinsieme di [1, 2] - COMPATIBILE")
        print(f"   Durante SIO: no problemi ✓")
        return True
    else:
        channels_lost = [ch for ch in active_channels if ch > 2]
        print(f"⚠️  Usa canali {active_channels}")
        print(f"   Canali che si silenzierebbero durante SIO: {channels_lost}")
        print(f"   Durante il caricamento: audio ridotto")
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python3 analyze_rmt_fixed.py file.rmt")
        print("Mostra quale canali POKEY usa il file RMT")
        sys.exit(1)
    
    filename = sys.argv[1]
    result = analyze_rmt(filename)
    sys.exit(0 if result else 1)
