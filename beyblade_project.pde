// --- PARAMÈTRES GLOBAUX ---
int ETAT_JEU = 0; // 0 = Menu, 1 = Combat
double dt = 0.015;
double t = 0;
double courbure = 0.0015; 
double R_arene = 380;
double g = 9.81;

// --- CONFIGURATION CHOISIE (0, 1 ou 2) ---
int p1_disque = 0; // 0=Standard, 1=Lourd/Petit, 2=Large/Léger
int p1_pointe = 0; // 0=Standard, 1=Attaque (Rapide), 2=Défense (Stable)

int p2_disque = 0;
int p2_pointe = 0;

Toupie t1;
Toupie t2;

void setup() {
  size(1000, 800, P3D); // Fenêtre un peu plus large pour le menu
  noStroke();
  textSize(20);
}

void draw() {
  if (ETAT_JEU == 0) {
    drawMenu();
  } else {
    drawCombat();
  }
}

// -------------------------------------------------------
// LOGIQUE DU MENU
// -------------------------------------------------------
void drawMenu() {
  background(20);
  camera(); hint(DISABLE_DEPTH_TEST); // 2D Overlay
  
  textAlign(CENTER);
  fill(255); textSize(40);
  text("ATELIER BEYBLADE - CONFIGURATION", width/2, 80);
  
  textSize(16);
  text("Appuyez sur ESPACE pour COMBATTRE", width/2, 120);
  
  // --- COLONNE JOUEUR 1 ---
  drawPlayerConfig(width/4, "JOUEUR 1 (Bleu)", p1_disque, p1_pointe, color(100, 200, 255));
  fill(200); textSize(14);
  text("Touches : 'A' (Disque) / 'Z' (Pointe)", width/4, height - 50);

  // --- COLONNE JOUEUR 2 ---
  drawPlayerConfig(3*width/4, "JOUEUR 2 (Rouge)", p2_disque, p2_pointe, color(255, 100, 100));
  fill(200); textSize(14);
  text("Touches : 'O' (Disque) / 'P' (Pointe)", 3*width/4, height - 50);
  
  hint(ENABLE_DEPTH_TEST);
}

void drawPlayerConfig(float x, String name, int d, int p, color c) {
  fill(c); textSize(26);
  text(name, x, 200);
  
  // DISQUE
  fill(255); textSize(20);
  text("TYPE DE DISQUE (Inertie/Masse)", x, 260);
  String dName = "";
  String dStats = "";
  if(d == 0) { dName = "STANDARD"; dStats = "Moyenne partout"; }
  if(d == 1) { dName = "COMPACT LOURD"; dStats = "Densité ++ / Choc ++ / Portée -"; }
  if(d == 2) { dName = "LARGE LÉGER"; dStats = "Stabilité ++ / Choc - / Endurant"; }
  
  fill(255, 255, 0); textSize(24); text("< " + dName + " >", x, 300);
  fill(150); textSize(16); text(dStats, x, 330);
  
  // POINTE
  fill(255); textSize(20);
  text("TYPE DE POINTE (Mvt/Frottement)", x, 400);
  String pName = "";
  String pStats = "";
  if(p == 0) { pName = "EQUILIBRE"; pStats = "Mixte"; }
  if(p == 1) { pName = "ATTAQUE (Plate)"; pStats = "Vitesse ++ / Endurance -- / Instable"; }
  if(p == 2) { pName = "DEFENSE (Fine)"; pStats = "Immobile / Endurance ++ / Stable"; }
  
  fill(255, 255, 0); textSize(24); text("< " + pName + " >", x, 440);
  fill(150); textSize(16); text(pStats, x, 470);
  
  // VISUALISATION SIMPLIFIÉE
  pushMatrix();
  translate(x, 600, 0);
  rotateX(-PI/6);
  rotateY(frameCount * 0.05);
  noStroke();
  
  // Dessin de l'aperçu
  float scaleW = (d == 1) ? 0.8 : ((d == 2) ? 1.4 : 1.0);
  fill(c); 
  // Cylindre "maison" rapide pour le menu
  float r = 40 * scaleW;
  float h = 10;
  pushMatrix(); rotateX(PI/2); cylinderUI(r, h); popMatrix();
  
  // Pointe
  float tipH = (p == 2) ? 60 : 40;
  fill(100);
  pushMatrix(); translate(0, 5 + tipH/2, 0); rotateX(PI); cylinderUI(5, tipH); popMatrix();
  
  popMatrix();
}

// Petit cylindre pour l'UI uniquement
void cylinderUI(float r, float h) {
  int sides = 20; float angle = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, -h/2); vertex(x, y, h/2);
  }
  endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, -h/2); for (int i = 0; i <= sides; i++) vertex(cos(angle * i) * r, sin(angle * i) * r, -h/2); endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, h/2); for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, h/2); endShape();
}

// -------------------------------------------------------
// LOGIQUE DU COMBAT
// -------------------------------------------------------
void drawCombat() {
  background(30);
  ambientLight(100, 100, 100);
  directionalLight(255, 255, 255, 0, 1, -1);
  
  // Caméra
  float camX = (float)(t1.x + t2.x) / 2 * 0.4;
  float camY = (float)(t1.y + t2.y) / 2 * 0.4 - 600;
  camera(camX, camY, 800, 0, 0, 0, 0, 0, -1);

  drawArena();
  
  t1.update();
  t2.update();
  
  gererCollision(t1, t2);
  
  t1.display();
  t2.display();
  
  checkHUD();
  
  t += dt;
}

void initGame() {
  // Création des toupies selon la configuration du menu
  t1 = new Toupie(-150, 0, color(100, 200, 255), p1_disque, p1_pointe);
  t2 = new Toupie(150, 0, color(255, 100, 100), p2_disque, p2_pointe);
  
  // Lancement automatique
  t1.lancer(-1);
  t2.lancer(1);
  
  ETAT_JEU = 1;
}

void keyPressed() {
  if (ETAT_JEU == 0) {
    if (key == 'a' || key == 'A') p1_disque = (p1_disque + 1) % 3;
    if (key == 'z' || key == 'Z') p1_pointe = (p1_pointe + 1) % 3;
    
    if (key == 'o' || key == 'O') p2_disque = (p2_disque + 1) % 3;
    if (key == 'p' || key == 'P') p2_pointe = (p2_pointe + 1) % 3;
    
    if (key == ' ') initGame();
  } else {
    if (key == 'r' || key == 'R') ETAT_JEU = 0; // Reset
  }
}

// -------------------------------------------------------
// CLASSE TOUPIE (Paramétrique)
// -------------------------------------------------------
class Toupie {
  double x, y, z, vx, vy;
  double theta = 0.2, phi = 0, omega_phi = 0, omega_theta = 0;
  boolean lancee = false;
  
  // PROPRIÉTÉS PHYSIQUES
  double m, L, C, A;
  float rayon_reel;
  
  // PROPRIÉTÉS DE COMPORTEMENT
  double frot_air, frot_sol, frot_pointe; // Friction pointe
  double facteur_drive;  // Agressivité mouvement
  double seuil_critique; // Stabilité
  
  color c;
  
  // Constructeur Intelligent
  Toupie(double startX, double startY, color col, int typeDisque, int typePointe) {
    x = startX; y = startY; c = col;
    
    // 1. DÉFINITION DU DISQUE (Masse & Inertie)
    double scale = 1.0;
    double density = 1.0;
    
    if (typeDisque == 0) { // STANDARD
       scale = 1.0; density = 1.0;
    } else if (typeDisque == 1) { // COMPACT LOURD (Petit rayon, grosse masse)
       scale = 0.8; density = 2.0; 
    } else if (typeDisque == 2) { // LARGE LÉGER (Grand rayon, masse normale)
       scale = 1.4; density = 0.6; 
    }
    
    rayon_reel = (float)(20 * scale);
    m = 1.0 * (scale * scale) * density; 
    
    // Inertie : C dépend de la masse et du RAYON au carré. 
    // Le disque large (type 2) aura une inertie énorme -> très stable.
    C = 10 * m * scale * scale; 
    A = C / 2.0; 

    // 2. DÉFINITION DE LA POINTE (Frottement & Hauteur)
    if (typePointe == 0) { // ÉQUILIBRE
       L = 50; 
       frot_pointe = 0.8;
       facteur_drive = 0.08; 
       seuil_critique = 25.0;
    } else if (typePointe == 1) { // ATTAQUE (Plate / Caoutchouc)
       L = 45; // Plus basse
       frot_pointe = 0.3; // Glisse MIEUX (moins de perte rotation) -> faux, en vrai ça accroche le sol pour bouger
       // Correction modèle : Une pointe d'attaque convertit la rotation en mouvement
       facteur_drive = 0.25; // BOUGE BEAUCOUP
       frot_pointe = 1.5; // Perd de la vitesse de rotation vite
       seuil_critique = 35.0; // Instable plus vite
    } else if (typePointe == 2) { // DÉFENSE (Fine / Métal)
       L = 55; // Plus haute
       frot_pointe = 0.4; // Tourne très longtemps
       facteur_drive = 0.02; // Ne bouge presque pas
       seuil_critique = 15.0; // Reste stable très longtemps
    }
    
    // Fixes
    frot_air = 0.035;
    frot_sol = 0.008;
  }
  
  boolean estCouchee() { return (theta >= PI/2 - 0.2 && omega_phi < 1.0); }
  
  void lancer(int direction) {
    lancee = true;
    x = direction * 150; y = random(-5, 5);
    
    // Si c'est une pointe d'attaque, on lance plus fort vers le centre
    double vitesse_lancement = (facteur_drive > 0.1) ? 3.5 : 2.0;
    
    vx = -direction * vitesse_lancement; 
    vy = random(-0.5, 0.5);
    
    // La vitesse de rotation dépend de l'inertie (plus dur à lancer si lourd)
    omega_phi = 600.0 / Math.sqrt(C); // Approximation énergie constante
    
    theta = 0.3; omega_theta = 0;
  }
  
  void update() {
    if (!lancee) return;
    
    // --- PHYSIQUE (Même que V6) ---
    double r = Math.sqrt(x*x + y*y);
    double angle_pos = Math.atan2(y, x);
    double angle_pente = Math.atan(2 * courbure * r);
    
    double F_rappel = -m * g * Math.sin(angle_pente);
    // Force centrifuge modérée
    double F_centri = omega_phi * 0.002 * m; 
    
    double force_tangentielle = 0;
    if (theta < PI/2 - 0.1) {
       force_tangentielle = omega_phi * Math.sin(theta) * facteur_drive * m;
    }

    double F_radial = F_rappel + F_centri;
    double ax = (F_radial * Math.cos(angle_pos)) / m;
    double ay = (F_radial * Math.sin(angle_pos)) / m;
    
    ax += (force_tangentielle * Math.cos(angle_pos + PI/2)) / m;
    ay += (force_tangentielle * Math.sin(angle_pos + PI/2)) / m;
    
    vx += ax * dt; vy += ay * dt;
    vx -= vx * frot_sol; vy -= vy * frot_sol;
    
    // Mur
    if (r > R_arene) {
       double nx = Math.cos(angle_pos); double ny = Math.sin(angle_pos);
       x = nx * (R_arene - 2); y = ny * (R_arene - 2);
       double v_dot = vx*nx + vy*ny;
       if(v_dot > 0) {
         vx -= 1.2 * v_dot * nx; vy -= 1.2 * v_dot * ny;
         omega_phi *= 0.8;
       }
    }
    
    x += vx; y += vy;
    z = courbure * x * x + courbure * y * y;
    
    // Rotation & Tangage
    double acc_theta = (m * g * L * Math.sin(theta) - A * omega_phi * omega_phi * Math.cos(theta) * Math.sin(theta)) / C;
    
    if (omega_phi < seuil_critique) {
       double ratio = (seuil_critique - omega_phi) / seuil_critique;
       acc_theta += Math.sin(t * 15.0) * (3.0 * ratio); // Oscillation
       acc_theta += 0.5 * ratio; // Poussée vers le sol
    }
    
    acc_theta -= 0.1 * omega_theta; 
    omega_theta += acc_theta * dt;
    theta += omega_theta * dt;
    
    if(theta < 0.05) theta = 0.05;
    
    // Scraping (Frottement bord)
    if (theta > 1.2) {
       omega_phi -= 8.0 * dt;
       theta += random(-0.01, 0.02);
       vx *= 0.92; vy *= 0.92;
       if (omega_phi <= 0) {
          omega_phi = 0; omega_theta = 0; vx = 0; vy = 0; theta = PI/2 - 0.14;
       }
    } else {
       omega_phi -= frot_air * omega_phi * dt;
       if (omega_phi > 0) omega_phi -= frot_pointe * dt;
    }
    
    if (omega_phi < 0) omega_phi = 0;
    if(theta > PI/2 - 0.14) { theta = PI/2 - 0.14; if (omega_theta > 0) omega_theta *= -0.3; }
    
    phi += omega_phi * dt;
  }
  
  void display() {
    if (lancee || (!lancee && frameCount % 30 < 15)) { 
      pushMatrix();
      translate((float)x, (float)y, (float)z);
      
      float lift = (float)Math.sin(theta) * rayon_reel;
      if (lift < 4.0) lift = 0; else lift -= 4.0;
      translate(0, 0, lift);
      
      rotateZ((float)phi); rotateY((float)theta); 
      
      // Tige
      pushMatrix(); translate(0,0,(float) L); rotateX(PI); fill(100); drawCone(4, (float)L, 10); popMatrix();
      // Disque
      translate(0,0,(float) L); fill(c); cylinder(rayon_reel, 4); 
      // Repère
      fill(255,255,0); translate(rayon_reel - 5, 0, 2); box(5);
      popMatrix();
    }
  }
}

// -------------------------------------------------------
// GESTION COLLISIONS & HUD
// -------------------------------------------------------
void gererCollision(Toupie a, Toupie b) {
  if (a.estCouchee() || b.estCouchee()) return; 
  double dx = a.x - b.x; double dy = a.y - b.y;
  double dist = Math.sqrt(dx*dx + dy*dy);
  double rayonContact = a.rayon_reel + b.rayon_reel; 
  
  if (dist < rayonContact) {
    double nx = dx / dist; double ny = dy / dist;
    double overlap = rayonContact - dist;
    a.x += nx * overlap / 2; a.y += ny * overlap / 2;
    b.x -= nx * overlap / 2; b.y -= ny * overlap / 2;
    
    double v1n = a.vx * nx + a.vy * ny; double v2n = b.vx * nx + b.vy * ny;
    if (v1n - v2n < 0) {
      double e = 0.8; 
      double j = (-(1 + e) * (v1n - v2n)) / (1/a.m + 1/b.m);
      a.vx += (j / a.m) * nx; a.vy += (j / a.m) * ny;
      b.vx -= (j / b.m) * nx; b.vy -= (j / b.m) * ny;
      a.omega_phi *= 0.90; b.omega_phi *= 0.90;
      a.omega_theta += random(-1, 1); b.omega_theta += random(-1, 1);
    }
  }
}

void mousePressed() {
  // Désactivé en mode menu, géré par clavier
}

void checkHUD() {
  camera(); hint(DISABLE_DEPTH_TEST);
  textAlign(LEFT); textSize(16);
  fill(100, 200, 255); text("J1 (Bleu): " + (int)t1.omega_phi + " rad/s", 20, 30);
  fill(255, 100, 100); text("J2 (Rouge): " + (int)t2.omega_phi + " rad/s", 20, 50);
  
  fill(255); textAlign(CENTER);
  if (t1.estCouchee() && !t2.estCouchee()) text("VICTOIRE ROUGE !", width/2, 100);
  else if (!t1.estCouchee() && t2.estCouchee()) text("VICTOIRE BLEU !", width/2, 100);
  else if (t1.estCouchee() && t2.estCouchee()) text("MATCH NUL (Appuyez sur R)", width/2, 100);
  hint(ENABLE_DEPTH_TEST);
}

// --- FONCTIONS GRAPHIQUES ---
void drawArena() {
  fill(60);
  for (float r = 0; r < R_arene; r += 20) {
    float h1 = (float)(courbure * r * r); float h2 = (float)(courbure * (r+20) * (r+20));
    if((r/20)%2==0) fill(55); else fill(60);
    beginShape(QUAD_STRIP);
    for(int d=0; d<=360; d+=10) {
      float a = radians(d); vertex(cos(a)*r, sin(a)*r, h1); vertex(cos(a)*(r+20), sin(a)*(r+20), h2);
    }
    endShape();
  }
}
void drawCone(float r, float h, int sides) {
  float angle = TWO_PI / sides; beginShape(TRIANGLES);
  for (int i = 0; i < sides; i++) {
    float x1 = cos(angle * i) * r; float y1 = sin(angle * i) * r;
    float x2 = cos(angle * (i + 1)) * r; float y2 = sin(angle * (i + 1)) * r;
    vertex(0, 0, h); vertex(x1, y1, 0); vertex(x2, y2, 0);
  } endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, 0); for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, 0); endShape();
}
void cylinder(float r, float h) {
  int sides = 30; float angle = TWO_PI / sides; beginShape(QUAD_STRIP);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r; float y = sin(angle * i) * r; vertex(x, y, 0); vertex(x, y, h);
  } endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, h); for (int i = 0; i <= sides; i++) vertex(cos(angle * i) * r, sin(angle * i) * r, h); endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, 0); for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, 0); endShape();
}
