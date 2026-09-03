# hxifish
FFXI Tracker for fishing statistics. Window automatically opens when casting your line.<br /><br />
Current Version: 1.7.3<br />
<a href="CHANGELOG.md">View Changelog</a><br /><br />

This is a fork of <a href="https://github.com/spkywt/hxifish">spkywt/hxifish</a> by Espe (spkywt), adding fishing pool refresh tracking.

<table>
  <tr>
    <td>/hxifish</td>
    <td>manually show the tracking window</td>
</tr>
</table>

## New in this fork (1.7.0)

### Pool refresh timer

HorizonXI restocks its fishing pools at the Vana'diel hours **0:00, 4:00, 6:00, 7:00, 17:00, 18:00 and 20:00**.
A line under **Skill** shows which restock is next and how long you have to wait in real-life time:

```
Next Refresh: 06:00 (3m 34s)
```

The `06:00` is the Vana'diel hour the pools restock at; the countdown in parentheses is real time.

### Pool refresh chime

**Show Options** has a **Pool Refresh Chime** checkbox (**off by default**). When enabled, the
`<call21>` sound effect plays at each restock. It is played through Ashita's own sound player, so
nothing is written to the chat log.

A nested **Only with fishing rod equipped** checkbox (**on by default**) limits the chime to when
you actually have a rod in your ranged slot. Rods are detected by weapon skill rather than an item
id list, so all 20 of them are covered — bait and lures share that skill but are ammo-slot items,
so they don't count.

The sound lives in `files/call21.wav`. To use a different call, extract it from your own game
files with the included decoder. The call jingles are `se0000NN.spw` in `<FFXI>/sound/win/se/se000`,
where `NN = 16 + call number` — so `se000017.spw` is `<call1>` and `se000037.spw` is `<call21>`:

```
# swap the chime for <call5>
python3 tools/spw2wav.py "<FFXI>/sound/win/se/se000/se000021.spw" files/call21.wav
```

`files/call21.wav` is decoded from FINAL FANTASY XI client data and remains the property of
Square Enix. It is included here for use alongside a legitimate installation of the game.

---

New in 1.5 -- added notification for epic fish that should be good enough for the fishing competition<br />
<img width="465" height="92" alt="image" src="https://github.com/user-attachments/assets/470bfaec-0a7f-4d1b-96e6-d8093113c2d0" /><br /><br />
New in 1.4 -- skill up chance in catch message<br />
<img width="535" height="35" alt="image" src="https://github.com/user-attachments/assets/fa37148c-d896-4a7c-a478-55e8156614d5" /><br /><br />
<img width="254" height="562" alt="image" src="https://github.com/user-attachments/assets/513f756e-cf1c-4ced-84a8-3ccc7a630415" />
<img width="249" height="560" alt="image" src="https://github.com/user-attachments/assets/7a334713-fdd7-4763-89ed-c7519e000056" />
<img width="251" height="558" alt="image" src="https://github.com/user-attachments/assets/09b6f34d-9f6d-407e-9e42-8cd13589f866" />
