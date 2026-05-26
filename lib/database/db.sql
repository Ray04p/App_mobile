--Tabella principale delle Ricette 
CREATE TABLE recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  preparationTime INTEGER NOT NULL,
  difficulty TEXT NOT NULL,
  portions INTEGER NOT NULL,
  notes TEXT,
  imagePath TEXT,
  isRecommended INTEGER NOT NULL DEFAULT 0,
  isFavorite INTEGER NOT NULL DEFAULT 0
);

--Tabella relazionale per gli Ingredienti delle Ricette
CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recipeId INTEGER NOT NULL,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,      
  unit TEXT NOT NULL,          
  FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
);