# 🎲 Dice Shake App

App Flutter semplice per lanciare dadi virtuali con lo shake del dispositivo, perfetta per giochi da tavolo!

## Funzionalità

✨ **Shake Detection**: Scuoti il dispositivo per lanciare automaticamente i dadi
🎲 **1 o 2 Dadi**: Scegli tra lanciare 1 o 2 dadi
🎨 **Animazioni Fluide**: Rotazione e cambio rapido dei valori durante il lancio
📱 **Lancio Manuale**: Pulsante per lanciare senza shake
🎯 **Calcolo Totale**: Visualizzazione automatica della somma

## Tecnologie Utilizzate

- **Flutter**: Framework UI cross-platform
- **sensors_plus**: Pacchetto per accedere all'accelerometro del dispositivo
- **Material Design 3**: UI moderna e pulita

## Come Funziona

L'app utilizza l'accelerometro per rilevare quando il dispositivo viene scosso:

1. **Rilevazione Shake**: Monitora l'accelerazione su tutti e tre gli assi (x, y, z)
2. **Soglia**: Quando l'accelerazione supera 15.0 m/s², viene rilevato lo shake
3. **Cooldown**: Un timer di 1 secondo previene lanci multipli accidentali
4. **Animazione**: I dadi ruotano e cambiano valore per 500ms
5. **Risultato**: Viene mostrato il valore finale e il totale

## Installazione

1. Assicurati di avere Flutter installato
2. Clona o copia i file del progetto
3. Esegui:

```bash
cd dice_shake_app
flutter pub get
flutter run
```

## Requisiti

- Flutter SDK >= 3.0.0
- Dispositivo fisico con accelerometro (lo shake non funziona nell'emulatore)

## Permessi Android

L'app non richiede permessi speciali, l'accelerometro è accessibile di default.

## Struttura del Codice

```
dice_shake_app/
├── lib/
│   └── main.dart          # Codice principale dell'app
├── pubspec.yaml           # Dipendenze e configurazione
└── README.md              # Questo file
```

## Personalizzazioni Possibili

- Modificare `_shakeThreshold` per rendere lo shake più o meno sensibile
- Cambiare `_shakeCooldownMs` per variare il tempo tra un lancio e l'altro
- Aggiungere più dadi (modificare il selector)
- Cambiare colori e stile dell'interfaccia

## Note

- Per testare l'app è necessario un dispositivo fisico
- L'accelerometro negli emulatori non supporta lo shake detection
- L'app è ottimizzata per funzionare su Android e iOS

## Licenza

Progetto didattico
