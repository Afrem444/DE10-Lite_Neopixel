# DE10-Lite_Neopixel
Programm for the DE10-Lite FPGA Development Board to controll Neopixel LEDs

## Code-Erklärung

### Übersicht
Dieses VHDL-Programm steuert WS2812B Neopixel LEDs über das DE10-Lite FPGA Board. Die Neopixel LEDs verwenden ein spezielles Timing-Protokoll, bei dem Nullen und Einsen durch unterschiedliche Pulsbreiten codiert werden.

### Ein- und Ausgänge

| Port | Richtung | Beschreibung |
|------|----------|--------------|
| `CLOCK_50` | Eingang | 50 MHz Systemtakt |
| `GPIO(0)` | Ausgang | Datenleitung zu den Neopixel LEDs |
| `KEY(1:0)` | Eingang | Taster zur T0H-Timing-Anpassung |
| `SW(2:0)` | Eingang | Schalter für RGB-Farbauswahl |

### Signale

| Signal | Typ | Beschreibung |
|--------|-----|--------------|
| `counter` | 26-bit Vektor | Zähler für Timing |
| `Clock_neo` | std_logic | Ausgangssignal für die LEDs |
| `RGB1` | 24-bit Vektor | Farbdaten (GRB-Format) |
| `position` | Integer 0-23 | Aktuelles Bit im 24-bit Farbwert |
| `led_count` | Integer 0-9 | Aktuelle LED-Nummer (max. 9 LEDs) |

### Funktionsweise

#### 1. Farbzuweisung
```vhdl
BLED1 <= (others => SW(0));  -- Blau = SW(0)
RLED1 <= (others => SW(1));  -- Rot = SW(1)
GLED1 <= (others => SW(2));  -- Grün = SW(2)
RGB1 <= BLED1 & RLED1 & GLED1;
```
Die Schalter SW(0-2) setzen die Farbkanäle auf 0x00 oder 0xFF.

#### 2. Taster-Steuerung (KEY_PROCESS)
- **KEY(0)**: Erhöht T0H um 1 Takt (Flankengesteuert)
- **KEY(1)**: Verringert T0H um 1 Takt (Flankengesteuert)

Dies ermöglicht Feintuning des Timings.

#### 3. Hauptprozess (DIV_COUNTER)
Der Prozess durchläuft folgende Zustände:

```
┌─────────────────────────────────────────────────────┐
│  Für jede LED (led_count = 0 bis 8):                │
│    Für jedes Bit (position = 0 bis 23):             │
│      → Wenn Bit = '1': High für T1H, Low für T1L    │
│      → Wenn Bit = '0': High für T0H, Low für T0L    │
│  Nach 9 LEDs: Reset-Pause (TReset Takte)            │
└─────────────────────────────────────────────────────┘
```

#### 4. Signalausgabe
```vhdl
GPIO(0) <= Clock_neo;
```
Das generierte Signal wird über GPIO Pin 0 ausgegeben.

### Blockdiagramm

```
    SW(0-2)          KEY(0-1)
       │                 │
       ▼                 ▼
  ┌─────────┐     ┌─────────────┐
  │  Farb-  │     │   Timing-   │
  │ zuwei-  │     │  Anpassung  │
  │  sung   │     │    (T0H)    │
  └────┬────┘     └──────┬──────┘
       │                 │
       ▼                 ▼
  ┌──────────────────────────────┐
  │      Bit-Serialisierer       │
  │  (24 Bit × 9 LEDs + Reset)   │
  └──────────────┬───────────────┘
                 │
                 ▼
            GPIO(0) ──────► Neopixel LEDs
```

### Verwendung
1. **SW(0)** einschalten → Alle LEDs leuchten Blau
2. **SW(1)** einschalten → Alle LEDs leuchten Rot
3. **SW(2)** einschalten → Alle LEDs leuchten Grün
4. Kombinationen möglich (z.B. SW(0)+SW(1) = Magenta)
5. **KEY(0/1)** zur Timing-Feinabstimmung bei Problemen
