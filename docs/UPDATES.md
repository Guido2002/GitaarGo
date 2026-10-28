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


## Controle van releasehosting

De bronrepository bleek bij de eerste release privé. Daarom weigert het releasescript nu vooraf een private downloadrepository: een APK zonder GitHub-login kan daar de release niet ophalen. Een publieke downloadlocatie vereist een expliciete keuze: bronrepository openbaar maken of een aparte publieke repository met alleen binaries/checksums. Er wordt geen GitHub-token in de app ingebouwd.

De lokale Android-FileProvider-handoff is wel getest: een op SHA-256 gecontroleerde release-APK is in de private appcache aangeboden en opent succesvol Androids pakketinstaller op de emulator (`update_local_installer_test.dart`). Dit test de handoff, niet of de gebruiker de installatie uiteindelijk bevestigt. De publieke download-integratietest volgt zodra een publieke release-host is gekozen.
