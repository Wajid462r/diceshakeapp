Dice Shake App

Dice Shake App è un'applicazione mobile sviluppata con Flutter che consente di simulare il lancio di dadi virtuali utilizzando sia input manuale che interazione fisica tramite accelerometro. L'app è progettata per offrire un'esperienza fluida, moderna e realistica, ed è adatta a giochi da tavolo digitali o utilizzo didattico.

Features
Rilevamento dello scuotimento del dispositivo (shake detection)
Lancio manuale dei dadi tramite pulsante
Supporto fino a 3 dadi simultanei
Configurazione dinamica del numero di facce per ciascun dado (D1–D10)
Animazioni fluide durante il lancio
Calcolo automatico del totale
Persistenza locale dei risultati
Visualizzazione della cronologia dei lanci
Possibilità di cancellare la cronologia
Tech Stack
Flutter – Framework UI cross-platform
sensors_plus – Accesso ai sensori del dispositivo
sqflite – Database SQLite locale
path_provider – Gestione del file system
intl – Formattazione date e orari
How It Works

L'app utilizza i dati dell'accelerometro per rilevare movimenti del dispositivo. Quando l'accelerazione supera una soglia definita, viene attivato automaticamente il lancio dei dadi.

Durante il lancio:

I valori vengono aggiornati dinamicamente per simulare il movimento reale
Viene eseguita un'animazione di rotazione
Al termine, viene calcolato il totale e salvato nel database

Un sistema di cooldown previene attivazioni multiple ravvicinate.

Data Persistence

I risultati dei lanci vengono salvati in un database locale SQLite.

Per ogni lancio vengono memorizzati:

valori dei dadi (formato JSON)
totale
configurazione delle facce
timestamp

I dati sono successivamente recuperati per la visualizzazione della cronologia.

Project Structure
dice_shake_app/
├── lib/
│   └── main.dart          # Entry point e logica principale
├── pubspec.yaml           # Dipendenze
└── README.md              # Documentazione
Installation
Prerequisites
Flutter SDK >= 3.0.0
Dispositivo fisico con accelerometro
Setup
git clone <repository-url>
cd dice_shake_app
flutter pub get
flutter run
Notes
Lo shake detection non è supportato negli emulatori
L'app è compatibile con Android e iOS
Non sono richiesti permessi speciali per l'uso dell'accelerometro
Possible Improvements
Aggiunta di effetti sonori e vibrazione
Supporto a più tipi di dadi (es. D12, D20)
Esportazione della cronologia
Miglioramenti UI/UX
License

Questo progetto è stato realizzato a scopo didattico.
