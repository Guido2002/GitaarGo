# Validatie op fysieke apparaten

Nog uit te voeren op minimaal één Android-telefoon en één iPhone. De emulatorintegratietest bewijst uitsluitend opstarten en navigatie.

1. Installeer de app schoon. Rond onboarding af zonder microfoonvraag. Open Leren/Profiel zonder toestemming.
2. Start Stemmen; weiger toestemming. Controleer de uitleg. Geef toestemming in systeeminstellingen en probeer opnieuw.
3. Speel iedere losse snaar E2/A2/D3/G3/B3/E4. Vergelijk met een betrouwbaar stemapparaat. Noteer centsfout, confidence, stabilisatietijd, microfoonafstand, toestel/OS en omgeving. Herhaal zachter, met achtergrondruis, galm en harmonischen. Stilte mag nooit een correcte score geven.
4. Controleer alle zeven stemmingen, handmatige snaarkeuze, referentie 442 Hz en de ruisdrempel. Laat een toon uitsterven; onzekere informatie moet verdwijnen.
5. Speel een rustige oefening. Aangehouden tonen mogen slechts eenmaal meetellen. Controleer verkeerde tonen, opnieuw aanslaan, twee dezelfde noten en een legato-overgang.
6. Speel Solo Hero met losse snaren. Meet inputbuffering, onset-/detectieverschil en timing via externe referentie (bijvoorbeeld gelijktijdige video/audio). Stel pas daarna timingcompensatie af. Test de ±50/100/160 ms grenzen met reproduceerbare input, niet met alleen menselijke timing.
7. Pauzeer, hervat, verlaat het scherm, vergrendel de telefoon, open een andere app en veroorzaak een telefoongesprek. Controleer dat de microfoon stopt en nooit vanzelf hervat. Wissel audio-route en test USB indien beschikbaar.
8. Heropen de app na een afgeronde sessie: resultaat, XP en instellingen blijven bestaan. Probeer opnieuw opslaan bij een geïnduceerde opslagfout; sessie/XP mogen niet verdubbelen. Test de daguitdaging en kalenderreeks rond middernacht, zomertijd en een tijdzonewissel.
9. Test systeemtekst tot 200%, VoiceOver/TalkBack, licht/donker, verminderde beweging, verschillende schermformaten en teruggebaren. Game-layout is primair voor portrait; landscape is nog niet gekwalificeerd.
10. Profile in release/profile mode met DevTools: UI/raster-framebudget, dropped frames, workerbelasting, geheugen en stroomverbruik. Test minimaal twintig minuten onafgebroken en herhaald starten/stoppen.

Bewaar meetresultaten met datum, model, OS, build, route, gitaar, sample-rate en compensatie. Geen fysieke resultaten ingevuld zolang ze niet daadwerkelijk zijn gemeten.
