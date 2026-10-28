# Updates vanuit GitaarGo

Vanaf **0.2.0** kun je nieuwe Android-versies binnen de app ophalen, zoals bij ChromecastRemote.

## Voor gebruikers

Installeer 0.2.0 één keer via de [GitHub-release](https://github.com/Guido2002/GitaarGo/releases/tag/v0.2.0). Daarna:

1. GitaarGo controleert bij het opstarten op een nieuwere stabiele versie. Een melding op Vandaag verwijst naar Profiel.
2. Open **Profiel → App-updates**. Je kunt daar ook zelf op **Controleren op updates** tikken.
3. Tik **Update downloaden**. Een voortgangsbalk verschijnt; annuleren is mogelijk.
4. Na controle van grootte en SHA-256 verschijnt **Installeren**. Android opent zijn eigen installatievenster.
5. Geef GitaarGo desgevraagd toestemming om apps te installeren, keer terug en tik opnieuw op Installeren. Bevestig vervolgens de update in Android.

Bijwerken met dezelfde ondertekeningssleutel bewaart oefengegevens en instellingen. Het openen van de installer betekent nog niet dat Android de update heeft voltooid. GitaarGo toont bij de volgende start de daadwerkelijk geïnstalleerde versie.

Automatische controles kun je uitschakelen in Profiel. Downloaden en installeren blijven een bewuste gebruikersactie. Zonder internet blijven de oefenfuncties werken. De updater deelt geen audio, oefengegevens of persoonlijke statistieken; GitHub ontvangt de normale netwerkverzoeken voor versiecontrole en downloads.

## Releases publiceren vanaf de Mac

De release-APK is universeel: ARM32, ARM64 en x86-64. De updater kiest alleen `GitaarGo-<versie>.apk` en negeert concepts en prereleases. Publiceer altijd een nieuwe versienaam én hoger Android-buildnummer.

1. Verhoog `version` in `pubspec.yaml`, bijvoorbeeld `0.2.1+4`.
2. Voeg `docs/releases/0.2.1.md` toe met release-notities.
3. Commit je wijzigingen.
4. Voer uit:

```sh
python3 tool/release_android.py --publish
```

Dit haalt dependencies op, analyseert en test de app, bouwt de APK, controleert package/versie/build/architecturen/ondertekening, maakt een checksum en pusht commit/tag. Vervolgens uploadt het script APK en `SHA256SUMS.txt` naar een conceptrelease. Pas wanneer GitHub de verwachte uploadchecksums teruggeeft, wordt de release openbaar en de nieuwste release. De app vindt die daarna automatisch bij een volgende start of handmatige controle.

GitHub-toegang loopt via de bestaande git credential helper op de Mac of `GH_TOKEN`/`GITHUB_TOKEN`. Credentials worden niet in bestanden geschreven. Het script weigert een vuile werkboom, een tag op een andere commit of het vervangen van een reeds gepubliceerde release. Voor alleen lokaal bouwen gebruik je hetzelfde script zonder `--publish`.

**Ondertekening:** de testversies gebruiken de bestaande Android-debugkey op deze Mac. Die is niet opgeslagen in de repository. Bouw volgende testreleases op dezelfde Mac/met dezelfde sleutel, anders accepteert Android ze niet als update. Voor Play Store-distributie is een aparte signingstrategie nodig. Een GitHub Actions-runner krijgt daarom niet automatisch toegang tot de gedeelde privésleutel van deze Mac.

## Technisch

- `lib/features/update/update_service.dart`: GitHub Releases, semver, alleen eigen HTTPS-downloadlocaties, volledige stream, grootte-/hashcontrole, partial-file cleanup.
- `update_controller.dart`: geïnstalleerde versie via `package_info_plus`, annulering, foutstatus en installerhandoff via `open_filex`/FileProvider.
- `update_panel.dart`: Nederlandse bediening, automatische controle en instelbare voorkeur.
- APK-bestanden blijven in de eigen appcache. De FileProvider geeft alleen toegang tot `gitaargo-updates/`; er is geen media-/opslagpermissie nodig.
- Het product gebruikt geen GitHub-token; publieke releases zijn zonder account leesbaar.
- De bronaanpak is gebaseerd op de updater in `Guido2002/ChromecastRemote`, uitgebreid met SHA-256-controle en expliciete keuze van de universele APK.


## Uitgevoerde controle — 28 oktober 2026

Met expliciete toestemming is `Guido2002/GitaarGo` openbaar gemaakt, inclusief broncode en geschiedenis. De bestaande `v0.2.0`-release is zonder GitHub-aanmelding bereikbaar. APK en `SHA256SUMS.txt` zijn gepubliceerd; de serverdigest van de APK komt overeen met de lokale SHA-256-controle.

- `flutter analyze`: geen issues; 48 Flutter-tests geslaagd.
- Android-emulator: appstart/navigatie, lokale FileProvider-handoff én de volledige publieke download-/hash-/installerhandoff-tests geslaagd.
- RG406H met Android 13: bestaande versie `0.1.1` via `adb install -r` bijgewerkt naar `0.2.0` (build 3), zonder uninstall of gewiste appgegevens.
- De handoff-tests controleren het openen van Androids installer, niet of de gebruiker een volgende installatie daadwerkelijk bevestigt.
- De releasehost-controle blijft in het publicatiescript staan: toekomstige private downloadlocaties worden vóór publicatie geweigerd.

De fysieke installatie is bevestigd; dit is geen fysieke validatie van gitaarherkenning of audiolatency.
