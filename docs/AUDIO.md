# Audio en timing

## Invoer

`record` vraagt bij starten microfoontoestemming en levert mono PCM16 little endian op 48 kHz. Geen opnamebestand, netwerkverkeer, automatische gain, echo cancellation of noise suppression. Android vraagt onbewerkte input en schakelt automatische Bluetooth-routering uit. iOS laat de plugin AVAudioSession beheren en vraagt geen Bluetooth-categoryopties. USB/audio-interface en routewisselingen moeten nog op apparaten worden gevalideerd. YIN is afzonderlijk getest voor 44,1 en 48 kHz; de productiestream vraagt 48 kHz.

De ringbuffer heeft 4096 samples (85,33 ms); de hop is 1024 samples (21,33 ms). Er staat hoogstens één analyseframe tegelijk in de worker. Onder belasting worden tussenliggende vensters overgeslagen, zonder een wachtrij van verouderde audio op te bouwen. De Dart-isolate houdt de kwadratische YIN-analyse buiten de UI-thread. De ringbuffer en YIN-resultaten worden niet permanent opgeslagen.

## Detectie

YIN gebruikt de cumulative mean normalized difference en de eerste lokale minimumwaarde onder 0,15. Parabolische interpolatie verfijnt de frequentie. Stilte/ruis onder de configureerbare RMS-drempel geeft geen noot; een onbetrouwbaar minimum evenmin. De worker vereist minimaal twee opeenvolgende dezelfde afgeronde MIDI-noten en confidence ≥ 0,85. De analyses bestrijken ongeveer 65–1400 Hz.

Onsetdetectie gebruikt release, energiestijging of een stabiele pitchwijziging, met een refractory-periode van 140 ms. Een constante toon produceert dus niet steeds nieuwe scores. Dit is een eenvoudige monofone detector: zachte heraanslagen op dezelfde toon, galm, vibrato en snelle passages zijn nog niet fysiek gekwalificeerd. Dit is geen polyfone akkoordherkenning. Er worden geen claims gedaan over individuele snaren of vingers vanuit de microfoon.

## Tijd en latency

Een `Stopwatch` is de monotone bron. PCM-arrival wordt teruggerekend voor de nog resterende samples in de chunk en het midden van het analysevenster. Capture timestamps van de hardware zijn niet beschikbaar in de gebruikte record-API. De effectieve window-/onsetvertraging en native inputbuffering blijven daarom schattingen.

De game rekent beats met `2 + startBeat × 60 / BPM` om naar seconden; twee seconden geven voorbereidingstijd. Flame en scoring gebruiken dezelfde sessietijd. Pauzeren stopt de klok én de microfoon; hervatten bepaalt opnieuw de relatie tussen de audio- en sessieklok. Scoreverwerking gebruikt de audioframetijd, niet het moment waarop een widget is getekend. Targets verlopen op de tijd van reeds geanalyseerde PCM, zodat de UI-timer geen target afkeurt terwijl DSP nog onderweg is.

De handmatig instelbare compensatie in milliseconden wordt van de audio-eventtijd afgetrokken. Een positieve waarde compenseert vertraagde input. Deze instelling is geen automatische meting. Er is nog geen backingtrack/audioweergave; outputlatency is daarom nog niet gekwalificeerd. Bluetooth is niet geschikt als basis voor strakke timing zonder afzonderlijke metingen.

Timingvensters zijn configureerbaar: inclusief ±50/100/160 ms. Verkeerde noten verdienen geen punten; een target dat niet op tijd correct is gespeeld, verloopt. De rustige modus gebruikt geen timingvensters en kent geen Perfect-beoordeling toe.

## Levenscyclus

Eén appbrede audio-inputservice voorkomt overlappende native opnames bij snelle schermwisselingen. Start/stop-operaties zijn geserialiseerd. Stop tijdens een permissiedialoog annuleert de latere start. Bij verlaten van het scherm, achtergrond, onderbreking of streamfout stopt de opname. Hervatten vraagt een bewuste gebruikersactie. Worker, subscriptions en recorder worden opgeruimd. Native onderbrekingen en routewisselingen vereisen aanvullende fysieke tests.

## Voorlopige desktopmeting

`dart run tool/benchmark_audio.dart`: 100 YIN-frames, 4096 samples, synthetische E2 met harmonischen, na 30 warm-upframes. Tijdens deze sessie: mediaan **1,65 ms**, p95 **2,20 ms**, tegenover een hopbudget van 21,33 ms. Dit is Dart JIT op deze Mac, geen mobiele performancekwalificatie. FPS, dropped frames, energieverbruik en end-to-end latency zijn nog niet op telefoons gemeten.
