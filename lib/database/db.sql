CREATE TABLE recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  preparationTime INTEGER NOT NULL,
  difficulty TEXT NOT NULL,
  portions INTEGER NOT NULL,
  ingredients TEXT NOT NULL,
  notes TEXT,
  isRecommended INTEGER NOT NULL DEFAULT 0
  isFavorite INTEGER NOT NULL DEFAULT 0
);

-- Nota: ingredients lo salviamo come testo separato da virgole
--L’app utilizza SQLite locale tramite il package sqflite per garantire la persistenza dei dati anche dopo la chiusura dell’app. Le ricette vengono salvate nella tabella recipes, mentre le altre entità dell’app possono essere modellate in tabelle dedicate.