/*
 * =======================================================================================
 * PROJET R512: SIMULATION D'UN DUEL DE TOUPIE
 * =======================================================================================
 * * DESCRIPTION :
 * Ce programme est une simulation physique avancée de combats de toupies
 * Il intègre un moteur physique gérant la gravité, les frottements et l'effet gyroscopique
 * et les collisions élastiques/inélastiques
 *
 * AUTEUR : Galland Loris Et Bellini Le Gall Mathys
 */

import java.util.ArrayList; // pour stocker l'historique
import java.util.Collections; // pour trier les statistiques
import java.util.Comparator;  // pour comparer les scores

// =================================================================
// VARIABLES GLOBALES ET CONSTANTES
// =================================================================

// États du jeu : 0=Menu, 1=Jeu, 2=Fin, 3=Historique, 4=Stats
int ETAT_JEU = 0; 

// Variable de contrôle pour arrêter la physique à la fin d'un round
boolean gameOver = false;

// Variables de temps pour l'intégration physique (Méthode d'Euler semi-implicite)
double dt = 0.015; 
double t = 0;

// --- PARAMÈTRES DE L'ARÈNE ---
// La courbure définit la concavité de la parabole (z = c * r²)
double courbure = 0.0022; 
double R_arene = 380;     // Rayon limite de l'arène
double g = 9.81;          // Gravité universelle

// --- CONFIGURATIONS DES JOUEURS ---
// Stockage des choix faits dans le menu
// Disques : 0=Standard, 1=Lourd, 2=Large
// Pointes : 0=Équilibre, 1=Attaque, 2=Défense
int p1_disque = 0; int p1_pointe = 0; 
int p2_disque = 0; int p2_pointe = 0;

// Instances des objets
Toupie t1;
Toupie t2;

// Base de données des matchs
ArrayList<ResultatMatch> historique = new ArrayList<ResultatMatch>();

// =================================================================
// SETUP (INITIALISATION)
// =================================================================
void setup() {
  size(1000, 800, P3D); // Fenêtre 3D
  noStroke();           // Suppression des contours pour performance et esthétique
  textSize(20);
}

// =================================================================
// BOUCLE PRINCIPALE (DRAW)
// =================================================================
void draw() {
  // Aiguillage vers la fonction de dessin correspondante à l'état actuel
  if (ETAT_JEU == 0) {
    drawMenu();
  } 
  else if (ETAT_JEU == 1) {
    drawCombat();
  }
  else if (ETAT_JEU == 2) {
    drawEcranFin();
  }
  else if (ETAT_JEU == 3) {
    drawHistorique();
  }
  else if (ETAT_JEU == 4) {
    drawStatsAvancees(); // Nouvelle fonction de stats par toupie
  }
}

// =================================================================
// INTERFACE UTILISATEUR
// =================================================================

// ---MENU PRINCIPAL ---
void drawMenu() {
  background(25);
  camera(); hint(DISABLE_DEPTH_TEST); // Interface 2D
  textAlign(CENTER);
  
  // Titre et Sous-titre
  fill(255); textSize(40); text("SIMULATION D'UN DUEL DE TOUPIE", width/2, 60);
  fill(100, 255, 100); textSize(20); text("Appuyez sur [ESPACE] pour LANCER LE DUEL", width/2, 100);
  
  // Boutons Stats
  fill(200); textSize(16);
  text("[H] Historique des matchs   -   [S] Analyse des Performances (Stats)", width/2, 130);
  
  stroke(100); line(width/2, 160, width/2, height-50); noStroke();
  
  // Colonnes Joueurs
  drawPlayerConfig(width/4, "JOUEUR 1 (Bleu)", p1_disque, p1_pointe, color(50, 150, 255));
  fill(200); textSize(16); text("COMMANDES J1 : 'A' (Disque) / 'Z' (Pointe)", width/4, 550);

  drawPlayerConfig(3*width/4, "JOUEUR 2 (Rouge)", p2_disque, p2_pointe, color(255, 80, 80));
  fill(200); textSize(16); text("COMMANDES J2 : 'O' (Disque) / 'P' (Pointe)", 3*width/4, 550);
  
  hint(ENABLE_DEPTH_TEST);
}

// Fonction d'affichage d'une configuration joueur
void drawPlayerConfig(float x, String name, int d, int p, color c) {
  fill(c); textSize(30); text(name, x, 200);
  
  fill(255); textSize(18); text("DISQUE", x, 260);
  String dName = (d==0) ? "STANDARD" : (d==1 ? "LOURD" : "LARGE");
  fill(255, 255, 0); textSize(24); text("< " + dName + " >", x, 290);
  
  fill(255); textSize(18); text("POINTE", x, 360);
  String pName = (p==0) ? "EQUILIBRE" : (p==1 ? "ATTAQUE" : "DEFENSE");
  fill(255, 255, 0); textSize(24); text("< " + pName + " >", x, 390);
  
   // Prévisualisation 3D
  pushMatrix(); translate(x, 650, 0); rotateX(-PI/6); rotateY(frameCount*0.03);
  fill(c); 
  float r = (d==1) ? 30 : ((d==2) ? 55 : 40);
  pushMatrix(); rotateX(PI/2); cylinder(r, 10); popMatrix();
  fill(100);
  float tipH = (p==2) ? 60 : 40;
  pushMatrix(); translate(0, 5+tipH/2, 0); rotateX(PI); cylinder(5, tipH); popMatrix();
  popMatrix();
}

// ---ÉCRAN DE FIN---
void drawEcranFin() {
  drawCombat(); //On garde le jeu en fond
  camera(); hint(DISABLE_DEPTH_TEST);
  fill(0, 0, 0, 180); rect(0, 0, width, height); // Voile noir
  textAlign(CENTER);
  fill(255, 255, 0); textSize(50); text("FIN DU COMBAT !", width/2, height/2 - 60);
  textSize(30);
  if (t1.estKO() && !t2.estKO()) { fill(255, 100, 100); text("VICTOIRE JOUEUR 2 (ROUGE) !", width/2, height/2); }
  else if (!t1.estKO() && t2.estKO()) { fill(100, 200, 255); text("VICTOIRE JOUEUR 1 (BLEU) !", width/2, height/2); }
  else { fill(200); text("ÉGALITÉ !", width/2, height/2); }
  fill(255); textSize(20);
  text("[ENTRÉE] Retour Menu   -   [R] Rejouer", width/2, height/2 + 60);
  hint(ENABLE_DEPTH_TEST);
}

// --- ÉCRAN HISTORIQUE ---
void drawHistorique() {
  background(30);
  camera(); hint(DISABLE_DEPTH_TEST);
  textAlign(CENTER); fill(255); textSize(35); text("HISTORIQUE DES MATCHS", width/2, 50);
  textSize(16); text("[M] Menu Principal", width/2, 80);
  textAlign(LEFT); fill(150);
  float y = 140;
  text("N°", 50, y); text("Vainqueur", 100, y); 
  text("Config J1", 300, y); text("Config J2", 550, y); 
  text("Vit. J1", 800, y); text("Vit. J2", 900, y);
  stroke(100); line(40, y+10, width-40, y+10); noStroke();
  y += 40;
  int start = max(0, historique.size() - 12);
  for (int i = historique.size() - 1; i >= start; i--) {
    ResultatMatch r = historique.get(i);
    if (r.winnerID == 1) fill(100, 200, 255);
    else if (r.winnerID == 2) fill(255, 100, 100);
    else fill(200);
    
    text("#" + (i+1), 50, y);
    String w = (r.winnerID==1)?"J1":(r.winnerID==2?"J2":"EGAL");
    text(w, 100, y);
    fill(255);
    text(getConfigString(r.d1, r.p1), 300, y);
    text(getConfigString(r.d2, r.p2), 550, y);
    text((int)r.vFinalJ1, 800, y); text((int)r.vFinalJ2, 900, y);
    y += 35;
  }
  hint(ENABLE_DEPTH_TEST);
}

// --- STATISTIQUES AVANCÉES ---
// Analyse quelle CONFIGURATION gagne le plus, pas quel joueur.
void drawStatsAvancees() {
  background(30);
  camera(); hint(DISABLE_DEPTH_TEST);
  textAlign(CENTER); fill(255); textSize(35); 
  text("ANALYSE DE PERFORMANCE PAR CONFIGURATION", width/2, 50);
  textSize(16); text("[M] Retour Menu", width/2, 80);
  if (historique.size() == 0) {
    fill(150); text("Aucune donnée. Jouez des parties pour générer des stats.", width/2, height/2);
    hint(ENABLE_DEPTH_TEST); return;
  }
  
  // 1Agrégation des données
  // On utilise un tableau de 9 entrées (3 disques*3 pointes)
  // Index = disque*3 + pointe
  int[] partiesJouees = new int[9];
  int[] victoires = new int[9];
  
  for (ResultatMatch r : historique) {
    // Index config J1
    int idx1 = r.d1 * 3 + r.p1;
    partiesJouees[idx1]++;
    if (r.winnerID == 1) victoires[idx1]++;
    
    // Index config J2
    int idx2 = r.d2 * 3 + r.p2;
    partiesJouees[idx2]++;
    if (r.winnerID == 2) victoires[idx2]++;
  }
  
  // Recherche du TOP 3 et du flop 3
  // créer une liste triable
  ArrayList<StatEntry> stats = new ArrayList<StatEntry>();
  for(int d=0; d<3; d++) {
    for(int p=0; p<3; p++) {
      int idx = d*3 + p;
      if(partiesJouees[idx] > 0) {
        stats.add(new StatEntry(d, p, victoires[idx], partiesJouees[idx]));
      }
    }
  }
  
  // Tri par pourcentage de victoire (Décroissant)
  Collections.sort(stats, new Comparator<StatEntry>(){
    public int compare(StatEntry a, StatEntry b){
      return Float.compare(b.pourcentage, a.pourcentage);
    }
  });
  
  // Affichage
  textAlign(LEFT);
  float startY = 150;
  // Colonne MEILLEURES CONFIGS
  fill(100, 255, 100); textSize(24); text("TOP CONFIGURATIONS (Gagnantes)", 100, startY);
  textSize(18);
  for(int i=0; i<min(5, stats.size()); i++) {
    StatEntry s = stats.get(i);
    fill(255);
    String nom = getConfigString(s.disque, s.pointe);
    // Barre de progression
    float wBar = 200;
    fill(50); rect(100, startY + 40 + i*60, wBar, 20);
    fill(100, 255, 100); rect(100, startY + 40 + i*60, wBar * (s.pourcentage/100.0), 20);
    
    fill(255);
    text("#" + (i+1) + " " + nom, 100, startY + 30 + i*60);
    text((int)s.pourcentage + "% Victoires (" + s.victoires + "/" + s.jouees + ")", 320, startY + 55 + i*60);
  }
  
  // Colonne PIRES CONFIGS (Si assez de données)
  if(stats.size() > 1) {
    fill(255, 100, 100); textSize(24); text("MOINS EFFICACES", 600, startY);
    textSize(18);
    int count = 0;
    for(int i=stats.size()-1; i>=max(0, stats.size()-5); i--) {
      StatEntry s = stats.get(i);
      fill(255);
      String nom = getConfigString(s.disque, s.pointe);
      
      float wBar = 200;
      fill(50); rect(600, startY + 40 + count*60, wBar, 20);
      fill(255, 100, 100); rect(600, startY + 40 + count*60, wBar * (s.pourcentage/100.0), 20);
      
      fill(255);
      text(nom, 600, startY + 30 + count*60);
      text((int)s.pourcentage + "% Victoires", 820, startY + 55 + count*60);
      count++;
    }
  }
  
  hint(ENABLE_DEPTH_TEST);
}

// Classe interne pour aider au tri des stats
class StatEntry {
  int disque, pointe;
  int victoires, jouees;
  float pourcentage;
  StatEntry(int d, int p, int v, int j) {
    disque = d; pointe = p; victoires = v; jouees = j;
    pourcentage = (j == 0) ? 0 : ((float)v / j) * 100;
  }
}
// Helpers texte
String getConfigString(int d, int p) {
  String sD = (d==0)?"Std":(d==1?"Lourd":"Large");
  String sP = (p==0)?"Eq":(p==1?"Atk":"Def");
  return sD + " + " + sP;
}

class ResultatMatch {
  int winnerID; 
  int d1, p1, d2, p2; 
  float vFinalJ1, vFinalJ2;
  ResultatMatch(int w, int dis1, int poi1, int dis2, int poi2, float vf1, float vf2) {
    winnerID = w; d1=dis1; p1=poi1; d2=dis2; p2=poi2; vFinalJ1=vf1; vFinalJ2=vf2;
  }
}

// =================================================================
// MOTEUR DE JEU (PHYSIQUE)
// =================================================================
void drawCombat() {
  background(30);
  ambientLight(120, 120, 120);
  directionalLight(255, 255, 255, 0, 1, -1);
  
  float cx = (float)(t1.x + t2.x) / 2 * 0.5;
  float cy = (float)(t1.y + t2.y) / 2 * 0.5 - 550;
  camera(cx, cy, 700, 0, 0, 0, 0, 0, -1);

  drawArena();
  
  if (!gameOver) {
    t1.update(); t2.update();
    gererCollision(t1, t2);
    // Condition de fin : Une toupie est KO
    if (t1.estKO() || t2.estKO()) {
      gameOver = true;
      ETAT_JEU = 2; 
      
      int win = 0;
      if (!t1.estKO() && t2.estKO()) win = 1;
      else if (t1.estKO() && !t2.estKO()) win = 2;
      historique.add(new ResultatMatch(win, p1_disque, p1_pointe, p2_disque, p2_pointe, (float)t1.omega_phi, (float)t2.omega_phi));
    }
    t += dt;
  }
  
  t1.display(); t2.display();
  camera(); hint(DISABLE_DEPTH_TEST);
  textAlign(LEFT); textSize(16);
  fill(100, 200, 255); text("J1 SPIN: " + (int)t1.omega_phi, 20, 30);
  fill(255, 100, 100); text("J2 SPIN: " + (int)t2.omega_phi, 20, 50);
  hint(ENABLE_DEPTH_TEST);
}

// -------------------------------------------------------
// CLASSE TOUPIE
// -------------------------------------------------------
class Toupie {
  double x, y, z, vx, vy;
  double theta = 0.2, phi = 0, omega_phi = 0, omega_theta = 0;
  boolean lancee = false;
  double m, L, C, A;
  float rayon_visuel;
  double rayon_physique;
  double facteur_drive; 
  double seuil_chute = 10.0; // SEUIL CRITIQUE DE CHUTE (Demandé)
  double frot_air;
  color col;
  Toupie(double sx, double sy, color c, int dType, int pType) {
    x = sx; y = sy; col = c;
    
    // Config Disque
    double scale = 1.0; double densite = 1.0;
    if(dType == 1) { scale = 0.8; densite = 2.5; } 
    if(dType == 2) { scale = 1.3; densite = 0.7; } 
    rayon_visuel = (float)(20 * scale);
    rayon_physique = rayon_visuel + 2.0; 
    
    m = 1.0 * scale * scale * densite;
    C = 8.0 * m * scale * scale; 
    A = C / 2.0;                 
    
    // Config Pointe
    frot_air = 0.08; 
    if(pType == 0) { L = 50; facteur_drive = 0.08; } 
    else if(pType == 1) { L = 45; facteur_drive = 0.25; frot_air = 0.12; } 
    else { L = 55; facteur_drive = 0.01; frot_air = 0.06; }
  }
  
  void lancer(int dir) {
    lancee = true;
    x = dir * 250; y = random(-20, 20);
    vx = -dir * 3.5; vy = random(-1, 1);
    omega_phi = 150.0 / Math.sqrt(m); 
    theta = 0.3; omega_theta = 0;
  }
  
  boolean estKO() { return (theta > 1.4); }
  boolean estFaible() { return (omega_phi < 12.0 || theta > 0.8); }
  void update() {
    if (!lancee) return;
    // --- DÉPLACEMENT ---
    double r = Math.sqrt(x*x + y*y);
    double angPos = Math.atan2(y, x);
    double angPente = Math.atan(2 * courbure * r);
    double F_grav = -m * g * Math.sin(angPente) * 3.0; 
    double F_drive = 0;
    if(theta < 1.4) F_drive = omega_phi * Math.sin(theta) * facteur_drive * m;
    double ax = (F_grav * Math.cos(angPos) + F_drive * Math.cos(angPos + PI/2)) / m;
    double ay = (F_grav * Math.sin(angPos) + F_drive * Math.sin(angPos + PI/2)) / m;
    
    vx += ax * dt; vy += ay * dt;
    vx *= 0.985; vy *= 0.985; 
    
    if(r > R_arene) {
      double nx = Math.cos(angPos); double ny = Math.sin(angPos);
      x = nx*(R_arene-2); y = ny*(R_arene-2);
      double vdot = vx*nx + vy*ny;
      if(vdot > 0) {
        vx -= 0.8 * vdot * nx; vy -= 0.8 * vdot * ny; 
        omega_phi *= 0.8; 
      }
    }
    
    x += vx; y += vy;
    z = courbure * r * r;
    
    // --- ROTATION & CHUTE ---
    double couple_grav = m * g * L * Math.sin(theta);
    double couple_gyro = A * omega_phi * omega_phi * Math.cos(theta) * Math.sin(theta);
    double acc_theta = (couple_grav - couple_gyro) / C;
    
    // TANGAGE (Pré-chute)
    if(omega_phi < 30.0 && omega_phi >= 10.0) {
       double ratio = (30.0 - omega_phi) / 20.0;
       acc_theta += Math.sin(t * 20.0) * (15.0 * ratio); 
       acc_theta += 2.0 * ratio; 
    }
    
    // CHUTE FATALE (Vitesse < 10)
    if (omega_phi < 10.0) {
       double ratioMort = (10.0 - omega_phi) / 10.0; 
       acc_theta += 15.0 + (20.0 * ratioMort); 
       omega_phi *= 0.98; // Tuer la rotation pour accélérer la fin
    }
    
    acc_theta -= 0.2 * omega_theta; 
    omega_theta += acc_theta * dt;
    theta += omega_theta * dt;
    if(theta < 0.05) theta = 0.05; 
    
    // --- DISSIPATION ---
    omega_phi -= frot_air * omega_phi * dt;
    if(omega_phi > 0) omega_phi -= 3.0 * dt; 
    
    if(theta > 1.3) { 
       omega_phi -= 40.0 * dt; 
       vx *= 0.9; vy *= 0.9; 
       theta += random(-0.02, 0.02); 
    }
    
    if(omega_phi < 0) omega_phi = 0; 
    if(theta > 1.5) { theta = 1.5; if(omega_theta>0) omega_theta *= -0.5; }
    phi += omega_phi * dt;
  }
  
  void display() {
    if(!lancee) return;
    pushMatrix();
    translate((float)x, (float)y, (float)z);
    
    float lift = (float)Math.sin(theta) * rayon_visuel;
    if(lift < 4.0) lift = 0; else lift -= 4.0;
    translate(0, 0, lift);
    
    rotateZ((float)phi); rotateY((float)theta);
    
    pushMatrix(); translate(0,0,(float)L); 
    pushMatrix(); rotateX(PI); fill(80); drawCone(4, (float)L, 10); popMatrix(); 
    fill(col); cylinder(rayon_visuel, 5); 
    fill(255,255,0); translate(rayon_visuel-6, 0, 4); box(6); 
    popMatrix(); popMatrix();
  }
}

// -------------------------------------------------------
// COLLISIONS
// -------------------------------------------------------
void gererCollision(Toupie a, Toupie b) {
  if (a.estKO() || b.estKO()) return;
  
  double dx = a.x - b.x; double dy = a.y - b.y;
  double dist = Math.sqrt(dx*dx + dy*dy);
  double rContact = a.rayon_physique + b.rayon_physique;
  
  if (dist < rContact) {
    double nx = dx/dist; double ny = dy/dist;
    double overlap = rContact - dist;
    
    a.x += nx * overlap * 0.5; a.y += ny * overlap * 0.5;
    b.x -= nx * overlap * 0.5; b.y -= ny * overlap * 0.5;
    
    double v1n = a.vx*nx + a.vy*ny; double v2n = b.vx*nx + b.vy*ny;
    
    if(v1n - v2n < 0) {
       double restitution = 0.85; 
       
       // Si une toupie est faible le choc est léger
       if (a.estFaible() || b.estFaible()) {
           restitution = 0.1; 
           a.omega_theta += 5.0; b.omega_theta += 5.0;
           a.omega_phi -= 10.0; b.omega_phi -= 10.0;
       }
       
       double j = (-(1 + restitution) * (v1n - v2n)) / (1/a.m + 1/b.m);
       
       if (restitution > 0.5) {
          double minForce = 2.0;
          if (Math.abs(j) < minForce) j = (j > 0) ? minForce : -minForce;
       }
       
       a.vx += (j/a.m)*nx; a.vy += (j/a.m)*ny;
       b.vx -= (j/b.m)*nx; b.vy -= (j/b.m)*ny;
       
       double force = Math.abs(j);
       a.omega_phi -= force * 0.6; b.omega_phi -= force * 0.6;
       a.omega_theta += 2.0; b.omega_theta += 2.0;
    }
  }
}

// -------------------------------------------------------
// INPUTS CLAVIER
// -------------------------------------------------------
void keyPressed() {
  if (ETAT_JEU == 0) {
    if (key == 'a' || key == 'A') p1_disque = (p1_disque + 1) % 3;
    if (key == 'z' || key == 'Z') p1_pointe = (p1_pointe + 1) % 3;
    if (key == 'o' || key == 'O') p2_disque = (p2_disque + 1) % 3;
    if (key == 'p' || key == 'P') p2_pointe = (p2_pointe + 1) % 3;
    if (key == ' ') initGame();
    if (key == 'h' || key == 'H') ETAT_JEU = 3;
    if (key == 's' || key == 'S') ETAT_JEU = 4;
  } 
  else if (ETAT_JEU == 2) {
    if (key == 'r' || key == 'R') initGame();
    if (key == ENTER || key == RETURN) ETAT_JEU = 0;
  }
  else if (ETAT_JEU == 3 || ETAT_JEU == 4) {
    if (key == 'm' || key == 'M') ETAT_JEU = 0;
  }
}

void initGame() {
  t1 = new Toupie(-250, 0, color(50, 150, 255), p1_disque, p1_pointe);
  t2 = new Toupie(250, 0, color(255, 80, 80), p2_disque, p2_pointe);
  t1.lancer(-1); t2.lancer(1);
  ETAT_JEU = 1;
  gameOver = false;
}

// -------------------------------------------------------
// DESSIN 3D
// -------------------------------------------------------
void drawArena() {
  fill(50);
  for (float r = 0; r < R_arene; r += 20) {
    float h1 = (float)(courbure * r * r);
    float h2 = (float)(courbure * (r+20) * (r+20));
    if((r/20)%2==0) fill(55); else fill(50);
    beginShape(QUAD_STRIP);
    for(int d=0; d<=360; d+=15) {
      float a = radians(d); vertex(cos(a)*r, sin(a)*r, h1); vertex(cos(a)*(r+20), sin(a)*(r+20), h2);
    }
    endShape();
  }
}
void cylinder(float r, float h) {
  int s = 20; float a = TWO_PI/s;
  beginShape(QUAD_STRIP); for(int i=0;i<=s;i++) { vertex(cos(a*i)*r,sin(a*i)*r,0); vertex(cos(a*i)*r,sin(a*i)*r,h); } endShape();
  beginShape(TRIANGLE_FAN); vertex(0,0,h); for(int i=0;i<=s;i++) vertex(cos(a*i)*r,sin(a*i)*r,h); endShape();
  beginShape(TRIANGLE_FAN); vertex(0,0,0); for(int i=s;i>=0;i--) vertex(cos(a*i)*r,sin(a*i)*r,0); endShape();
}
void drawCone(float r, float h, int s) {
  float a = TWO_PI/s; beginShape(TRIANGLES);
  for(int i=0; i<s; i++) { vertex(0,0,h); vertex(cos(a*i)*r, sin(a*i)*r, 0); vertex(cos(a*(i+1))*r, sin(a*(i+1))*r, 0); } endShape();
  beginShape(TRIANGLE_FAN); vertex(0,0,0); for(int i=s;i>=0;i--) vertex(cos(a*i)*r,sin(a*i)*r,0); endShape();
}
