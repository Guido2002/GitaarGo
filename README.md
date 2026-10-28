# GitaarGo

**Speel. Leer. Groei.** Nederlandstalige Flutter-app voor Android en iOS. Versie 0.2.0 bevat de eerste vertical slice van de productvisie: stemmen → losse noten oefenen → echte audiofeedback → lokaal opgeslagen resultaten, plus een eerste Solo Hero-oefenbibliotheek.

## Android installeren en bijwerken

Download de [nieuwste GitHub-release](https://github.com/Guido2002/GitaarGo/releases/latest) en installeer de universele `GitaarGo-<versie>.apk` één keer. Vanaf **0.2.0** krijg je toekomstige updates rechtstreeks in de app: **Profiel → App-updates → Update downloaden → Installeren**. De app controleert ook automatisch bij het opstarten; dit kun je uitschakelen.

Zie [in-app updates en releases publiceren](docs/UPDATES.md). Als de eerste installatie niet lukt, kan `./tool/install_android.sh` via USB installeren en de exacte Android-foutmelding tonen. Zie ook de [installatieanalyse](docs/INSTALLATION.md).

## Starten

Ontwikkeld met Flutter **3.47.8** en Dart **3.13.7**. Gebruik een fysiek apparaat voor betrouwbare microfoontests.

```sh
flutter pub get
flutter run
```

Geen account of backend nodig. De microfoon start alleen via de knop Luisteren/Start met microfoon. Audio wordt lokaal verwerkt en niet opgeslagen. Alleen de optionele updatefunctie gebruikt internet om GitHub te raadplegen. Bij geweigerde toestemming blijft de bibliotheek bruikbaar; geef toestemming via de systeeminstellingen om te luisteren.

## Beschikbaar

- Vierstaps onboarding en vijf Nederlandse hoofdtabs.
- In-app GitHub-updates met voortgang, annuleren, SHA-256-controle en Android-installatievenster.
- Donker/licht thema, schaalbare tekst en linkshandige akkoorddiagrammen.
- Chromatische YIN-tuner met Hz, cents, smoothing, zeven stemmingen en handmatige snaarkeuze.
- Rustige nootoefeningen en Flame Solo Hero met echte toonhoogte- en timingbeoordeling, combo's, pauzeren en resultaten.
- Drie originele oefeningen in JSON; twaalf akkoorddiagrammen met open/gedempte snaren, vingernummers en een F-barré.
- SQLite/Drift-opslag, XP, levels, daguitdaging, oefenreeks, mijlpalen en weekgrafiek.
- Instelbare A4-referentie, ruisdrempel, geschatte timingcompensatie, haptiek en stemming.
- JSON-export via het klembord, statistieken wissen en privacy-/licentie-informatie.

Geen succesvolle detectie zonder audio. Een aangehouden noot telt eenmaal. Snaar/fret in de game zijn een speeladvies, geen gemeten positie. De rustige modus beoordeelt alleen toonhoogte.

## Controles

```sh
flutter analyze
flutter test
flutter test integration_test/app_flow_test.dart -d <apparaat-id>
flutter build apk --debug
flutter build apk --release
flutter build ios --release --no-codesign
dart run tool/benchmark_audio.dart
```

De Android-releasebuild gebruikt momenteel de Flutter-debugsleutel en is uitsluitend voor testinstallatie. Stel eigen signing in vóór distributie. De iOS-bronnen en microfoonpermissie zijn toegevoegd; hier kon geen iOS-build worden gemaakt wegens ontbrekende volledige Xcode/CocoaPods-configuratie.

De golden-tests gebruiken meegeleverde lettertypen en een vaste kalenderdatum. Update beelden alleen na visuele beoordeling met `flutter test --update-goldens test/layout_test.dart`.

## Status en vervolgwerk

Dit is een eerste werkende implementatie, **geen afgeronde uitvoering van alle zeven productfasen**. Volledige akkoordherkenning, akkoordwisselingen, Speed Trainer, een uitgebreide les-/akkoordbibliotheek, automatische latencykalibratie en store-distributie volgen nog. Er zijn nog geen fysieke Android-/iPhone-audiometingen of opgenomen gitaarfixtures uitgevoerd. De audio-engine is getest met synthetische PCM, inclusief grondtonen en harmonischen.

Zie [implementatierapport](docs/IMPLEMENTATION.md), [audio-ontwerp](docs/AUDIO.md) en [apparaatvalidatie](docs/DEVICE_VALIDATION.md).
