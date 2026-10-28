# Implementatierapport — 28 oktober 2026

De repository bevatte alleen README, licentie en Git-configuratie. Er is een Flutter Android/iOS-project opgebouwd. De opdracht is uitgevoerd met voorrang voor de eerste vertical slice, zoals de masterprompt voorschrijft. De volledige productvisie is nog niet afgerond.

## Fase 1: fundament

Geïmplementeerd in `lib/app`, `lib/main.dart`, `lib/core/database`, `lib/features/onboarding`, `android` en `ios`: Riverpod, go_router, Material 3, donker/licht, Nederlands, vijf tabs, vierstaps onboarding, lokale Drift/SQLite-opslag en platformpermissies. Er is geen account/backend. Android start en navigeert in de emulator. iOS moet nog worden gebouwd en getest met een volledige Apple-toolchain.

## Fase 2: muziektheorie

`lib/core/music/music.dart` en `lib/core/widgets/chord_diagram.dart`: frequentie/MIDI/cents, zeven stemmingen, twaalf gecontroleerde akkoordvoicings, dagselectie op kalenderdatum en schaalbare diagrammen met open/gedempte snaren, vingernummers en F-barré. `assets/exercises/library.json` bevat drie originele oefeningen. Geen volledige akkoordbibliotheek, alternatieve voicings of interactieve positie-editor.

## Fase 3: audio en tuner

`lib/core/audio` en `lib/features/tuner`: PCM-ringbuffer, aparte DSP-isolate, YIN, stiltefilter, confidence, stabilisatie, onsetdetectie, smoothing, Hz/cents, stemmingen en handmatige snaarkeuze. Start/stop is geserialiseerd en lifecycle-afhankelijk. Synthetische audio is getest via de daadwerkelijke PCM-adapter en worker. De acceptatie op fysiek gespeelde gitaren is nog niet aangetoond. De latency-instelling is een handmatige schatting.

## Fase 4: eerste Solo Hero

`lib/core/scoring`, `lib/features/solo_hero` en `lib/features/practice`: Flame-notenbaan, zes snaren, hitlijn, voorbereidingstijd, monotone klok, echte audio-input, timingvensters, combo/multiplier, pauzeren/hervatten, resultaat en opslag. Er is geen tap-om-punten-te-krijgen-input. Een rustig alternatief beoordeelt alleen toonhoogte. Alternatieve vingerzettingen worden geaccepteerd zolang de gemeten MIDI-noot klopt. Geen begeleidende muziek, sustain-scoring, tempowisselingen of gekwalificeerde landscape-gameplay.

## Fase 5: leren

`lib/features/learning`: akkoorddiagramstudie, uitleg over losse snaren, een A-mineur-pentatonische oefening en chromatische vingertraining. Volledige akkoordherkenning, akkoordwisselingen, ritme-/lescurriculum en Speed Trainer zijn niet geïmplementeerd. De interface geeft deze beperking expliciet aan en beloont geen onbewezen akkoordherkenning.

## Fase 6: voortgang

`lib/core/scoring/rewards.dart`, database en `lib/features/home`/`profile`: sessieresultaten, centrale XP-regels, levels, 10-noten-daguitdaging, kalenderstreak, vier mijlpalen en XP-weekgrafiek. Opslag en beloningen zijn één transactie; de sessie-ID maakt opnieuw opslaan idempotent. Geen XP zonder correcte invoer. Instellingen worden opgeslagen/toegepast. Export is JSON via het klembord. De volledige achievementcatalogus, akkoordstatistieken, historische tempostatistieken en 10-noten-achter-elkaar-uitdaging zijn nog vervolgwerk; de huidige daguitdaging vraagt tien correcte noten in totaal.

## Fase 7: validatie en distributie

Er zijn unit-, DSP-, opslag-, widget-, golden- en emulatorintegratietests. Android debug- en release-APK's zijn gebouwd. Release gebruikt voorlopig de debug-testkey. Geen store-upload, signing voor distributie, TestFlight, fysieke audioacceptatie of iOS-releasevalidatie.

Uitgevoerd op deze ontwikkelomgeving:

- `flutter pub get`: geslaagd.
- `flutter analyze`: geen issues.
- `flutter test`: **39 tests geslaagd**, inclusief DSP op 44,1/48 kHz, PCM-isolate, permissieweigering/startannulering, scoring, beloningen, heropenen van SQLite, onboarding, navigatie en licht/donker-goldens met 180% tekstcontrole.
- `flutter test integration_test/app_flow_test.dart -d emulator-5554`: **1 test geslaagd**, Android API 37-emulator, opstarten/onboarding/navigatie.
- Android debug-APK en release-APK: geslaagd; release is met de debug-testkey ondertekend.
- `flutter build ios --release --no-codesign`: niet geslaagd (`Application not configured for iOS`); `flutter doctor` meldt onvolledige Xcode en ontbrekende CocoaPods. Geen iOS-build of fysieke iPhone-test uitgevoerd.
- `dart run tool/benchmark_audio.dart`: desktop mediaan 1,65 ms / p95 2,20 ms per YIN-venster. Geen mobiele FPS- of latencyclaim.
- `git diff --check`: geslaagd.

De dark/light-goldens zijn visueel bekeken; diagrammarkeringen en vingernummers zijn zichtbaar. `docs/AUDIO.md` legt timing en beperkingen vast; `docs/DEVICE_VALIDATION.md` beschrijft de nog uit te voeren fysieke controles.

## Dependencies

Versies zijn via pub.dev en de daadwerkelijke resolver gecontroleerd; de exacte resolved versies staan in `pubspec.lock`. De broncode en licentiebestanden van de toegevoegde packages zijn lokaal geïnspecteerd. Flutter 3.47.8 / Dart 3.13.7 kon deze combinatie analyseren, testen en voor Android bouwen.

| Package | Versie | Licentie | Reden |
|---|---|---|---|
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | 3.4.3 | MIT | state en dependency injection |
| [go_router](https://pub.dev/packages/go_router) | 18.1.1 | BSD-3-Clause | tab- en oefenroutes |
| [record](https://pub.dev/packages/record) | 7.1.2 | BSD-3-Clause | PCM16-stream en platformaudiosessie |
| [flame](https://pub.dev/packages/flame) | 1.38.2 | MIT | renderloop en notenbaan |
| [drift](https://pub.dev/packages/drift) | 2.35.3 | MIT | SQLite, transacties en achtergrondexecutie |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.8.0 | MIT | native SQLite-runtime |
| [path_provider](https://pub.dev/packages/path_provider) | 2.1.6 | BSD-3-Clause | application-supportdirectory |
| [path](https://pub.dev/packages/path) | 1.9.1 | BSD-3-Clause | platformbestendige databasepaden |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | 2.0.0 | MIT | platformiconen die Flutter gebruikt |

Flutter-localisaties komen uit de SDK. Geen chartpackage nodig voor de kleine toegankelijke weekgrafiek. Manrope is lokaal meegeleverd met SIL OFL 1.1 in `assets/fonts/OFL.txt`, ook bereikbaar via het licentiescherm. Alle oefeningen zijn nieuw geschreven voor deze repository en vallen onder de projectlicentie; er zijn geen songs of externe backingtracks opgenomen.

## Volgende technische stap

Voer eerst de fysieke Android-/iPhone-audiometingen uit. Gebruik die resultaten om onsetdetectie, daadwerkelijke sample-rate, routegedrag en latency te verbeteren vóór complexere of snellere oefeningen worden toegevoegd. Voeg vervolgens opgenomen gitaarfixtures toe en kwalificeer akkoordherkenning afzonderlijk met confidence en negatieve voorbeelden.


## Toevoeging 0.2.0: releases en in-app updates

GitHub-releasecontrole bij opstarten, handmatige controle in Profiel, downloaden/annuleren, grootte- en SHA-256-controle en rechtstreeks openen van Androids installer zijn toegevoegd. Nieuwe versies worden gepubliceerd met `tool/release_android.py --publish`; dat bouwt en uploadt APK/checksums voordat een conceptrelease openbaar wordt. De APK blijft met de bestaande sleutel ondertekend. Er zijn negen nieuwe updater-tests voor semver, releasekeuze, API-fouten, volledige/afgebroken/beschadigde/geannuleerde transfers en checksums; de Flutter-suite telt nu 48 geslaagde tests. Zie `docs/UPDATES.md`.
