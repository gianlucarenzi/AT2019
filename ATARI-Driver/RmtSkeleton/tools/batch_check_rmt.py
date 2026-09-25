#!/usr/bin/env python3
"""
Batch analyzer per file RMT - filtra quelli che usano solo canali 1+2
Uso: python3 batch_check_rmt.py directory/

Crea un report di quali file sono compatibili con SIO (solo CH1+2)
"""
import struct
import sys
import os
from pathlib import Path

def check_rmt(filepath):
    """Ritorna (canali_attivi, is_2channel)"""
    try:
        with open(filepath, 'rb') as f:
            data = f.read()
    except:
        return None, False
    
    if len(data) < 16:
        return None, False
    
    # Header Atari
    if data[:2] != b'\xff\xff':
        return None, False
    
    try:
        start, end = struct.unpack('<HH', data[2:6])
        module = data[6:6 + end - start + 1]
    except:
        return None, False
    
    # Verifica RMT4
    if module[:4] != b'RMT4':
        return None, False
    
    if len(module) < 16:
        return None, False
    
    # Leggi puntatori tracce
    try:
        p_tlo = struct.unpack('<H', module[10:12])[0]
        p_thi = struct.unpack('<H', module[12:14])[0]
    except:
        return None, False
    
    o_tlo = p_tlo - start
    o_thi = p_thi - start
    
    # Verifica canali
    active_channels = []
    for ch in range(4):
        if o_tlo + ch < len(module) and o_thi + ch < len(module):
            lo = module[o_tlo + ch]
            hi = module[o_thi + ch]
            ptr = lo | (hi << 8)
            if ptr != 0:
                active_channels.append(ch + 1)
    
    is_2channel = active_channels == [1, 2]
    return active_channels, is_2channel

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 batch_check_rmt.py /path/to/rmt/files/")
        print("     Crea un report dei file RMT filtrati per canali")
        sys.exit(1)
    
    directory = sys.argv[1]
    
    if not os.path.isdir(directory):
        print(f"❌ Directory non trovata: {directory}")
        sys.exit(1)
    
    # Cerca tutti i .rmt
    rmt_files = sorted(Path(directory).rglob('*.rmt'))
    
    if not rmt_files:
        print(f"❌ Nessun file .rmt trovato in {directory}")
        sys.exit(1)
    
    print(f"📁 Analizzando {len(rmt_files)} file RMT...")
    print()
    
    perfect = []     # Esattamente [1, 2]
    partial = []     # Sottoinsieme di [1, 2] (solo 1 oppure solo 2)
    full = []        # [1, 2, 3, 4]
    other = []       # Altro
    invalid = []
    
    for filepath in rmt_files:
        channels, is_2ch = check_rmt(str(filepath))
        
        if channels is None:
            invalid.append(filepath.name)
        elif is_2ch:
            perfect.append((filepath.name, channels))
        elif set(channels).issubset({1, 2}):
            partial.append((filepath.name, channels))
        elif channels == [1, 2, 3, 4]:
            full.append((filepath.name, channels))
        else:
            other.append((filepath.name, channels))
    
    # Report
    print("═" * 70)
    print("REPORT CANALI RMT")
    print("═" * 70)
    print()
    
    print(f"✅ PERFETTI (SOLO CH1+2): {len(perfect)}")
    if perfect:
        for name, ch in perfect:
            print(f"   ✓ {name}")
    print()
    
    print(f"⚠️  PARZIALI (Sottoinsieme di 1+2): {len(partial)}")
    if partial:
        for name, ch in partial:
            print(f"   • {name:<40} canali: {ch}")
    print()
    
    print(f"⚠️  TUTTI 4 CANALI: {len(full)}")
    if full and len(full) <= 5:
        for name, ch in full:
            print(f"   • {name}")
    elif full:
        print(f"   ({len(full)} file)")
    print()
    
    print(f"❌ ALTRI: {len(other)}")
    if other and len(other) <= 5:
        for name, ch in other:
            print(f"   • {name:<40} canali: {ch}")
    elif other:
        print(f"   ({len(other)} file)")
    print()
    
    print(f"❌ INVALIDI: {len(invalid)}")
    print()
    
    print("═" * 70)
    print(f"TOTALE: {len(rmt_files)} file")
    print(f"COMPATIBILI SIO (CH1+2 only): {len(perfect)} file ({100*len(perfect)//len(rmt_files)}%)")
    print("═" * 70)
    
    # Salva lista
    if perfect:
        with open('/tmp/rmt_2channel_list.txt', 'w') as f:
            for name, _ in perfect:
                f.write(name + '\n')
        print(f"\n💾 File compatibili salvati in: /tmp/rmt_2channel_list.txt")

if __name__ == '__main__':
    main()
