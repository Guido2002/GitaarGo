# Android-testinstallatie — historische analyse 0.1.1

De huidige release is **0.2.0** met in-app updates. Zie [Updates](UPDATES.md). Onderstaande APK-metingen en foutanalyse zijn van de eerdere 0.1.1-build.

Er is een compacte, zelfstandig installeerbare APK voor ARM64-Android gebouwd:

`build/releases/GitaarGo-0.1.1-arm64.apk`

De [RG406H-specificaties van Anbernic](https://anbernic.com/products/rg-406h) vermelden de Unisoc T820 en Android 13. De daadwerkelijke firmware van het toestel is niet via USB uitgelezen. Deze APK bevat alleen `arm64-v8a`, vereist minimaal Android 7/API 24 en is bedoeld voor direct installeren, niet voor Google Play. Het is één APK: er zijn geen aanvullende splitbestanden nodig.

## Onderzochte fix in ChromecastRemote

De lokale checkout en GitHub `main` van `Guido2002/ChromecastRemote` zijn gecontroleerd. De relevante commits zijn:

- [`d6045be`](https://github.com/Guido2002/ChromecastRemote/commit/d6045be2e967c9a306736884b9f13d23228a5f7f): eigen APK-download naar lokale opslag; controle van ontvangen byteaantal tegen de verwachte bestandsgrootte; openen via `open_filex`/FileProvider met APK-MIME-type; `REQUEST_INSTALL_PACKAGES` voor updates vanuit de app.
- [`a77aada`](https://github.com/Guido2002/ChromecastRemote/commit/a77aada5041e10cf979ad0673ba650930fd1b010): onderscheid tussen het openen van de installer en daadwerkelijk installeren; platformfouten tonen en vervolgbegeleiding na openen.

De Gradle-geschiedenis bevat geen aparte installatie-/ondertekeningsfix. De lokaal gebouwde ChromecastRemote-release en GitaarGo-release gebruiken dezelfde debug-certificaatfingerprint. Dat vergelijkt de builds op deze Mac; het bewijst niets over een eventueel elders gebouwde APK.

Deze updater-route kan pas werken zodra de app geïnstalleerd is. Alleen `REQUEST_INSTALL_PACKAGES` aan GitaarGo toevoegen zou de eerste installatie vanuit Files by Google niet veranderen: die toestemming hoort bij de app die de installer start.

Het direct toepasbare deel is overgenomen in de USB-installatieroute: `tool/verify_apk.py` controleert vóór installatie de archiefintegriteit en, wanneer een passende `SHA256SUMS.txt` aanwezig is, de exacte checksum. Het installatiescript stopt bij beschadigde/onvolledige bestanden en geeft de echte Android-installatiefout door. Android controleert zelf de ondertekening. Er wordt geen succes gemeld op basis van alleen het openen van een scherm.

## Automatisch annuleren vanuit Files by Google

Er zijn [gebruikersmeldingen](https://www.reddit.com/r/motorola/comments/1vil3uk/when_i_try_to_install_apks_the_installation_is/) waarbij dezelfde APK via een andere app wel installeert. Dit blijft een mogelijke installatieroutekwestie, geen bevestigde diagnose van deze installatie.

Een praktische alternatieve route is **Openen met → Pakketinstallatieprogramma** of openen vanuit de browserdownloadlijst. De gecontroleerde USB-route hieronder kan de APK zonder Files by Google aan Android aanbieden en de daadwerkelijke foutcode uitlezen.

## Wat is aangepast?

- Versie 0.1.1, buildnummer 2. De package-ID en ondertekeningssleutel zijn behouden.
- Native libraries zijn gecomprimeerd en worden tijdens installatie uitgepakt (`useLegacyPackaging = true`). Dit verkleint het downloadbestand en vermijdt afhankelijkheid van in-place laden uit de APK door de OEM-installer. Dit is een compatibiliteitsmaatregel, geen bewezen diagnose van de oorspronkelijke fout.
- Microfoonhardware is expliciet optioneel. De bibliotheek kan ook op een handheld zonder ingebouwde microfoon worden gebruikt; audiofuncties vereisen uiteraard wel werkende invoer.
- Eigen plectrum/gitaar-icoon met Android adaptive/themed icons en alle iOS-icoonformaten.
- De distributiekopie heeft een duidelijke bestandsnaam en een SHA-256-controlebestand in dezelfde map.

De oorspronkelijke APK heeft een geldige v2-handtekening en installeert op de beschikbare Android-emulator. Een exacte oorzaak op de RG406H kan daarom nog niet worden bevestigd. Er is geen aangesloten fysiek toestel; een succesvolle emulatorinstallatie bewijst geen succesvolle installatie op de RG406H.

## Uitgevoerde controle

De uiteindelijke 0.1.1-APK is circa **9,5 MB**. `apksigner verify` en `zipalign` slagen; de package heeft versiecode 2, bevat uitsluitend ARM64-native code en declareert microfoonhardware als optioneel. Zowel een update-installatie als een schone installatie op de ARM64/API 37-emulator geeft `Success`; de release-app start daarna. `flutter analyze` meldt geen issues en alle 39 bestaande tests slagen. Alle iOS-iconen zijn gecontroleerd op afmeting en een RGB-bestand zonder alfa. Het icoon is visueel gecontroleerd.

Er is nog geen fysieke RG406H-installatie getest.

## Installeren

Download/kopieer de volledige APK naar de interne opslag en open deze met de Android-bestandsbeheerder. Geef die bestandsbeheerder toestemming om apps te installeren wanneer Android daarom vraagt. Er hoeft geen bestaande GitaarGo-installatie of oefendata te worden verwijderd.

Als Android nog steeds alleen 'App niet geïnstalleerd' toont, geeft ADB de exacte foutcode. Verbind het toestel met een USB-datakabel, schakel USB-debugging in via Androids ontwikkelaarsopties en accepteer de computer op het toestel. Voer op de Mac uit:

```sh
tool/install_android.sh
```

Bij meerdere verbonden apparaten:

```sh
tool/install_android.sh build/releases/GitaarGo-0.1.1-arm64.apk <serienummer>
```

Dit script controleert eerst APK/checksum en toont daarna model, Android-versie, ondersteunde CPU-architecturen en de onveranderde `INSTALL_FAILED_…`-melding. Het gebruikt `adb install -r`: geen uninstall, gewiste data of beveiligingsomzeiling. Meld de foutcode om de werkelijke oorzaak gericht op te lossen.

## Zelf opnieuw bouwen

```sh
flutter build apk --release --target-platform android-arm64 --split-per-abi --android-project-arg=force-version-code-ignoring-abi=true
mkdir -p build/releases
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk build/releases/GitaarGo-0.1.1-arm64.apk
(cd build/releases && shasum -a 256 GitaarGo-0.1.1-arm64.apk > SHA256SUMS.txt)
```

De huidige build gebruikt nog de oorspronkelijke debug-testkey. Een distributiesleutel voor de Play Store is afzonderlijk werk; wissel die niet zomaar voor een bestaande installatie.

## Icoonbron

Het eigen vectorontwerp staat in `assets/branding/gitaargo-icon.svg`; een 1024px-preview staat naast het SVG-bestand. De native Android-vectoren, vijf legacyformaten en iOS-iconen komen uit dezelfde geometrie:

```sh
flutter test tool/generate_icons.dart
python3 tool/package_ios_icons.py
```

De tweede stap gebruikt Pillow om uitsluitend het PNG-alfakanaal van iOS-iconen te verwijderen. De pixels zijn volledig dekkend. Er zijn geen nieuwe runtimepackages toegevoegd voor het icoon.
