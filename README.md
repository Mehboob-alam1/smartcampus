# Smart Campus – Sistema integrato di reclami e presenze

Sistema unificato per **Digital Complaint Box** e **Smart Attendance** (presenze con riconoscimento facciale) per campus universitari.

## Moduli

1. **Digital Complaint Box**  
   Gli studenti inviano reclami (alloggio, trasporti, mensa, altro), ne seguono lo stato e ricevono notifiche. Gli amministratori filtrano, aggiornano e rispondono ai reclami.

2. **Smart Attendance**  
   Registrazione del volto una sola volta; in seguito le presenze vengono rilevate automaticamente (backend con OpenCV + DeepFace). Report presenze per docenti e admin.

## Stack tecnologico

- **App mobile**: Flutter (studenti + interfaccia admin)
- **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
- **Face recognition**: Python (FastAPI, OpenCV, DeepFace)

## Struttura progetto

```
smartcampus/
├── lib/                    # App Flutter
│   ├── main.dart
│   ├── app_router.dart
│   ├── theme/
│   ├── models/
│   ├── services/
│   ├── screens/
│   │   └── admin/
│   └── widgets/
├── face_recognition_service/   # API Python
│   ├── app.py
│   ├── face_utils.py
│   └── requirements.txt
├── firestore.rules
├── firestore.indexes.json
└── README.md
```

## Configurazione

### 1. Firebase

1. Crea un progetto su [Firebase Console](https://console.firebase.google.com).
2. Abilita **Authentication** (Email/Password) e **Firestore**, **Cloud Messaging**.
3. Installa FlutterFire CLI e configura l’app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Carica regole e indici:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

### 2. App Flutter

```bash
cd smartcampus
flutter pub get
```

Per **Android**: in `android/app/build.gradle.kts` verifica che sia applicato il plugin `com.google.gms.google-services`.  
Per **iOS**: aggiungi la capacità Push Notifications e il file `GoogleService-Info.plist` generato da `flutterfire configure`.

### 3. Backend Face Recognition (Python)

```bash
cd face_recognition_service
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

L’API espone:

- `POST /register`: registrazione volto (file immagine + `user_id`, `user_email`, `user_name`).
- `POST /verify`: verifica volto e restituisce l’utente riconosciuto (per marcare presenza).
- `GET /health`: health check.

Nell’app Flutter, in `lib/services/attendance_service.dart`, imposta `faceServiceBaseUrl` con l’indirizzo del server (es. `http://10.0.2.2:8000` per emulatore Android, `http://localhost:8000` per iOS simulator).

### 4. Utente admin

Dopo la prima registrazione, imposta il campo `isAdmin: true` nel documento dell’utente in Firestore (`users/<uid>`) per abilitare la gestione reclami e i report presenze.

## Esecuzione

- **Flutter**: `flutter run`
- **Face API**: dalla cartella `face_recognition_service`, `uvicorn app:app --reload --port 8000`

## Indici Firestore

Se Firestore segnala indici mancanti, usare il file `firestore.indexes.json` e eseguire `firebase deploy --only firestore:indexes`, oppure creare gli indici dal link suggerito nei messaggi di errore.

## Licenza

Progetto didattico / capstone.
