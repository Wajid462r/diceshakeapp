# Dice Shake App

Dice Shake App è un’applicazione mobile sviluppata con Flutter che consente di simulare il lancio di dadi virtuali tramite interazione fisica (shake del dispositivo) e input manuale. Il progetto integra sensori hardware, animazioni fluide e persistenza locale dei dati, offrendo un’esperienza realistica e interattiva.

---

## Descrizione

L’app permette di lanciare uno o più dadi virtuali attraverso lo scuotimento del dispositivo o tramite un pulsante dedicato. Il sistema utilizza l’accelerometro per rilevare il movimento e attivare automaticamente il lancio. I risultati vengono animati in tempo reale e salvati in una cronologia locale consultabile.

---

## Funzionalità principali

* Rilevamento dello shake tramite accelerometro
* Lancio manuale dei dadi
* Supporto fino a 3 dadi simultanei
* Configurazione personalizzata delle facce (D1–D10)
* Animazioni di rotazione durante il lancio
* Calcolo automatico del totale
* Cronologia dei lanci con timestamp
* Eliminazione completa dei dati salvati

---

## Tecnologie utilizzate

* Flutter (UI cross-platform) – [https://flutter.dev](https://flutter.dev)
* sensors_plus (accelerometro) – [https://pub.dev/packages/sensors_plus](https://pub.dev/packages/sensors_plus)
* sqflite (database locale SQLite) – [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite)
* path_provider (accesso file system) – [https://pub.dev/packages/path_provider](https://pub.dev/packages/path_provider)
* intl (formattazione date) – [https://pub.dev/packages/intl](https://pub.dev/packages/intl)

---

## Architettura del progetto

```
dice_shake_app/
├── lib/
│   └── main.dart          # Logica principale e UI
├── pubspec.yaml           # Dipendenze progetto
└── README.md              # Documentazione
```

---

## Funzionamento

L’app calcola l’accelerazione del dispositivo sui tre assi (x, y, z). Quando il valore supera una soglia definita, viene attivato il lancio dei dadi. Durante il processo, i valori cambiano rapidamente per simulare il movimento reale. Al termine dell’animazione, il risultato viene salvato in un database locale SQLite.

---

## Persistenza dei dati

Ogni lancio viene salvato localmente con:

* valori dei dadi in formato JSON
* totale
* configurazione delle facce
* timestamp del lancio

I dati vengono recuperati per la visualizzazione della cronologia.

---

## Requisiti

* Flutter SDK >= 3.0.0
* Dispositivo fisico con accelerometro
* Android o iOS

---

## Note

* Lo shake non funziona sugli emulatori
* Nessun permesso speciale richiesto
* Ottimizzato per dispositivi mobili

---

## Possibili miglioramenti

* Effetti sonori e vibrazione
* Supporto dadi avanzati (D12, D20)
* Esportazione cronologia
* Miglioramenti UI/UX

---

## Licenza

Progetto didattico
